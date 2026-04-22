class Hotel {
  const Hotel({
    required this.name,
    required this.location,
    required this.description,
    required this.nightlyPrice,
    required this.rating,
    required this.tags,
  });

  final String name;
  final String location;
  final String description;
  final int nightlyPrice;
  final double rating;
  final List<String> tags;
}
