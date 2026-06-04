#!/usr/bin/env bash
# Generates an Android release keystore and android/key.properties for Gradle.
#
# Configuration (first match wins):
#   1. CLI flags
#   2. Environment variables
#   3. android/signing.env (copy from android/signing.env.example)
#   4. Built-in defaults
#
# Examples:
#   ./scripts/setup_android_signing.sh
#   ./scripts/setup_android_signing.sh --config android/signing.env
#   ANDROID_KEY_ALIAS=upload ANDROID_KEYSTORE_PASSWORD=secret ./scripts/setup_android_signing.sh
#   ./scripts/setup_android_signing.sh --keystore android/app/upload-keystore.jks --alias upload
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ANDROID_DIR="${ROOT}/android"
APP_DIR="${ANDROID_DIR}/app"
CONFIG_FILE="${ANDROID_DIR}/signing.env"
FORCE=0
PROPERTIES_ONLY=0
NON_INTERACTIVE=0

# Defaults (lowest priority).
KEYSTORE_PATH="android/app/upload-keystore.jks"
KEY_ALIAS="upload"
STORE_PASSWORD=""
KEY_PASSWORD=""
VALIDITY_DAYS="10000"
KEY_ALG="RSA"
KEY_SIZE="2048"
DNAME="CN=Where To Fly, OU=Mobile, O=Where To Fly, L=Buenos Aires, ST=CABA, C=AR"

