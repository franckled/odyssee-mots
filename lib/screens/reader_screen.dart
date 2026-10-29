import 'dart:async';

import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets/parent_gate.dart';

class ReaderScreen extends StatefulWidget {
  final Story? existing;
  final String age;
  final StoryHero? hero;
  final String universe;
  final String parentContext;

  const ReaderScreen.newStory({
    super.key,
    required this.age,
    required StoryHero this.hero,
    required this.universe,
    required this.parentContext,
  }) : existing = null;

  ReaderScreen.resume(Story story, {super.key})
      : existing = story,
        age = story.age,
        hero = story.hero,
        universe = story.universe,
        parentContext = story.parentContext;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final api = StoryApi();
  Storage get s => Storage.instance;

  Story? story;
  int index = 0;
  String? error;
  bool waitingNext = false;
  Future<void>? _prefetch;
  Future<void> _imageChain = Future.value();

  // Question de lecture de la page en cours
  final Set<int> _wrongAnswers = {};
  String? _quizFeedback;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      story = widget.existing;
      final firstUnread = story!.pages.indexWhere((p) => !p.read);
      index = firstUnread >= 0 ? firstUnread : 0;
      if (story!.pages.isNotEmpty && story!.cover != null) {
        story!.pages.first.image ??= story!.cover;
      }
      final current = story!.pages[index];
      if (!current.read) _queueImage(current);
      _maybePrefetch();
    } else {
      _begin();
    }
  }

  // ------------------------------------------------------------------
  // Chargement
  // ------------------------------------------------------------------

  Future<void> _begin() async {
    setState(() => error = null);
    try {
      final st = await api.start(
        age: widget.age,
        hero: widget.hero!,
        universe: widget.universe,
        parentContext: widget.parentContext,
      );
      if (!mounted) return;
      setState(() => story = st);
      _queueImage(st.pages.first);
      await s.saveStory(st);
      _maybePrefetch();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  /// Les illustrations sont dessinées l'une après l'autre : la première sert
  /// de modèle aux suivantes pour garder le même héros.
  void _queueImage(StoryPage page) {
    if (page.image != null || page.imageRequested || page.scene.isEmpty) return;
    page.imageRequested = true;
    _imageChain = _imageChain.then((_) async {
      final st = story;
      if (st == null || page.image != null) return;
      try {
        final bytes = await api.image(
          scene: page.scene,
          heroSheet: st.heroSheet,
          reference: page.number == 1 ? null : st.cover,
        );
        if (bytes == null) {
          page.imageFailed = true;
        } else {
          page.image = bytes;
          if (page.number == 1 && st.cover == null) {
            try {
              st.cover = await shrinkImage(bytes);
            } catch (_) {
              st.cover = null;
            }
            await s.saveStory(st);
          }
        }
      } catch (_) {
        page.imageFailed = true;
      }
      if (mounted) setState(() {});
    });
  }

  /// Pendant que l'enfant lit, on prépare déjà la page suivante
  /// (sauf si elle dépend d'un choix).
  void _maybePrefetch() {
    final st = story;
    if (st == null || _prefetch != null) return;
    final last = st.pages.last;
    final needsNext = index >= st.pages.length - 1;
    if (!needsNext || last.isEnd || (last.choice != null && last.chosen == null)) return;
    _prefetch = _fetchNext().whenComplete(() => _prefetch = null);
  }

  Future<void> _fetchNext() async {
    final st = story!;
    try {
      final page = await api.next(st);
      st.pages.add(page);
      _queueImage(page);
      await s.saveStory(st);
      if (mounted) setState(() => error = null);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  // ------------------------------------------------------------------
  // Actions de l'enfant
  // ------------------------------------------------------------------

  StoryPage get page => story!.pages[index];

  void _markRead() {
    setState(() {
      page.read = true;
      s.addStars(1);
    });
    s.saveStory(story!);
  }

  void _answer(int i) {
    final q = page.quiz!;
    setState(() {
      if (i == q.correct) {
        page.quizSolved = true;
        if (_wrongAnswers.isEmpty) s.addStars(1);
        _quizFeedback = _wrongAnswers.isEmpty ? 'Bravo, tu as tout compris ! ⭐' : 'Bien joué ! 👏';
      } else {
        _wrongAnswers.add(i);
        _quizFeedback = 'Presque ! Relis la page, la réponse s\'y cache 🔍';
      }
    });
    s.saveStory(story!);
  }

  Future<void> _choose(String option) async {
    setState(() {
      page.chosen = option;
      waitingNext = true;
    });
    await s.saveStory(story!);
    await _fetchNext();
    if (!mounted) return;
    setState(() => waitingNext = false);
    if (story!.pages.length > index + 1) _goTo(index + 1);
  }

  Future<void> _next() async {
    final st = story!;
    if (index + 1 < st.pages.length) {
      _goTo(index + 1);
      return;
    }
    setState(() => waitingNext = true);
    if (_prefetch != null) {
      await _prefetch;
    } else {
      await _fetchNext();
    }
    if (!mounted) return;
    setState(() => waitingNext = false);
    if (index + 1 < st.pages.length) _goTo(index + 1);
  }

  void _goTo(int i) {
    setState(() {
      index = i;
      _wrongAnswers.clear();
      _quizFeedback = null;
      error = null;
    });
    if (!page.read) _queueImage(page);
    _maybePrefetch();
  }

  Future<void> _report() async {
    if (!await askParentGate(context)) return;
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Signaler cette page ?'),
        content: const Text(
            'Le texte et l\'image de cette page seront masqués. Le signalement est conservé dans l\'espace parents.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Signaler')),
        ],
      ),
    );
    if (ok != true) return;
    final p = page;
    s.addReport('${DateTime.now().toLocal().toString().substring(0, 16)} — « ${story!.title} », page ${p.number} : '
        '${p.text.length > 160 ? '${p.text.substring(0, 160)}…' : p.text}');
    setState(() {
      p.reported = true;
      p.read = true;
    });
    await s.saveStory(story!);
  }

  void _showWord(NewWord w) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final saved = s.hasWord(w.word);
          return Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w.word, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.coral)),
                const SizedBox(height: 10),
                Text(w.definition, style: storyTextStyle(20)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: saved
                        ? null
                        : () {
                            s.addWord(w);
                            setSheet(() {});
                          },
                    icon: Icon(saved ? Icons.check : Icons.bookmark_add),
                    label: Text(saved ? 'Dans mon carnet !' : 'Ajouter à mon carnet'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------------
  // Affichage
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final st = story;
    if (st == null) {
      return Scaffold(
        appBar: AppBar(),
        body: error == null ? const _Preparing() : _ErrorView(message: error!, onRetry: _begin),
      );
    }

    final age = ageGroupOf(st.age);
    final p = page;

    return Scaffold(
      appBar: AppBar(
        title: Text(st.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Signaler (parents)',
            onPressed: p.reported ? null : _report,
            icon: const Icon(Icons.flag_outlined),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              _Progress(current: p.number, total: st.totalPages),
              Expanded(
                child: ListView(
                  key: ValueKey('page-$index'),
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
                  children: [
                    if (p.reported)
                      const _ReportedPage()
                    else ...[
                      _Illustration(page: p, universe: st.universe),
                      const SizedBox(height: 20),
                      SelectableText(p.text, style: storyTextStyle(age.fontSize)),
                      if (p.word != null) ...[
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ActionChip(
                            avatar: const Text('🔎'),
                            label: Text('Mot à découvrir : ${p.word!.word}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            backgroundColor: AppColors.sun.withValues(alpha: 0.35),
                            side: BorderSide.none,
                            onPressed: () => _showWord(p.word!),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 24),
                    _buildActions(p),
                    if (error != null && !waitingNext) ...[
                      const SizedBox(height: 16),
                      _ErrorView(message: error!, onRetry: () {
                        setState(() => error = null);
                        _next();
                      }, compact: true),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(StoryPage p) {
    final st = story!;

    final prevButton = index > 0
        ? TextButton.icon(
            onPressed: () => _goTo(index - 1),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Page précédente'),
          )
        : const SizedBox.shrink();

    // 1. L'enfant lit d'abord la page.
    if (!p.read) {
      return Column(children: [
        FilledButton.icon(
          onPressed: _markRead,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('J\'ai lu cette page'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.mint, foregroundColor: AppColors.navy),
        ),
        const SizedBox(height: 8),
        prevButton,
      ]);
    }

    // 2. Petite question de lecture avant un choix.
    if (p.quiz != null && !p.quizSolved && !p.reported) {
      final q = p.quiz!;
      return _Card(
        color: AppColors.sky.withValues(alpha: 0.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('🧐 Petite question', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navyLight)),
            const SizedBox(height: 6),
            Text(q.question, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy)),
            const SizedBox(height: 12),
            for (var i = 0; i < q.answers.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: _wrongAnswers.contains(i) ? null : () => _answer(i),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(q.answers[i], style: const TextStyle(fontSize: 18)),
                ),
              ),
            if (_quizFeedback != null)
              Text(_quizFeedback!, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.coral)),
          ],
        ),
      );
    }

    // 3. Le moment du choix : l'enfant oriente l'histoire.
    if (p.choice != null && !p.reported) {
      final c = p.choice!;
      final chosen = p.chosen;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_quizFeedback != null && p.quizSolved && chosen == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(_quizFeedback!, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.coral)),
            ),
          _Card(
            color: AppColors.sun.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('✨ À toi de choisir !', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.coral)),
                const SizedBox(height: 6),
                Text(c.question, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.navy)),
                const SizedBox(height: 12),
                for (final o in c.options)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FilledButton(
                      onPressed: chosen == null && !waitingNext ? () => _choose(o) : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: chosen == o ? AppColors.coral : AppColors.navy,
                        disabledBackgroundColor: chosen == o ? AppColors.coral : Colors.black12,
                        disabledForegroundColor: chosen == o ? Colors.white : Colors.black38,
                      ),
                      child: Text(o, textAlign: TextAlign.center),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (waitingNext) const _Waiting(text: 'L\'histoire prend un nouveau chemin…'),
          if (chosen != null && !waitingNext && index + 1 < st.pages.length)
            FilledButton.icon(
              onPressed: _next,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Page suivante'),
            ),
          prevButton,
        ],
      );
    }

    // 4. Fin de l'histoire.
    if (p.isEnd) {
      return _Card(
        color: AppColors.mint.withValues(alpha: 0.35),
        child: Column(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            Text('Bravo ${st.hero.name} et bravo à toi !',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.navy)),
            const SizedBox(height: 6),
            Text('Tu as lu ${st.pagesRead} pages. Ton histoire est rangée dans ta bibliothèque.',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 17)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Retour à l\'accueil'),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => _goTo(0), child: const Text('Relire depuis le début')),
          ],
        ),
      );
    }

    // 5. Page suivante.
    return Column(children: [
      if (waitingNext)
        const _Waiting(text: 'Le conteur écrit la suite…')
      else
        FilledButton.icon(
          onPressed: _next,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Page suivante'),
        ),
      const SizedBox(height: 8),
      prevButton,
    ]);
  }
}

