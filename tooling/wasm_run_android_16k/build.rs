fn main() {
    println!("cargo:rerun-if-changed=src/api.rs");
    if std::env::var("TARGET")
        .unwrap_or_default()
        .contains("android")
    {
        return;
    }
}
