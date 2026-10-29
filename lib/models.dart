import 'dart:convert';
import 'dart:typed_data';

/// Tranches d'âge proposées (les clés correspondent au serveur).
class AgeGroup {
  final String key;
  final String label;
  final String emoji;
  final double fontSize;
  const AgeGroup(this.key, this.label, this.emoji, this.fontSize);
}

const ageGroups = <AgeGroup>[
  AgeGroup('5-7', '5 – 7 ans', '🐣', 25),
  AgeGroup('7-9', '7 – 9 ans', '🐥', 22),
  AgeGroup('9-11', '9 – 11 ans', '🦉', 20),
  AgeGroup('11-13', '11 – 13 ans', '🦊', 19),
  AgeGroup('13+', '13 ans et +', '🦅', 18),
];

AgeGroup ageGroupOf(String key) =>
    ageGroups.firstWhere((a) => a.key == key, orElse: () => ageGroups[1]);

class Option {
  final String key;
  final String label;
  final String emoji;
  const Option(this.key, this.label, this.emoji);
}

const heroKinds = <Option>[
  Option('fille', 'Une fille', '👧'),
  Option('garcon', 'Un garçon', '👦'),
  Option('animal', 'Un animal', '🦊'),
  Option('robot', 'Un robot', '🤖'),
  Option('creature', 'Une créature magique', '🐉'),
];

const animalSpecies = <Option>[
  Option('renard', 'Renard', '🦊'),
  Option('lapin', 'Lapin', '🐰'),
  Option('chat', 'Chat', '🐱'),
  Option('ours', 'Ourson', '🐻'),
  Option('tortue', 'Tortue', '🐢'),
  Option('hibou', 'Hibou', '🦉'),
];

const creatureSpecies = <Option>[
  Option('petit dragon gentil', 'Dragon', '🐉'),
  Option('licorne', 'Licorne', '🦄'),
  Option('fée', 'Fée', '🧚'),
  Option('lutin', 'Lutin', '🍄'),
];

const nameSuggestions = <String, List<String>>{
  'fille': ['Lina', 'Zoé', 'Maëlle', 'Romy', 'Nina'],
  'garcon': ['Malo', 'Noé', 'Elio', 'Sacha', 'Tom'],
  'animal': ['Pistache', 'Caramel', 'Noisette', 'Plume', 'Biscotte'],
  'robot': ['Bip', 'Zigzag', 'Boulon', 'Pixel', 'Tic-Tac'],
  'creature': ['Lumi', 'Fizz', 'Grelot', 'Opaline', 'Brindille'],
};

class HeroColor {
  final String name;
  final int argb;
  const HeroColor(this.name, this.argb);
}

const heroColors = <HeroColor>[
  HeroColor('rouge', 0xFFE8574A),
  HeroColor('orange', 0xFFF59A3C),
  HeroColor('jaune', 0xFFFFCB45),
  HeroColor('vert', 0xFF5CC48A),
  HeroColor('turquoise', 0xFF3CC2C4),
  HeroColor('bleu', 0xFF4C8FE0),
  HeroColor('violet', 0xFF9A6BD8),
  HeroColor('rose', 0xFFF08DB8),
];

const universes = <Option>[
  Option('foret', 'Forêt enchantée', '🌳'),
  Option('ocean', 'Océan', '🐠'),
  Option('espace', 'Espace', '🚀'),
  Option('chateau', 'Château', '🏰'),
  Option('montagne', 'Montagnes', '⛰️'),
  Option('ville', 'Ville secrète', '🏙️'),
  Option('dinosaures', 'Dinosaures', '🦕'),
  Option('surprise', 'Surprise !', '🎁'),
];

class StoryHero {
  final String kind;
  final String species;
  final String name;
  final String color;
  const StoryHero({required this.kind, this.species = '', required this.name, required this.color});

  Map<String, dynamic> toJson() => {'kind': kind, 'species': species, 'name': name, 'color': color};

  factory StoryHero.fromJson(Map<String, dynamic> j) => StoryHero(
        kind: j['kind'] ?? 'fille',
        species: j['species'] ?? '',
        name: j['name'] ?? 'Lou',
        color: j['color'] ?? 'jaune',
      );
}

class NewWord {
  final String word;
  final String definition;
  const NewWord(this.word, this.definition);

  Map<String, dynamic> toJson() => {'word': word, 'definition': definition};

  static NewWord? fromJson(dynamic j) {
    if (j is! Map || (j['word'] ?? '').toString().isEmpty) return null;
    return NewWord(j['word'].toString(), (j['definition'] ?? '').toString());
  }
}