// ----------------------------------------------------------------------
// Petits éléments d'interface
// ----------------------------------------------------------------------

class _Progress extends StatelessWidget {
  final int current;
  final int total;
  const _Progress({required this.current, required this.total});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 6),
        child: Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: current / total,
                minHeight: 12,
                backgroundColor: AppColors.sky.withValues(alpha: 0.35),
                color: AppColors.coral,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('Page $current / $total',
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
        ]),
      );
}

class _Illustration extends StatelessWidget {
  final StoryPage page;
  final String universe;
  const _Illustration({required this.page, required this.universe});

  @override
  Widget build(BuildContext context) {
    final emoji = universes.firstWhere((u) => u.key == universe, orElse: () => universes.last).emoji;
    Widget child;
    if (page.image != null) {
      child = Image.memory(page.image!, fit: BoxFit.cover, gaplessPlayback: true);
    } else if (page.imageFailed || !page.imageRequested) {
      child = Center(child: Text(emoji, style: const TextStyle(fontSize: 90)));
    } else {
      child = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🎨', style: TextStyle(fontSize: 56)),
          SizedBox(height: 10),
          Text('Le pinceau magique dessine…',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.navy)),
          SizedBox(height: 14),
          SizedBox(width: 160, child: LinearProgressIndicator(color: AppColors.coral)),
        ],
      );
    }
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFE7C2), Color(0xFFD5EEFF), Color(0xFFD9F5E8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AnimatedSwitcher(duration: const Duration(milliseconds: 500), child: child),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final Color color;
  const _Card({required this.child, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
        child: child,
      );
}

class _Waiting extends StatelessWidget {
  final String text;
  const _Waiting({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(children: [
          const CircularProgressIndicator(color: AppColors.coral),
          const SizedBox(height: 10),
          Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.navy)),
        ]),
      );
}

