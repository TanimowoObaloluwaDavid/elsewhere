class FieldFilm {
  const FieldFilm({
    required this.id,
    required this.title,
    required this.placeId,
    required this.location,
    required this.description,
    required this.duration,
    required this.year,
  });

  final String id;
  final String title;
  final String placeId;
  final String location;
  final String description;
  final String duration;
  final String year;

  String get asset => 'assets/videos/$id.mp4';
  String get poster => 'assets/images/${placeId}_02.jpg';

  String get tag => 'A silent field film · $year';
}

class FieldNote {
  const FieldNote({required this.title, required this.body});

  final String title;
  final String body;
}

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.country,
    required this.region,
    required this.noteNumber,
    required this.title,
    required this.lede,
    required this.season,
    required this.days,
    required this.coordinates,
    required this.story,
    required this.notes,
    required this.quote,
    required this.quoteSource,
    required this.galleryCaptions,
    required this.nearby,
    required this.keywords,
  });

  final String id;
  final String name;
  final String country;
  final String region;
  final String noteNumber;
  final String title;
  final String lede;
  final String season;
  final String days;
  final String coordinates;
  final List<String> story;
  final List<FieldNote> notes;
  final String quote;
  final String quoteSource;
  final List<String> galleryCaptions;
  final List<String> nearby;
  final List<String> keywords;

  String get hero => 'assets/images/${id}_01.jpg';
  String get wide => 'assets/images/${id}_02.jpg';
  String get square => 'assets/images/${id}_03.jpg';
  List<String> get gallery => [hero, wide, square];

  String get placeLine => '$country · $region';
}
