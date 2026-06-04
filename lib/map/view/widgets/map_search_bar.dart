import 'package:flutter/material.dart';
import 'package:where_to_fly/app/router/app_routes.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';

/// A floating, pill-shaped search bar: search icon, text field, settings.
class MapSearchBar extends StatelessWidget {
  const MapSearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fieldStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 15,
      height: 1.25,
    );

    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(28),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.only(left: 14, right: 2),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              Icon(
                Icons.search,
                size: 22,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.search,
                  onChanged: onChanged,
                  onSubmitted: (_) => onSubmitted(),
                  style: fieldStyle,
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    hintStyle: fieldStyle?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    isCollapsed: true,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.settings,
                iconSize: 22,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => const SettingsRoute().push<void>(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
