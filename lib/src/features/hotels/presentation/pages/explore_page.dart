import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/app_scope.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatting/date_formatter.dart';
import '../../../../core/load_status.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../shared/widgets/brand_mark.dart';
import '../../../../shared/widgets/content_column.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/entrance_animation.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../application/hotel_search_controller.dart';
import '../../domain/hotel.dart';
import '../widgets/hotel_filters_bar.dart';
import '../widgets/hotel_results.dart';
import '../widgets/stay_search_panel.dart';
import 'hotel_details_page.dart';

/// Search, refine and browse stays.
///
/// Phones and tablets get a single scrolling column; desktop and wide web
/// windows get a fixed search sidebar next to a scrolling results grid.
class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[deps.search, deps.saved]),
      builder: (context, _) => ResponsiveBuilder(
        builder: (context, size) => size.isDesktop
            ? _ExploreDesktop(deps: deps)
            : _ExploreStacked(deps: deps, showBrand: size.isMobile),
      ),
    );
  }
}

class _ExploreStacked extends StatelessWidget {
  const _ExploreStacked({required this.deps, required this.showBrand});

  final AppDependencies deps;
  final bool showBrand;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth =
            math.min(constraints.maxWidth, 960.0) - AppSpacing.lg * 2;
        final columns = columnsForWidth(contentWidth);

        return CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              floating: true,
              snap: true,
              automaticallyImplyLeading: false,
              title: showBrand
                  ? const Row(
                      children: <Widget>[
                        BrandMark(size: 30),
                        SizedBox(width: AppSpacing.md),
                        Text('Hotel Booking'),
                      ],
                    )
                  : const Text('Explore'),
            ),
            SliverContentColumn(
              maxWidth: 960,
              sliver: SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  0,
                ),
                sliver: SliverList.list(
                  children: <Widget>[
                    EntranceAnimation(
                      child: _HeroBanner(controller: deps.search),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    EntranceAnimation(
                      delay: const Duration(milliseconds: 80),
                      child: StaySearchPanel(
                        controller: deps.search,
                        onSearch: () => _announceResults(context, deps.search),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    EntranceAnimation(
                      delay: const Duration(milliseconds: 140),
                      child: HotelFiltersBar(controller: deps.search),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _ResultsHeader(controller: deps.search),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
            SliverContentColumn(
              maxWidth: 960,
              sliver: SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: _ResultsSliver(deps: deps, columns: columns),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.only(bottom: AppSpacing.xl),
            ),
          ],
        );
      },
    );
  }
}

class _ExploreDesktop extends StatelessWidget {
  const _ExploreDesktop({required this.deps});

  final AppDependencies deps;

  static const double _sidebarWidth = 380;

  @override
  Widget build(BuildContext context) {
    return ContentColumn(
      maxWidth: 1400,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: _sidebarWidth,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    EntranceAnimation(
                      child: _HeroBanner(controller: deps.search),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    EntranceAnimation(
                      delay: const Duration(milliseconds: 80),
                      child: StaySearchPanel(
                        controller: deps.search,
                        onSearch: () => _announceResults(context, deps.search),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    EntranceAnimation(
                      delay: const Duration(milliseconds: 140),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Refine',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              HotelFiltersBar(
                                controller: deps.search,
                                wrap: true,
                                maxAmenities: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = columnsForWidth(constraints.maxWidth);
                  return CustomScrollView(
                    slivers: <Widget>[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: _ResultsHeader(controller: deps.search),
                        ),
                      ),
                      _ResultsSliver(deps: deps, columns: columns),
                      const SliverPadding(
                        padding: EdgeInsets.only(bottom: AppSpacing.xl),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _announceResults(BuildContext context, HotelSearchController controller) {
  final count = controller.results.length;
  final destination = controller.stay.destination;
  final where = destination.isEmpty ? 'everywhere' : 'for "$destination"';
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text('Showing $count ${count == 1 ? 'stay' : 'stays'} $where'),
      ),
    );
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.controller});

  final HotelSearchController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final stay = controller.stay;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              scheme.primary,
              Color.lerp(scheme.primary, Colors.black, 0.35)!,
            ],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              right: -40,
              top: -60,
              child: _Blob(
                size: 180,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              right: 60,
              bottom: -70,
              child: _Blob(
                size: 140,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Find your next stay',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: scheme.onPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Hand-picked hotels across India. Search by city, dates and guests, '
                  'then book in under a minute.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimary.withValues(alpha: 0.88),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    _BannerPill(
                      icon: Icons.calendar_month_outlined,
                      label: formatDateRange(stay.checkIn, stay.checkOut),
                    ),
                    _BannerPill(
                      icon: Icons.nights_stay_outlined,
                      label: formatNights(stay.nights),
                    ),
                    _BannerPill(
                      icon: Icons.people_outline,
                      label: formatGuests(stay.guests),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _BannerPill extends StatelessWidget {
  const _BannerPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.controller});

  final HotelSearchController controller;

  @override
  Widget build(BuildContext context) {
    final status = controller.status;
    final stay = controller.stay;
    final results = controller.results;
    final count = results.length;
    final noun = count == 1 ? 'stay' : 'stays';

    final String title;
    if (status.isLoading || status == LoadStatus.idle) {
      title = 'Finding stays…';
    } else if (!stay.hasDestination &&
        !controller.filters.hasActiveRefinements) {
      title = 'Recommended stays';
    } else if (stay.hasDestination) {
      title = '$count $noun for ${stay.destination}';
    } else {
      title = '$count $noun found';
    }

    return SectionHeader(
      title: title,
      subtitle:
          '${formatDateRange(stay.checkIn, stay.checkOut)} · '
          '${formatNights(stay.nights)} · ${formatGuests(stay.guests)} · '
          'sorted by ${controller.filters.sort.label.toLowerCase()}',
    );
  }
}

class _ResultsSliver extends StatelessWidget {
  const _ResultsSliver({required this.deps, required this.columns});

  final AppDependencies deps;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final search = deps.search;

    if (search.status.isLoading || search.status == LoadStatus.idle) {
      return HotelResultsSkeletonSliver(columns: columns);
    }
    if (search.status.isFailed) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorState(
          message:
              'We could not load stays right now. Check your connection and try again.',
          onRetry: search.load,
        ),
      );
    }

    final results = search.results;
    if (results.isEmpty) {
      final canReset =
          search.stay.hasDestination || search.filters.hasActiveRefinements;
      return SliverToBoxAdapter(
        child: EmptyState(
          icon: Icons.search_off_outlined,
          title: 'No stays match',
          message:
              'Try another destination, fewer guests, or clear the filters.',
          actionLabel: canReset ? 'Reset search' : null,
          onAction: canReset ? search.resetAll : null,
        ),
      );
    }

    return HotelResultsSliver(
      hotels: results,
      stay: search.stay,
      columns: columns,
      isSaved: (hotel) => deps.saved.isSaved(hotel.id),
      onSaveToggle: (hotel) => _toggleSaved(context, deps, hotel),
      onHotelTap: (hotel, heroTag) => Navigator.of(
        context,
      ).push(HotelDetailsPage.route(hotel: hotel, heroTag: heroTag)),
    );
  }
}

void _toggleSaved(BuildContext context, AppDependencies deps, Hotel hotel) {
  final saved = deps.saved.toggle(hotel);
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(
          saved ? 'Saved ${hotel.name}' : 'Removed ${hotel.name} from saved',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
}
