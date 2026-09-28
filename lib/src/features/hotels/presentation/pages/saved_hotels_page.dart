import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/app_scope.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/content_column.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../shell/application/shell_controller.dart';
import '../../../shell/presentation/home_shell.dart';
import '../widgets/hotel_results.dart';
import 'hotel_details_page.dart';

/// The traveller's shortlist.
class SavedHotelsPage extends StatelessWidget {
  const SavedHotelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[deps.search, deps.saved]),
      builder: (context, _) {
        final saved = deps.saved.savedFrom(deps.search.hotels);

        return LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth =
                math.min(constraints.maxWidth, 1200.0) - AppSpacing.lg * 2;
            final columns = columnsForWidth(contentWidth);

            return CustomScrollView(
              slivers: <Widget>[
                SliverAppBar(
                  floating: true,
                  snap: true,
                  automaticallyImplyLeading: false,
                  title: Text(
                    saved.isEmpty
                        ? 'Saved stays'
                        : 'Saved stays (${saved.length})',
                  ),
                ),
                if (saved.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.favorite_border,
                      title: 'Nothing saved yet',
                      message:
                          'Tap the heart on any stay to keep it here for later.',
                      actionLabel: 'Explore stays',
                      onAction: () => context.showShellTab(ShellTab.explore),
                    ),
                  )
                else
                  SliverContentColumn(
                    maxWidth: 1200,
                    sliver: SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      sliver: HotelResultsSliver(
                        hotels: saved,
                        stay: deps.search.stay,
                        columns: columns,
                        heroTagPrefix: 'saved-cover',
                        isSaved: (hotel) => deps.saved.isSaved(hotel.id),
                        onSaveToggle: deps.saved.toggle,
                        onHotelTap: (hotel, heroTag) =>
                            Navigator.of(context).push(
                              HotelDetailsPage.route(
                                hotel: hotel,
                                heroTag: heroTag,
                              ),
                            ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
