import '../domain/hotel.dart';

const sampleHotels = <Hotel>[
  Hotel(
    name: 'The Park Residency',
    location: 'Park Street, Kolkata',
    description: 'Central stay with fast access to restaurants and museums.',
    nightlyPrice: 6400,
    rating: 4.7,
    tags: <String>['Breakfast', 'Wi-Fi', 'City view'],
  ),
  Hotel(
    name: 'Riverside Grand',
    location: 'BBD Bagh, Kolkata',
    description: 'Business-friendly rooms close to the riverfront.',
    nightlyPrice: 7200,
    rating: 4.6,
    tags: <String>['Workspace', 'Gym', 'Airport pickup'],
  ),
  Hotel(
    name: 'Salt Lake Suites',
    location: 'Sector V, Kolkata',
    description: 'Quiet serviced suites for longer work trips.',
    nightlyPrice: 5100,
    rating: 4.5,
    tags: <String>['Kitchenette', 'Parking', 'Laundry'],
  ),
];
