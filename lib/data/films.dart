import '../models/place.dart';

const films = <FieldFilm>[
  FieldFilm(
    id: 'north-of-silence',
    title: 'North of Silence',
    placeId: 'lofoten',
    location: 'Lofoten, Norway',
    description: 'The E10 at blue hour. No narration, no music. Just the wind.',
    duration: '0:08',
    year: '2026',
  ),
  FieldFilm(
    id: 'the-long-light',
    title: 'The Long Light',
    placeId: 'sicily',
    location: 'Sicily, Italy',
    description: 'A sailboat crosses the last warm hour.',
    duration: '0:07',
    year: '2026',
  ),
  FieldFilm(
    id: 'rain-slowly',
    title: 'Rain, Slowly',
    placeId: 'kyoto',
    location: 'Kyoto, Japan',
    description: 'Morning fog, a gate, and the patience of water.',
    duration: '0:08',
    year: '2026',
  ),
  FieldFilm(
    id: 'river-of-lanterns',
    title: 'River of Lanterns',
    placeId: 'hoian',
    location: 'Hội An, Vietnam',
    description: 'Paper moons drift downstream.',
    duration: '0:07',
    year: '2026',
  ),
  FieldFilm(
    id: 'between-dunes',
    title: 'Between Dunes',
    placeId: 'merzouga',
    location: 'Merzouga, Morocco',
    description: 'The sand remembers every footstep for a few minutes.',
    duration: '0:06',
    year: '2026',
  ),
];

FieldFilm? filmForPlace(String placeId) {
  for (final film in films) {
    if (film.placeId == placeId) return film;
  }
  return null;
}

FieldFilm filmById(String id) => films.firstWhere((f) => f.id == id);
