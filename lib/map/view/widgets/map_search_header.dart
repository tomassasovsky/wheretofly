import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:where_to_fly/map/cubit/map_search_cubit.dart';
import 'package:where_to_fly/map/view/widgets/map_legend.dart';
import 'package:where_to_fly/map/view/widgets/map_search_bar.dart';
import 'package:where_to_fly/map/view/widgets/search_results_overlay.dart';

/// Search bar, results overlay, and optional legend column.
class MapSearchHeader extends StatelessWidget {
  const MapSearchHeader({
    required this.searchController,
    required this.focusNode,
    required this.showLegend,
    required this.onQueryChanged,
    required this.onSubmitSearch,
    super.key,
  });

  final TextEditingController searchController;
  final FocusNode focusNode;
  final bool showLegend;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onSubmitSearch;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapSearchCubit, MapSearchState>(
      builder: (context, searchState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MapSearchBar(
              controller: searchController,
              focusNode: focusNode,
              onChanged: onQueryChanged,
              onSubmitted: onSubmitSearch,
            ),
            if (searchState.showResults) ...[
              const SizedBox(height: 8),
              SearchResultsOverlay(
                searching: searchState.searching,
                results: searchState.results,
                error: searchState.searchError,
                onResultSelected: (result) =>
                    context.read<MapSearchCubit>().selectResult(result),
              ),
            ],
            if (showLegend) ...[
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerRight,
                child: MapLegend(),
              ),
            ],
          ],
        );
      },
    );
  }
}
