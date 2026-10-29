import 'package:flutter/material.dart';

import '../models.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets/parent_gate.dart';
import 'reader_screen.dart';

/// Avant l'histoire, on pose les questions à l'enfant :
/// son âge, son héros ou son héroïne, son nom, sa couleur, l'univers.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late String age = Storage.instance.lastAge;
  String? kind;
  String species = '';
  String? name;
  String color = 'jaune';
  String universe = 'foret';
  String parentContext = '';
  final nameCtrl = TextEditingController();

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  bool get ready =>
      kind != null &&
      (name ?? '').trim().isNotEmpty &&
      (!(kind == 'animal' || kind == 'creature') || species.isNotEmpty);

  void _pickKind(String k) {
    setState(() {
      kind = k;
      species = '';
      name = null;
      nameCtrl.clear();
    });
  }

  Future<void> _editParentContext() async {
    if (!await askParentGate(context)) return;
    if (!mounted) return;
    final ctrl = TextEditingController(text: parentContext);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: const Text('Le début de l\'histoire'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Écrivez un début ou un contexte : un lieu, une situation (un déménagement, '
                'une rentrée, un petit frère qui arrive…), un objet magique. '
                'L\'IA continuera l\'histoire à partir de là.\n\n'
                'Pour protéger votre enfant, n\'indiquez ni nom de famille, ni adresse, ni école.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 6,
                maxLength: 1500,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Il était une fois, dans un petit village corse…',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, ''), child: const Text('Effacer')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Valider')),
        ],
      ),
    );
    if (result != null) setState(() => parentContext = result);
  }

  void _start() {
    Storage.instance.lastAge = age;
    final hero = StoryHero(kind: kind!, species: species, name: name!.trim(), color: color);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ReaderScreen.newStory(
        age: age,
        hero: hero,
        universe: universe,
        parentContext: parentContext,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final speciesList = kind == 'animal'
        ? animalSpecies
        : kind == 'creature'
            ? creatureSpecies
            : const <Option>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Ton histoire')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              const _Question('Quel âge as-tu ?'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final a in ageGroups)
                    _Pill(
                      label: '${a.emoji}  ${a.label}',
                      selected: age == a.key,
                      onTap: () => setState(() => age = a.key),
                    ),
                ],
              ),
              const _Question('Qui sera le héros ou l\'héroïne ?'),
              _CardGrid(
                options: heroKinds,
                selected: kind,
                onTap: _pickKind,
              ),
              if (speciesList.isNotEmpty) ...[
                const _Question('Lequel ?'),
                _CardGrid(
                  options: speciesList,
                  selected: species.isEmpty ? null : species,
                  onTap: (k) => setState(() => species = k),
                ),
              ],
              if (kind != null) ...[
                const _Question('Comment s\'appelle-t-il ou s\'appelle-t-elle ?'),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final n in nameSuggestions[kind] ?? const <String>[])
                      _Pill(
                        label: n,
                        selected: name == n && nameCtrl.text.isEmpty,
                        onTap: () => setState(() {
                          nameCtrl.clear();
                          name = n;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  maxLength: 20,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                    labelText: 'Ou invente un nom de héros',
                    helperText: 'Un nom imaginaire, c\'est encore plus magique ✨',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onChanged: (v) => setState(() => name = v),
                ),
                const _Question('Sa couleur préférée ?'),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final c in heroColors)
                      GestureDetector(
                        onTap: () => setState(() => color = c.name),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Color(c.argb),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color == c.name ? AppColors.navy : Colors.white,
                              width: color == c.name ? 4 : 2,
                            ),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: color == c.name ? const Icon(Icons.check, color: Colors.white) : null,
                        ),
                      ),
                  ],
                ),
              ],
              const _Question('Où se passe l\'aventure ?'),
              _CardGrid(
                options: universes,
                selected: universe,
                onTap: (k) => setState(() => universe = k),
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: _editParentContext,
                icon: const Icon(Icons.edit_note),
                label: Text(parentContext.isEmpty
                    ? 'Un parent écrit le début (facultatif)'
                    : 'Début écrit par un parent ✓ (modifier)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  foregroundColor: AppColors.navy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!ready)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(14)),
              child: Text(
                kind == null
                    ? 'Choisis d\'abord ton héros ou ton héroïne 👆'
                    : (kind == 'animal' || kind == 'creature') && species.isEmpty
                        ? 'Choisis lequel 👆'
                        : 'Choisis ou invente un nom 👆',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: ready ? 1 : 0.45,
        child: FilledButton(
          onPressed: ready ? _start : null,
          style: FilledButton.styleFrom(
            disabledBackgroundColor: AppColors.coral,
            disabledForegroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
          ),
          child: const Text('C\'est parti ! 🚀'),
        ),
      ),
        ],
      ),
    );
  }
}

class _Question extends StatelessWidget {
  final String text;
  const _Question(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 26, bottom: 12),
        child: Text(text,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy)),
      );
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.navy)),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.coral,
        backgroundColor: Colors.white,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      );
}

class _CardGrid extends StatelessWidget {
  final List<Option> options;
  final String? selected;
  final ValueChanged<String> onTap;
  const _CardGrid({required this.options, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final o in options)
          GestureDetector(
            onTap: () => onTap(o.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 132,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: selected == o.key ? AppColors.sky : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected == o.key ? AppColors.navy : Colors.transparent,
                  width: 3,
                ),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Column(
                children: [
                  Text(o.emoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 6),
                  Text(o.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