ARGS=("$@")
idx=0
while [[ ${idx} -lt ${#ARGS[@]} ]]; do
  if [[ "${ARGS[${idx}]}" == "--config" ]]; then
    CONFIG_FILE="${ARGS[$((idx + 1))]}"
    idx=$((idx + 2))
  else
    idx=$((idx + 1))
  fi
done

load_config_file() {
  local file="$1"
  if [[ ! -f "${file}" ]]; then
    return 0
  fi
  # shellcheck disable=SC1090
  set -a
  source "${file}"
  set +a
  KEYSTORE_PATH="${ANDROID_KEYSTORE_PATH:-${KEYSTORE_PATH}}"
  KEY_ALIAS="${ANDROID_KEY_ALIAS:-${KEY_ALIAS}}"
  STORE_PASSWORD="${ANDROID_KEYSTORE_PASSWORD:-${STORE_PASSWORD}}"
  KEY_PASSWORD="${ANDROID_KEY_PASSWORD:-${KEY_PASSWORD}}"
  VALIDITY_DAYS="${ANDROID_KEY_VALIDITY_DAYS:-${VALIDITY_DAYS}}"
  KEY_ALG="${ANDROID_KEY_ALG:-${KEY_ALG}}"
  KEY_SIZE="${ANDROID_KEY_SIZE:-${KEY_SIZE}}"
  DNAME="${ANDROID_DNAME:-${DNAME}}"
}

load_config_file "${CONFIG_FILE}"

# Environment variables override the config file.
KEYSTORE_PATH="${ANDROID_KEYSTORE_PATH:-${KEYSTORE_PATH}}"
KEY_ALIAS="${ANDROID_KEY_ALIAS:-${KEY_ALIAS}}"
STORE_PASSWORD="${ANDROID_KEYSTORE_PASSWORD:-${STORE_PASSWORD}}"
KEY_PASSWORD="${ANDROID_KEY_PASSWORD:-${KEY_PASSWORD}}"
VALIDITY_DAYS="${ANDROID_KEY_VALIDITY_DAYS:-${VALIDITY_DAYS}}"
KEY_ALG="${ANDROID_KEY_ALG:-${KEY_ALG}}"
KEY_SIZE="${ANDROID_KEY_SIZE:-${KEY_SIZE}}"
DNAME="${ANDROID_DNAME:-${DNAME}}"

usage() {
  cat <<'EOF'
Usage: setup_android_signing.sh [options]

Options:
  --config PATH          Config file (default: android/signing.env)
  --keystore PATH        Keystore path (repo-relative or absolute)
  --alias NAME           Key alias (default: upload)
  --store-password PASS  Keystore password
  --key-password PASS    Key password (defaults to store password)
  --validity-days N      Certificate validity in days (default: 10000)
  --dname STRING         keytool -dname value
  --force                Replace an existing keystore
  --properties-only      Write key.properties only; do not create a keystore
  --non-interactive      Fail if passwords are missing (for CI)
  -h, --help             Show this help

Environment variables:
  ANDROID_KEYSTORE_PATH, ANDROID_KEY_ALIAS, ANDROID_KEYSTORE_PASSWORD,
  ANDROID_KEY_PASSWORD, ANDROID_KEY_VALIDITY_DAYS, ANDROID_KEY_ALG,
  ANDROID_KEY_SIZE, ANDROID_DNAME
EOF
}

set -- "${ARGS[@]}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)
      CONFIG_FILE="$2"
      shift 2
      ;;
    --keystore)
      KEYSTORE_PATH="$2"
      shift 2
      ;;
    --alias)
      KEY_ALIAS="$2"
      shift 2
      ;;
    --store-password)
      STORE_PASSWORD="$2"
      shift 2
      ;;
    --key-password)
      KEY_PASSWORD="$2"
      shift 2
      ;;
    --validity-days)
      VALIDITY_DAYS="$2"
      shift 2
      ;;
    --dname)
      DNAME="$2"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    --properties-only)
      PROPERTIES_ONLY=1
      shift
      ;;
    --non-interactive)
      NON_INTERACTIVE=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "${KEYSTORE_PATH}" != /* ]]; then
  KEYSTORE_ABS="${ROOT}/${KEYSTORE_PATH}"
else
  KEYSTORE_ABS="${KEYSTORE_PATH}"
fi

KEY_PROPERTIES="${ANDROID_DIR}/key.properties"
KEYSTORE_DIR="$(dirname "${KEYSTORE_ABS}")"

if [[ -z "${KEY_PASSWORD}" ]]; then
  KEY_PASSWORD="${STORE_PASSWORD}"
fi

prompt_password() {
  local label="$1"
  local var_name="$2"
  local value=""
  read -r -s -p "${label}: " value
  echo
  printf -v "${var_name}" '%s' "${value}"
}

if [[ -z "${STORE_PASSWORD}" ]]; then
  if [[ "${NON_INTERACTIVE}" -eq 1 ]]; then
    echo "Missing keystore password. Set ANDROID_KEYSTORE_PASSWORD or use --store-password." >&2
    exit 1
  fi
  prompt_password "Keystore password" STORE_PASSWORD
  KEY_PASSWORD="${STORE_PASSWORD}"
fi

if [[ -z "${KEY_PASSWORD}" ]]; then
  if [[ "${NON_INTERACTIVE}" -eq 1 ]]; then
    echo "Missing key password. Set ANDROID_KEY_PASSWORD or use --key-password." >&2
    exit 1
  fi
  prompt_password "Key password (Enter to match keystore password)" KEY_PASSWORD
  if [[ -z "${KEY_PASSWORD}" ]]; then
    KEY_PASSWORD="${STORE_PASSWORD}"
  fi
fi

if ! command -v keytool >/dev/null 2>&1; then
  echo "keytool not found. Install a JDK and ensure keytool is on PATH." >&2
  exit 1
fi

mkdir -p "${KEYSTORE_DIR}"

if [[ "${PROPERTIES_ONLY}" -eq 0 ]]; then
  if [[ -f "${KEYSTORE_ABS}" && "${FORCE}" -eq 0 ]]; then
    echo "Keystore already exists: ${KEYSTORE_ABS}"
    echo "Use --force to replace it, or --properties-only to refresh key.properties."
  else
    if [[ -f "${KEYSTORE_ABS}" && "${FORCE}" -eq 1 ]]; then
      rm -f "${KEYSTORE_ABS}"
    fi
    echo "Creating keystore: ${KEYSTORE_ABS}"
    keytool -genkeypair -v \
      -keystore "${KEYSTORE_ABS}" \
      -alias "${KEY_ALIAS}" \
      -keyalg "${KEY_ALG}" \
      -keysize "${KEY_SIZE}" \
      -validity "${VALIDITY_DAYS}" \
      -storepass "${STORE_PASSWORD}" \
      -keypass "${KEY_PASSWORD}" \
      -dname "${DNAME}"
  fi
elif [[ ! -f "${KEYSTORE_ABS}" ]]; then
  echo "Keystore not found: ${KEYSTORE_ABS}" >&2
  echo "Remove --properties-only or create the keystore first." >&2
  exit 1
fi

# Gradle resolves storeFile from android/app/ unless an absolute path is given.
case "${KEYSTORE_ABS}" in
  "${APP_DIR}/"*)
    STORE_FILE_VALUE="${KEYSTORE_ABS#"${APP_DIR}/"}"
    ;;
  *)
    STORE_FILE_VALUE="${KEYSTORE_ABS}"
    ;;
esac

cat > "${KEY_PROPERTIES}" <<EOF
storePassword=${STORE_PASSWORD}
keyPassword=${KEY_PASSWORD}
keyAlias=${KEY_ALIAS}
storeFile=${STORE_FILE_VALUE}
EOF

chmod 600 "${KEY_PROPERTIES}" 2>/dev/null || true

echo
echo "Wrote ${KEY_PROPERTIES}"
echo "Keystore: ${KEYSTORE_ABS}"
echo
echo "Release build:"
echo "  flutter build appbundle"
echo "  flutter build apk --release"
echo
echo "Certificate fingerprints (for Play Console / Google Maps restrictions):"

keytool -list -v \
  -keystore "${KEYSTORE_ABS}" \
  -alias "${KEY_ALIAS}" \
  -storepass "${STORE_PASSWORD}" 2>/dev/null | awk '
    /SHA1:/ { print "  SHA-1:  " $2 }
    /SHA256:/ { print "  SHA-256:" $2 }
  '

echo
echo "Keep the keystore and passwords backed up — losing them blocks Play Store updates."