class ReadingQuiz {
  final String question;
  final List<String> answers;
  final int correct;
  const ReadingQuiz(this.question, this.answers, this.correct);

  Map<String, dynamic> toJson() => {'question': question, 'answers': answers, 'correct': correct};

  static ReadingQuiz? fromJson(dynamic j) {
    if (j is! Map || j['answers'] is! List) return null;
    return ReadingQuiz(
      (j['question'] ?? '').toString(),
      (j['answers'] as List).map((e) => e.toString()).toList(),
      (j['correct'] as num?)?.toInt() ?? 0,
    );
  }
}

class StoryChoice {
  final String question;
  final List<String> options;
  const StoryChoice(this.question, this.options);

  Map<String, dynamic> toJson() => {'question': question, 'options': options};

  static StoryChoice? fromJson(dynamic j) {
    if (j is! Map || j['options'] is! List) return null;
    return StoryChoice(
      (j['question'] ?? '').toString(),
      (j['options'] as List).map((e) => e.toString()).toList(),
    );
  }
}

class StoryPage {
  final int number;
  final String text;
  final String scene;
  final bool isEnd;
  final NewWord? word;
  final ReadingQuiz? quiz;
  final StoryChoice? choice;

  // Progression de l'enfant
  String? chosen;
  bool read;
  bool quizSolved;
  bool reported;

  // Illustration (gardée en mémoire seulement, trop lourde pour être sauvegardée)
  Uint8List? image;
  bool imageFailed = false;
  bool imageRequested = false;

  StoryPage({
    required this.number,
    required this.text,
    required this.scene,
    required this.isEnd,
    this.word,
    this.quiz,
    this.choice,
    this.chosen,
    this.read = false,
    this.quizSolved = false,
    this.reported = false,
  });

  factory StoryPage.fromJson(Map<String, dynamic> j) => StoryPage(
        number: (j['number'] as num?)?.toInt() ?? 1,
        text: (j['text'] ?? '').toString(),
        scene: (j['scene'] ?? '').toString(),
        isEnd: j['isEnd'] == true,
        word: NewWord.fromJson(j['word']),
        quiz: ReadingQuiz.fromJson(j['quiz']),
        choice: StoryChoice.fromJson(j['choice']),
        chosen: j['chosen'] as String?,
        read: j['read'] == true,
        quizSolved: j['quizSolved'] == true,
        reported: j['reported'] == true,
      );

  Map<String, dynamic> toJson() => {
        'number': number,
        'text': text,
        'scene': scene,
        'isEnd': isEnd,
        'word': word?.toJson(),
        'quiz': quiz?.toJson(),
        'choice': choice?.toJson(),
        'chosen': chosen,
        'read': read,
        'quizSolved': quizSolved,
        'reported': reported,
      };
}

class Story {
  final String id;
  final String title;
  final String heroSheet;
  final int totalPages;
  final String age;
  final StoryHero hero;
  final String universe;
  final String parentContext;
  final DateTime createdAt;
  final List<StoryPage> pages;

  /// Petite version de la première illustration : couverture dans la
  /// bibliothèque et modèle du héros pour garder le même personnage.
  Uint8List? cover;

  Story({
    required this.id,
    required this.title,
    required this.heroSheet,
    required this.totalPages,
    required this.age,
    required this.hero,
    required this.universe,
    required this.parentContext,
    required this.createdAt,
    required this.pages,
    this.cover,
  });

  bool get finished => pages.isNotEmpty && pages.last.isEnd && pages.last.read;

  int get pagesRead => pages.where((p) => p.read).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'heroSheet': heroSheet,
        'totalPages': totalPages,
        'age': age,
        'hero': hero.toJson(),
        'universe': universe,
        'parentContext': parentContext,
        'createdAt': createdAt.toIso8601String(),
        'pages': pages.map((p) => p.toJson()).toList(),
        'cover': cover == null ? null : base64Encode(cover!),
      };

  factory Story.fromJson(Map<String, dynamic> j) => Story(
        id: j['id'].toString(),
        title: (j['title'] ?? '').toString(),
        heroSheet: (j['heroSheet'] ?? '').toString(),
        totalPages: (j['totalPages'] as num?)?.toInt() ?? 10,
        age: (j['age'] ?? '7-9').toString(),
        hero: StoryHero.fromJson(Map<String, dynamic>.from(j['hero'] ?? {})),
        universe: (j['universe'] ?? 'surprise').toString(),
        parentContext: (j['parentContext'] ?? '').toString(),
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        pages: ((j['pages'] as List?) ?? [])
            .map((p) => StoryPage.fromJson(Map<String, dynamic>.from(p)))
            .toList(),
        cover: j['cover'] is String ? base64Decode(j['cover']) : null,
      );
}
