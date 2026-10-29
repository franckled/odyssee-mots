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
  });
}
