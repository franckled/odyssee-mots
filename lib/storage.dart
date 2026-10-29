import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Tout est stocké sur l'appareil uniquement : rien ne part sur un serveur.
class Storage {
  Storage._(this._p);
  final SharedPreferences _p;

  static late Storage instance;

  static Future<void> init() async {
    instance = Storage._(await SharedPreferences.getInstance());
  }

  /// Adresse du serveur intégrée à l'application (réglée au moment de la
  /// compilation par GitHub Actions, variable WORKER_URL du dépôt).
  static const _defaultWorkerUrl = String.fromEnvironment('WORKER_URL');
  static const maxStories = 20;

  // ---- Réglages parent ----
  String get workerUrl {
    final saved = _p.getString('workerUrl') ?? '';
    return saved.isNotEmpty ? saved : _defaultWorkerUrl;
  }

  set workerUrl(String v) => _p.setString('workerUrl', v.trim());

  String get accessCode => _p.getString('accessCode') ?? '';
  set accessCode(String v) => _p.setString('accessCode', v.trim());

  bool get isConfigured => workerUrl.isNotEmpty;

  /// Jeton anonyme propre à cet appareil (donné par le serveur).
  String get deviceToken => _p.getString('deviceToken') ?? '';
  set deviceToken(String v) => _p.setString('deviceToken', v);

  /// Identifiant anonyme de l'appareil (sert aussi pour l'abonnement).
  String get deviceId => deviceToken.contains('.') ? deviceToken.split('.').first : '';

  bool get consentGiven => _p.getBool('consent') ?? false;
  set consentGiven(bool v) => _p.setBool('consent', v);

  String get lastAge => _p.getString('lastAge') ?? '7-9';
  set lastAge(String v) => _p.setString('lastAge', v);

  // ---- Étoiles de lecture ----
  int get stars => _p.getInt('stars') ?? 0;
  void addStars(int n) => _p.setInt('stars', stars + n);

  // ---- Carnet de mots ----
  List<NewWord> get words {
    final raw = _p.getStringList('words') ?? [];
    return raw.map((s) => NewWord.fromJson(jsonDecode(s))).whereType<NewWord>().toList();
  }

  bool hasWord(String word) => words.any((w) => w.word.toLowerCase() == word.toLowerCase());

  void addWord(NewWord w) {
    if (hasWord(w.word)) return;
    final raw = _p.getStringList('words') ?? [];
    raw.insert(0, jsonEncode(w.toJson()));
    _p.setStringList('words', raw);
  }

  void removeWord(String word) {
    final raw = (_p.getStringList('words') ?? []).where((s) {
      final w = NewWord.fromJson(jsonDecode(s));
      return w == null || w.word != word;
    }).toList();
    _p.setStringList('words', raw);
  }

  // ---- Bibliothèque ----
  List<Story> get stories {
    final raw = _p.getStringList('stories') ?? [];
    final out = <Story>[];
    for (final s in raw) {
      try {
        out.add(Story.fromJson(jsonDecode(s)));
      } catch (_) {
        // histoire illisible : on l'ignore
      }
    }
    return out;
  }

  Future<void> saveStory(Story story) async {
    final list = stories.where((s) => s.id != story.id).toList();
    list.insert(0, story);
    final trimmed = list.take(maxStories).map((s) => jsonEncode(s.toJson())).toList();
    try {
      await _p.setStringList('stories', trimmed);
    } catch (_) {
      // Mémoire du navigateur pleine : on retire les couvertures des plus anciennes.
      final light = list.take(maxStories).toList();
      for (var i = 3; i < light.length; i++) {
        light[i].cover = null;
      }
      await _p.setStringList('stories', light.map((s) => jsonEncode(s.toJson())).toList());
    }
  }

  Future<void> deleteStory(String id) async {
    final raw = stories.where((s) => s.id != id).map((s) => jsonEncode(s.toJson())).toList();
    await _p.setStringList('stories', raw);
  }

  // ---- Signalements faits par le parent ----
  List<String> get reports => _p.getStringList('reports') ?? [];

  void addReport(String text) {
    final r = reports..insert(0, text);
    _p.setStringList('reports', r.take(50).toList());
  }

  Future<void> clearAll() async {
    final keep = {
      for (final k in ['workerUrl', 'accessCode', 'deviceToken']) k: _p.getString(k),
    };
    final consent = consentGiven;
    await _p.clear();
    for (final e in keep.entries) {
      if (e.value != null) await _p.setString(e.key, e.value!);
    }
    consentGiven = consent;
  }
}
