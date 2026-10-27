import '../models/place.dart';

const places = <Place>[
  Place(
    id: 'lofoten',
    name: 'Lofoten',
    country: 'Norway',
    region: 'Nordic',
    noteNumber: '01',
    title: 'The quiet end of the world',
    lede:
        'Above the Arctic Circle, the road runs out of adjectives. Red cabins turn amber at dusk. The sea keeps its own time.',
    season: 'SEP — MAR',
    days: '6 DAYS',
    coordinates: '68.2° N / 14.4° E',
    story: [
      'You arrive in the dark and wake to a horizon that refuses to end. In Lofoten the mountains do not sit behind the water — they rise out of it, patient and unfinished, while the light moves across them like something alive.',
      'The villages are small enough to miss. A handful of wooden houses, a cod-drying rack, a café that opens when the owner feels like it. Nobody hurries. The weather changes five times before lunch, and no one mentions it.',
    ],
    notes: [
      FieldNote(
        title: 'Drive the E10 after nine',
        body:
            'The blue hour lasts for hours here. Pull over near Reine and watch the peaks turn to paper.',
      ),
      FieldNote(
        title: 'Eat where the fishermen eat',
        body:
            'A red cabin, a plastic chair, a bowl of fish soup. This is the whole luxury.',
      ),
      FieldNote(
        title: 'Wait for the aurora',
        body: 'It is not guaranteed. The silence is.',
      ),
    ],
    quote:
        'Some places don’t ask you to stay. They simply make leaving impossible.',
    quoteSource: 'Field notes, Reine',
    galleryCaptions: [
      'First light, 05:42',
      'The water refuses to stay still',
      'A cabin with one lamp on',
    ],
    nearby: ['faroe', 'patagonia'],
    keywords: ['arctic', 'mountains', 'fjord', 'aurora', 'sea', 'north'],
  ),
  Place(
    id: 'oaxaca',
    name: 'Oaxaca',
    country: 'Mexico',
    region: 'Latin America',
    noteNumber: '02',
    title: 'A city that tastes like smoke',
    lede:
        'Markets before sunrise, mezcal after dark, and a hundred shades of red in between.',
    season: 'OCT — MAR',
    days: '5 DAYS',
    coordinates: '17.0° N / 96.7° W',
    story: [
      'The market opens while it is still dark. Women arrange marigolds in neat pyramid, a man grinds cacao with a stone, and the air smells of charcoal, wet clay, and something sweet you cannot name. You came for breakfast and stayed for the argument happening two stalls over.',
      'In the afternoon the light turns the walls the colour of burnt sugar. Sit in the zócalo. Let the city come to you. It will.',
    ],
    notes: [
      FieldNote(
        title: 'Arrive hungry, leave slowly',
        body:
            'Mercado 20 de Noviembre. Order the tlayuda. Then order another one.',
      ),
      FieldNote(
        title: 'Climb at six',
        body:
            'Monte Albán before the buses. The ruins are better when the valley is still full of mist.',
      ),
      FieldNote(
        title: 'Say yes to the last mezcal',
        body:
            'Find a palenque outside the city. The good bottles never have labels.',
      ),
    ],
    quote:
        'The best meal of your life will cost eleven dollars and happen on a plastic chair.',
    quoteSource: 'Field notes, Oaxaca de Juárez',
    galleryCaptions: [
      'Marigolds, before the market opens',
      'The long afternoon, in ochre',
      'Smoke from a kitchen that never closes',
    ],
    nearby: ['merzouga', 'sicily'],
    keywords: ['desert', 'food', 'market', 'mezcal', 'colour', 'mexico'],
  ),
  Place(
    id: 'kyoto',
    name: 'Kyoto',
    country: 'Japan',
    region: 'Asia',
    noteNumber: '03',
    title: 'Rain, and everything after',
    lede:
        'The city keeps a second city beneath it: stone, moss, and a thousand small ceremonies.',
    season: 'MAR — MAY / NOV',
    days: '7 DAYS',
    coordinates: '35.0° N / 135.8° E',
    story: [
      'It rains on the second day and does not stop. The temples look better for it. Vermilion turns deeper, moss turns almost black, and the gravel gardens become diagrams of water. You stop taking photographs and simply stand there.',
      'In the evening, find a kissaten with three tables and no menu in English. Point at the set breakfast. The owner will nod, make a small ceremony of the coffee, and leave you alone with the rain.',
    ],
    notes: [
      FieldNote(
        title: 'Go before the gates open',
        body:
            'Fushimi Inari at six in the morning. The mountain belongs to the people sweeping it.',
      ),
      FieldNote(
        title: 'Order the set',
        body:
            'A kissaten breakfast: thick toast, a boiled egg, coffee poured with both hands.',
      ),
      FieldNote(
        title: 'Walk the philosopher’s path in the rain',
        body:
            'The canal, the hydrangeas, the little bridges. Bring no umbrella — borrow one.',
      ),
    ],
    quote: 'Beauty here is not a spectacle. It is a habit.',
    quoteSource: 'Field notes, Higashiyama',
    galleryCaptions: [
      'A gate, keeping the fog',
      'The city after rain',
      'Moss doing its slow work',
    ],
    nearby: ['hoian', 'sicily'],
    keywords: ['rain', 'temple', 'forest', 'torii', 'japan', 'slow'],
  ),
  Place(
    id: 'faroe',
    name: 'Faroe Islands',
    country: 'Denmark',
    region: 'Nordic',
    noteNumber: '04',
    title: 'Weather as a love language',
    lede:
        'Eighteen islands, one bridge, and more weather than you have names for.',
    season: 'MAY — SEP',
    days: '4 DAYS',
    coordinates: '62.0° N / 7.0° W',
    story: [
      'The ferry leaves when the sea allows it. In between, there are turf-roofed houses, waterfalls that fall upward in the wind, and a silence so complete you can hear your own coat moving.',
      'The Faroes do not perform for visitors. The weather arrives, rearranges the view, and leaves. You learn to stop checking the forecast and start dressing for it.',
    ],
    notes: [
      FieldNote(
        title: 'Go to Saksun at low tide',
        body:
            'The lagoon empties, the church looks impossible, and the walk back is all sheep and small waterfalls.',
      ),
      FieldNote(
        title: 'Find the waterfall that faces the sea',
        body:
            'Múlafossur, in Gásadalur. Stand still long enough for the wind to change.',
      ),
      FieldNote(
        title: 'Take the ferry to Mykines',
        body:
            'If it sails. If it doesn’t, that is also the Faroes. Wait in the harbour with a coffee.',
      ),
    ],
    quote: 'There is no bad weather. Only the wrong coat.',
    quoteSource: 'Field notes, Gásadalur',
    galleryCaptions: [
      'Two rocks, one weather system',
      'The sea, keeping its distance',
      'A house the wind knows well',
    ],
    nearby: ['lofoten', 'patagonia'],
    keywords: ['fog', 'islands', 'cliffs', 'sea', 'weather', 'nordic'],
  ),
  Place(
    id: 'merzouga',
    name: 'Merzouga',
    country: 'Morocco',
    region: 'Africa',
    noteNumber: '05',
    title: 'The blue hour, loudly',
    lede:
        'The Sahara doesn’t arrive. It accumulates — one dune, then another, until the horizon forgets where it was.',
    season: 'OCT — APR',
    days: '3 DAYS',
    coordinates: '31.1° N / 4.0° W',
    story: [
      'The road from Fes unspools for eight hours. Then the tarmac ends and the sand begins. You leave the car, climb onto a camel, and enter a landscape that makes a mockery of distance.',
      'At camp, dinner is served under a sky with too many stars. The wind moves over the dunes, softly, all night, like a conversation in another room.',
    ],
    notes: [
      FieldNote(
        title: 'Take the long way',
        body:
            'The road from Fes through Midelt. Stop for oranges and a roadside tajine.',
      ),
      FieldNote(
        title: 'Sleep outside the tent',
        body:
            'A mattress on the sand. The temperature drops, the stars double, and nobody minds.',
      ),
      FieldNote(
        title: 'Wake before the sun',
        body:
            'Climb the nearest dune at five-thirty. Watch the sand turn from grey to rose to gold.',
      ),
    ],
    quote:
        'The desert does not make you small. It makes everything else quieter.',
    quoteSource: 'Field notes, Erg Chebbi',
    galleryCaptions: [
      'The blue hour, arriving',
      'One tent, three dunes',
      'Sand remembering a footstep',
    ],
    nearby: ['oaxaca', 'sicily'],
    keywords: ['sahara', 'desert', 'dunes', 'stars', 'camp', 'africa'],
  ),
  Place(
    id: 'patagonia',
    name: 'Patagonia',
    country: 'Chile',
    region: 'Latin America',
    noteNumber: '06',
    title: 'A place that outlasts you',
    lede: 'Wind, granite, ice. The scale is rude about your plans.',
    season: 'NOV — MAR',
    days: '9 DAYS',
    coordinates: '51.0° S / 73.0° W',
    story: [
      'The towers appear at dawn, briefly, before the clouds close again. You wait two days for this. When it happens, nobody speaks — the wind is doing all the talking.',
      'Patagonia is not a place you settle into. It is a place you keep negotiating with: the weather, the distances, the weight of your pack. Then a puma crosses the road, and the negotiation becomes a privilege.',
    ],
    notes: [
      FieldNote(
        title: 'Watch the towers at first light',
        body:
            'Torres del Paine, from the Mirador. Bring more layers than you think.',
      ),
      FieldNote(
        title: 'Tie everything down',
        body:
            'The wind is not a metaphor here. It will take your hat, your tent, and your assumptions.',
      ),
      FieldNote(
        title: 'Take the slow road',
        body:
            'The Carretera Austral. Gravel, rivers, and long stretches with no signal at all.',
      ),
    ],
    quote: 'You do not conquer Patagonia. You are allowed to visit.',
    quoteSource: 'Field notes, Torres del Paine',
    galleryCaptions: [
      'The towers, briefly',
      'Wind writing on the water',
      'A tent that won’t stay still',
    ],
    nearby: ['lofoten', 'faroe'],
    keywords: ['mountains', 'ice', 'wind', 'hiking', 'tent', 'south america'],
  ),
  Place(
    id: 'hoian',
    name: 'Hội An',
    country: 'Vietnam',
    region: 'Asia',
    noteNumber: '07',
    title: 'Lanterns on the river',
    lede:
        'Every evening the old town lights a thousand paper moons and lets them float.',
    season: 'FEB — APR',
    days: '4 DAYS',
    coordinates: '15.9° N / 108.3° E',
    story: [
      'At dusk, the tailor shops close and the river fills with small lights. Paper lanterns drift downstream with wishes inside them. The reflection doubles everything: the bridge, the boats, the people leaning over the water.',
      'In the morning, the same streets are almost empty. A woman sells bánh mì from a cart, a man repairs a bicycle, and the river is just a river again.',
    ],
    notes: [
      FieldNote(
        title: 'Swim at five-thirty',
        body:
            'An Bang beach before the town wakes. The water is warm and the horizon is empty.',
      ),
      FieldNote(
        title: 'Order the bánh mì',
        body:
            'Madam Khanh’s cart. Crisp bread, pâté, herbs, chilli. Eat it standing up.',
      ),
      FieldNote(
        title: 'Find the lantern makers',
        body:
            'Nguyễn Thái Học, late afternoon. Watch a bamboo frame become a small moon.',
      ),
    ],
    quote: 'Some light is meant to be let go.',
    quoteSource: 'Field notes, An Hội',
    galleryCaptions: [
      'Paper moons, ready',
      'The river, doubled',
      'A street before the heat',
    ],
    nearby: ['kyoto', 'sicily'],
    keywords: ['lanterns', 'river', 'night', 'vietnam', 'food', 'asia'],
  ),
  Place(
    id: 'sicily',
    name: 'Sicily',
    country: 'Italy',
    region: 'Europe',
    noteNumber: '08',
    title: 'The island that keeps secrets',
    lede:
        'An island conquered so many times it has learned to keep its best stories for the back streets.',
    season: 'APR — JUN / SEP',
    days: '6 DAYS',
    coordinates: '37.5° N / 14.0° E',
    story: [
      'Sicily is not one place. It is a Greek temple, an Arab market, a Norman cathedral, and a bar where the granita is made with the stubbornness of a family argument. You can taste the history, but mostly you taste the lemon.',
      'The sea is never far away. Drive south, find a beach with no name, swim until you are hungry, and eat something that takes three hours. This is the itinerary.',
    ],
    notes: [
      FieldNote(
        title: 'Swim before breakfast',
        body:
            'Scala dei Turchi, early. The white cliffs turn pink and the beach is yours.',
      ),
      FieldNote(
        title: 'Granita is breakfast',
        body:
            'A bar in Catania. Almond granita, a brioche, espresso. Do not explain it to anyone.',
      ),
      FieldNote(
        title: 'Take the last ferry',
        body:
            'The Aeolian Islands at golden hour. Stromboli smokes politely in the distance.',
      ),
    ],
    quote: 'The south does not explain itself. It simply opens another bottle.',
    quoteSource: 'Field notes, Noto',
    galleryCaptions: [
      'The last warm hour',
      'A sea that insists on blue',
      'Stone, light, lunch',
    ],
    nearby: ['faroe', 'hoian'],
    keywords: ['sea', 'island', 'food', 'italy', 'summer', 'europe'],
  ),
];

Place placeById(String id) => places.firstWhere((p) => p.id == id);

/// Deep-link/screenshot helper: accepts home, explore, films, saved.
const tabNames = ['journal', 'explore', 'films', 'saved'];

int tabIndexFromName(String? name) {
  final index = tabNames.indexOf(name ?? 'journal');
  return index < 0 ? 0 : index;
}
