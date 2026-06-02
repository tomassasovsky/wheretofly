import 'package:flutter/material.dart';
import 'package:geocoding_repository/geocoding_repository.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';

/// Floating overlay card listing geocoding suggestions below the search bar.
class SearchResultsOverlay extends StatelessWidget {
  const SearchResultsOverlay({
    required this.searching,
    required this.results,
    required this.error,
    required this.onResultSelected,
    super.key,
  });

  final bool searching;
  final List<GeocodeResult> results;
  final GeocodingFailure? error;
  final ValueChanged<GeocodeResult> onResultSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280),
        child: searching
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : error != null
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      error == GeocodingFailure.noResults
                          ? l10n.searchNoResults
                          : l10n.searchNetworkError,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: results.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    itemBuilder: (context, index) {
                      final result = results[index];
                      return _SearchResultTile(
                        result: result,
                        onTap: () => onResultSelected(result),
                      );
                    },
                  ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.result, required this.onTap});

  final GeocodeResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        Icons.place_outlined,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        result.label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      dense: true,
      onTap: onTap,
    );
  }
}
