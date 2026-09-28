import '../domain/hotel.dart';

/// Fictional inventory used by the in-memory repository.
///
/// Hotels span several Indian cities so destination search, party-size limits
/// and every filter have something meaningful to act on.
const List<Hotel> sampleHotels = <Hotel>[
  Hotel(
    id: 'kol-park-residency',
    name: 'The Park Residency',
    city: 'Kolkata',
    area: 'Park Street',
    tagline: 'Central stay steps from cafés, bookshops and museums.',
    description:
        'A refurbished 1930s townhouse on Park Street with high ceilings, '
        'restored teak floors and a quiet courtyard café. Rooms face either the '
        'street or the inner garden, and the rooftop opens for breakfast with a '
        'view over the Maidan.',
    nightlyPrice: 6400,
    rating: 4.7,
    reviewCount: 812,
    maxGuests: 3,
    category: HotelCategory.boutique,
    amenities: <String>[
      'Free Wi-Fi',
      'Breakfast included',
      'City view',
      'Rooftop café',
      'Laundry',
    ],
    freeCancellation: true,
  ),
  Hotel(
    id: 'kol-riverside-grand',
    name: 'Riverside Grand',
    city: 'Kolkata',
    area: 'BBD Bagh',
    tagline: 'Business-ready rooms beside the Hooghly riverfront.',
    description:
        'Purpose-built for work trips: every room has a proper desk, blackout '
        'blinds and a coffee machine. The lobby lounge doubles as a co-working '
        'space and the gym stays open around the clock.',
    nightlyPrice: 7200,
    rating: 4.6,
    reviewCount: 1043,
    maxGuests: 2,
    category: HotelCategory.business,
    amenities: <String>[
      'Free Wi-Fi',
      'Workspace',
      'Gym',
      'Airport pickup',
      'Parking',
    ],
  ),
  Hotel(
    id: 'kol-salt-lake-suites',
    name: 'Salt Lake Suites',
    city: 'Kolkata',
    area: 'Sector V',
    tagline: 'Quiet serviced suites for longer stays.',
    description:
        'One- and two-bedroom apartments with full kitchens, weekly housekeeping '
        'and a small residents-only pool. Popular with families relocating and '
        'consultants on multi-week engagements.',
    nightlyPrice: 5100,
    rating: 4.5,
    reviewCount: 356,
    maxGuests: 4,
    category: HotelCategory.business,
    amenities: <String>[
      'Free Wi-Fi',
      'Kitchenette',
      'Parking',
      'Laundry',
      'Pool',
    ],
    freeCancellation: true,
  ),
  Hotel(
    id: 'goa-anjuna-shore',
    name: 'Anjuna Shore Resort',
    city: 'Goa',
    area: 'Anjuna',
    tagline: 'Beachfront villas under the palms.',
    description:
        'Twelve villas set back from Anjuna beach, each with its own veranda '
        'and outdoor shower. The pool bar serves lunch until late and bikes are '
        'free to borrow for the ride to the Wednesday flea market.',
    nightlyPrice: 11800,
    rating: 4.8,
    reviewCount: 624,
    maxGuests: 4,
    category: HotelCategory.resort,
    amenities: <String>[
      'Free Wi-Fi',
      'Pool',
      'Sea view',
      'Breakfast included',
      'Spa',
      'Airport pickup',
    ],
    freeCancellation: true,
  ),
  Hotel(
    id: 'goa-panjim-latin',
    name: 'Casa Fontainhas',
    city: 'Goa',
    area: 'Panjim',
    tagline: 'A painted Portuguese house in the Latin Quarter.',
    description:
        'Six rooms in a restored heritage home with azulejo tiles, shuttered '
        'windows and a shaded patio. Breakfast is Goan: poi bread, chouriço and '
        'seasonal fruit from the Panjim market.',
    nightlyPrice: 5600,
    rating: 4.6,
    reviewCount: 289,
    maxGuests: 2,
    category: HotelCategory.heritage,
    amenities: <String>[
      'Free Wi-Fi',
      'Breakfast included',
      'City view',
      'Pet friendly',
    ],
  ),
  Hotel(
    id: 'mum-marine-drive',
    name: 'Marine Drive Residences',
    city: 'Mumbai',
    area: 'Churchgate',
    tagline: 'Art Deco rooms overlooking the Queen\'s Necklace.',
    description:
        'An Art Deco landmark on Marine Drive with sea-facing rooms, a '
        'members-style bar and one of the best sunset views in the city. '
        'Churchgate station is a four-minute walk.',
    nightlyPrice: 14500,
    rating: 4.7,
    reviewCount: 1520,
    maxGuests: 3,
    category: HotelCategory.heritage,
    amenities: <String>[
      'Free Wi-Fi',
      'Sea view',
      'Rooftop bar',
      'Gym',
      'Breakfast included',
    ],
  ),
  Hotel(
    id: 'mum-bkc-loft',
    name: 'BKC Loft Hotel',
    city: 'Mumbai',
    area: 'Bandra Kurla Complex',
    tagline: 'Smart rooms for meetings in the business district.',
    description:
        'Compact, well-designed rooms across the road from the BKC offices. '
        'Meeting pods can be booked by the hour and the breakfast counter runs '
        'from 5 a.m. for early flights.',
    nightlyPrice: 8900,
    rating: 4.4,
    reviewCount: 733,
    maxGuests: 2,
    category: HotelCategory.business,
    amenities: <String>['Free Wi-Fi', 'Workspace', 'Gym', 'Airport pickup'],
    freeCancellation: true,
  ),
  Hotel(
    id: 'jai-haveli-amber',
    name: 'Amber Haveli',
    city: 'Jaipur',
    area: 'Old City',
    tagline: 'Frescoed courtyards inside the Pink City walls.',
    description:
        'A family-run haveli with hand-painted rooms arranged around two '
        'courtyards. Evenings bring folk music on the terrace and a view of '
        'Hawa Mahal lit up across the rooftops.',
    nightlyPrice: 6900,
    rating: 4.8,
    reviewCount: 415,
    maxGuests: 4,
    category: HotelCategory.heritage,
    amenities: <String>[
      'Free Wi-Fi',
      'Breakfast included',
      'Rooftop café',
      'City view',
      'Airport pickup',
    ],
    freeCancellation: true,
  ),
  Hotel(
    id: 'blr-indiranagar-loft',
    name: 'Indiranagar Studio Stays',
    city: 'Bengaluru',
    area: 'Indiranagar',
    tagline: 'Design-led studios on 100 Feet Road.',
    description:
        'Loft-style studios above a specialty coffee roaster, with fast fibre, '
        'standing desks and a shared terrace. Walkable to the metro and the '
        'best of Indiranagar\'s restaurants.',
    nightlyPrice: 4300,
    rating: 4.5,
    reviewCount: 502,
    maxGuests: 2,
    category: HotelCategory.boutique,
    amenities: <String>[
      'Free Wi-Fi',
      'Workspace',
      'Kitchenette',
      'Laundry',
      'Pet friendly',
    ],
  ),
  Hotel(
    id: 'blr-whitefield-inn',
    name: 'Whitefield Express Inn',
    city: 'Bengaluru',
    area: 'Whitefield',
    tagline: 'Clean, no-frills rooms near the tech parks.',
    description:
        'A reliable budget option for project trips: spotless rooms, strong '
        'showers, a 24-hour front desk and free parking. Breakfast is simple '
        'and served early.',
    nightlyPrice: 2600,
    rating: 4.2,
    reviewCount: 968,
    maxGuests: 3,
    category: HotelCategory.budget,
    amenities: <String>[
      'Free Wi-Fi',
      'Parking',
      'Breakfast included',
      'Laundry',
    ],
    freeCancellation: true,
  ),
  Hotel(
    id: 'del-lodhi-garden',
    name: 'Lodhi Garden House',
    city: 'New Delhi',
    area: 'Lodhi Colony',
    tagline: 'Leafy calm between the gardens and the galleries.',
    description:
        'A converted bungalow with a lawn, a small pool and a library that '
        'hosts readings. Lodhi Garden, the India Habitat Centre and Khan Market '
        'are all within a ten-minute walk.',
    nightlyPrice: 9800,
    rating: 4.6,
    reviewCount: 388,
    maxGuests: 3,
    category: HotelCategory.boutique,
    amenities: <String>[
      'Free Wi-Fi',
      'Pool',
      'Breakfast included',
      'Parking',
      'Spa',
    ],
    freeCancellation: true,
  ),
  Hotel(
    id: 'udp-lake-palace-view',
    name: 'Pichola View Retreat',
    city: 'Udaipur',
    area: 'Lal Ghat',
    tagline: 'Lake-facing rooms and a sunset terrace.',
    description:
        'Whitewashed rooms stacked above the ghats with balconies over Lake '
        'Pichola. The rooftop restaurant is a local favourite for dinner as the '
        'City Palace lights come on.',
    nightlyPrice: 7600,
    rating: 4.7,
    reviewCount: 611,
    maxGuests: 3,
    category: HotelCategory.heritage,
    amenities: <String>[
      'Free Wi-Fi',
      'Lake view',
      'Breakfast included',
      'Rooftop café',
      'Airport pickup',
    ],
  ),
  Hotel(
    id: 'drj-tea-estate',
    name: 'Glenview Tea Estate Bungalow',
    city: 'Darjeeling',
    area: 'Happy Valley',
    tagline: 'Planter\'s bungalow amid the tea gardens.',
    description:
        'Four suites in a working tea estate with fireplaces, a wraparound '
        'veranda and Kanchenjunga views on clear mornings. Guided tastings and '
        'garden walks are included.',
    nightlyPrice: 12400,
    rating: 4.9,
    reviewCount: 142,
    maxGuests: 6,
    category: HotelCategory.resort,
    amenities: <String>[
      'Free Wi-Fi',
      'Mountain view',
      'Breakfast included',
      'Spa',
      'Parking',
    ],
    freeCancellation: true,
  ),
];