class _ReportedPage extends StatelessWidget {
  const _ReportedPage();

  @override
  Widget build(BuildContext context) => _Card(
        color: Colors.black.withValues(alpha: 0.05),
        child: const Text('Cette page a été masquée par un parent.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
      );
}

class _Preparing extends StatefulWidget {
  const _Preparing();

  @override
  State<_Preparing> createState() => _PreparingState();
}

class _PreparingState extends State<_Preparing> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

  static const _messages = [
    'Le conteur ouvre son grand livre…',
    'Il choisit les plus beaux mots…',
    'Il trempe sa plume dans l\'encre magique…',
    'Ton aventure arrive !',
  ];
  int _m = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() => _m = (_m + 1) % _messages.length);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ScaleTransition(
            scale: Tween(begin: 0.85, end: 1.1).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
            child: const Text('📖', style: TextStyle(fontSize: 96)),
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(_messages[_m],
                key: ValueKey(_m),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.navy)),
          ),
        ]),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool compact;
  const _ErrorView({required this.message, required this.onRetry, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final content = Column(mainAxisSize: MainAxisSize.min, children: [
      if (!compact) const Text('🙈', style: TextStyle(fontSize: 72)),
      Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17)),
      const SizedBox(height: 12),
      FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
    ]);
    return compact ? content : Center(child: Padding(padding: const EdgeInsets.all(28), child: content));
  }
}
