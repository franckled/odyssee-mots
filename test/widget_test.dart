import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:odyssee_mots/models.dart';

void main() {
  test('une histoire se sauvegarde et se relit', () {
    final story = Story(
      id: '1',
      title: 'Lina et la lune',
      heroSheet: 'a girl with a yellow scarf',
      totalPages: 10,
      age: '5-7',
      hero: const StoryHero(kind: 'fille', name: 'Lina', color: 'jaune'),
      universe: 'foret',
      parentContext: '',
      createdAt: DateTime(2026, 10, 29),
      pages: [
        StoryPage(
          number: 3,
          text: 'Il était une fois…',
          scene: 'forest',
          isEnd: false,
          choice: const StoryChoice('Que fais-tu ?', ['Suivre le lapin', 'Grimper à l\'arbre']),
          quiz: const ReadingQuiz('Quelle couleur ?', ['Rouge', 'Jaune', 'Bleu'], 1),
        ),
      ],
    );
    final copy = Story.fromJson(story.toJson());
    expect(copy.title, 'Lina et la lune');
    expect(copy.pages.first.choice!.options.length, 2);
    expect(copy.pages.first.quiz!.correct, 1);
    expect(ageGroupOf('13+').label, '13 ans et +');
    expect(copy.imageStyle, defaultIllustrationStyle);
  });

  test('le style de dessin est gardé, et les anciennes histoires passent en aquarelle', () {
    final story = Story(
      id: '2',
      title: 'Bip sur la lune',
      heroSheet: 'a small round robot',
      totalPages: 10,
      age: '7-9',
      hero: const StoryHero(kind: 'robot', name: 'Bip', color: 'bleu'),
      universe: 'espace',
      parentContext: '',
      imageStyle: 'pate',
      createdAt: DateTime(2026, 11, 2),
      pages: const [],
    );
    expect(Story.fromJson(story.toJson()).imageStyle, 'pate');
    final old = story.toJson()..remove('imageStyle');
    expect(Story.fromJson(old).imageStyle, 'aquarelle');
    expect(illustrationStyles.map((o) => o.key), contains(defaultIllustrationStyle));
  });

  test('un autocollant se sauvegarde et se relit', () {
    final st = Sticker(
      storyId: '2',
      page: 4,
      title: 'Bip sur la lune',
      image: Uint8List.fromList([1, 2, 3]),
      earnedAt: DateTime(2026, 11, 2),
    );
    final copy = Sticker.fromJson(st.toJson())!;
    expect(copy.key, '2#4');
    expect(copy.image, [1, 2, 3]);
    expect(Sticker.fromJson({'page': 1}), isNull);
  });
}
