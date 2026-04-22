import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive_layout.dart';
import '../../data/sample_hotels.dart';
import '../../domain/hotel.dart';
import '../widgets/booking_search_panel.dart';
import '../widgets/hotel_card.dart';

class HotelSearchPage extends StatefulWidget {
  const HotelSearchPage({Key? key}) : super(key: key);

  @override
  State<HotelSearchPage> createState() => _HotelSearchPageState();
}

class _HotelSearchPageState extends State<HotelSearchPage> {
  final TextEditingController _destinationController =
      TextEditingController(text: 'Kolkata');

  late DateTime _checkInDate;
  int _guestCount = 2;
  final Set<String> _savedHotelNames = <String>{};

  @override
  void initState() {
    super.initState();
    _checkInDate = DateTime.now().add(const Duration(days: 2));
    _destinationController.addListener(_refreshSearchResults);
  }

  @override
  void dispose() {
    _destinationController.removeListener(_refreshSearchResults);
    _destinationController.dispose();
    super.dispose();
  }

  List<Hotel> get _visibleHotels {
    final query = _destinationController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return sampleHotels;
    }

    return sampleHotels.where((hotel) {
      final searchableText = <String>[
        hotel.name,
        hotel.location,
        hotel.description,
        ...hotel.tags,
      ].join(' ').toLowerCase();

      return searchableText.contains(query);
    }).toList(growable: false);
  }

  void _refreshSearchResults() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  void _handleSearchPressed() {
    final trimmedDestination = _destinationController.text.trim();
    if (_destinationController.text != trimmedDestination) {
      _destinationController.text = trimmedDestination;
      _destinationController.selection = TextSelection.collapsed(
        offset: trimmedDestination.length,
      );
    }

    FocusScope.of(context).unfocus();

    final resultCount = _visibleHotels.length;
    final destination =
        trimmedDestination.isEmpty ? 'all destinations' : trimmedDestination;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Showing $resultCount stays for $destination'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleDateChanged(DateTime date) {
    setState(() {
      _checkInDate = date;
    });
  }

  void _handleGuestCountChanged(int guestCount) {
    setState(() {
      _guestCount = guestCount.clamp(1, 6).toInt();
    });
  }

  void _clearFilters() {
    _destinationController.clear();

    setState(() {
      _checkInDate = DateTime.now().add(const Duration(days: 2));
      _guestCount = 2;
    });
  }

  void _toggleSavedHotel(Hotel hotel) {
    setState(() {
      if (_savedHotelNames.contains(hotel.name)) {
        _savedHotelNames.remove(hotel.name);
      } else {
        _savedHotelNames.add(hotel.name);
      }
    });
  }

  void _showSavedHotels() {
    final savedHotels = sampleHotels
        .where((hotel) => _savedHotelNames.contains(hotel.name))
        .toList(growable: false);

    if (savedHotels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No saved hotels yet'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            shrinkWrap: true,
            children: <Widget>[
              Text(
                'Saved hotels',
                style: Theme.of(context).textTheme.titleMedium != null
                    ? Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                        )
                    : const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
              ),
              const SizedBox(height: 8),
              for (final hotel in savedHotels)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.hotel_outlined,
                    color: Color(0xFF143D36),
                  ),
                  title: Text(hotel.name),
                  subtitle: Text(hotel.location),
                  trailing: Text('Rs ${hotel.nightlyPrice}'),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchPanel = BookingSearchPanel(
      destinationController: _destinationController,
      selectedDate: _checkInDate,
      guestCount: _guestCount,
      onDateChanged: _handleDateChanged,
      onGuestCountChanged: _handleGuestCountChanged,
      onSearchPressed: _handleSearchPressed,
      onClearPressed: _clearFilters,
    );
    final results = _RecommendedHotels(
      hotels: _visibleHotels,
      activeQuery: _destinationController.text,
      savedHotelNames: _savedHotelNames,
      onSavedToggle: _toggleSavedHotel,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel Booking'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Saved hotels',
            icon: const Icon(Icons.favorite_border),
            onPressed: _showSavedHotels,
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: _HotelSearchMobile(
            searchPanel: searchPanel,
            results: results,
          ),
          tablet: _HotelSearchWide(
            maxContentWidth: 840,
            searchPanel: searchPanel,
            results: results,
          ),
          desktop: _HotelSearchWide(
            maxContentWidth: 1180,
            searchPanel: searchPanel,
            results: results,
          ),
        ),
      ),
    );
  }
}

class _HotelSearchMobile extends StatelessWidget {
  const _HotelSearchMobile({
    Key? key,
    required this.searchPanel,
    required this.results,
  }) : super(key: key);

  final Widget searchPanel;
  final Widget results;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const _PageIntro(),
        const SizedBox(height: 16),
        searchPanel,
        const SizedBox(height: 24),
        results,
      ],
    );
  }
}

class _HotelSearchWide extends StatelessWidget {
  const _HotelSearchWide({
    Key? key,
    required this.maxContentWidth,
    required this.searchPanel,
    required this.results,
  }) : super(key: key);

  final double maxContentWidth;
  final Widget searchPanel;
  final Widget results;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const _PageIntro(),
                      const SizedBox(height: 16),
                      searchPanel,
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 5,
                  child: results,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageIntro extends StatelessWidget {
  const _PageIntro({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF143D36),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Find stays that fit the trip',
            style: textTheme.headlineSmall != null
                ? textTheme.headlineSmall!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  )
                : const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search curated hotels by city, dates, guests, and comfort needs.',
            style: textTheme.bodyMedium != null
                ? textTheme.bodyMedium!.copyWith(
                    color: const Color(0xFFDCE8E5),
                    height: 1.4,
                  )
                : const TextStyle(
                    color: Color(0xFFDCE8E5),
                    height: 1.4,
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedHotels extends StatelessWidget {
  const _RecommendedHotels({
    Key? key,
    required this.hotels,
    required this.activeQuery,
    required this.savedHotelNames,
    required this.onSavedToggle,
  }) : super(key: key);

  final List<Hotel> hotels;
  final String activeQuery;
  final Set<String> savedHotelNames;
  final ValueChanged<Hotel> onSavedToggle;

  @override
  Widget build(BuildContext context) {
    final query = activeQuery.trim();
    final heading =
        query.isEmpty ? 'Recommended stays' : '${hotels.length} stays found';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          heading,
          style: Theme.of(context).textTheme.titleMedium != null
              ? Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  )
              : const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (hotels.isEmpty)
          const _EmptyHotelResults()
        else
          for (final hotel in hotels) ...<Widget>[
            HotelCard(
              hotel: hotel,
              isSaved: savedHotelNames.contains(hotel.name),
              onSavedToggle: () => onSavedToggle(hotel),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _EmptyHotelResults extends StatelessWidget {
  const _EmptyHotelResults({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: const <Widget>[
            Icon(Icons.search_off_outlined, color: Color(0xFF52616A)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No matching hotels found. Try a different city, area, or amenity.',
                style: TextStyle(color: Color(0xFF52616A), height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
