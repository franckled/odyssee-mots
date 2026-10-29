import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;

import 'models.dart';
import 'storage.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// Dialogue avec le serveur Cloudflare (qui, lui, parle aux IA).
class StoryApi {
  Storage get _s => Storage.instance;

  Uri _uri(String path) {
    var base = _s.workerUrl;
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    return Uri.parse('$base$path');
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body,
      {Duration timeout = const Duration(seconds: 90)}) async {
    if (!_s.isConfigured) {
      throw ApiException("L'application n'est pas encore réglée. Demande à un parent d'ouvrir l'espace parents.");
    }
    http.Response res;
    try {
      res = await http
          .post(
            _uri(path),
            headers: {'Content-Type': 'application/json', 'X-Access-Code': _s.accessCode},
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } catch (_) {
      throw ApiException('Impossible de joindre le conteur. Vérifie la connexion internet.');
    }
    Map<String, dynamic> data;
    try {
      data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Réponse inattendue du conteur (${res.statusCode}).');
    }
    if (res.statusCode != 200) {
      if (res.statusCode == 401) throw ApiException("Code d'accès incorrect (espace parents).");
      throw ApiException((data['error'] ?? 'Erreur ${res.statusCode}').toString());
    }
    return data;
  }

  /// Vérifie l'adresse du serveur et le code d'accès.
  Future<void> testConnection() async {
    await _post('/check-context', {'context': ''}, timeout: const Duration(seconds: 20));
  }

  Future<Story> start({
    required String age,
    required StoryHero hero,
    required String universe,
    required String parentContext,
  }) async {
    final data = await _post('/start', {
      'age': age,
      'hero': hero.toJson(),
      'universe': universe,
      'parentContext': parentContext,
    });
    return Story(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: (data['title'] ?? 'Mon histoire').toString(),
      heroSheet: (data['heroSheet'] ?? '').toString(),
      totalPages: (data['totalPages'] as num?)?.toInt() ?? 10,
      age: age,
      hero: hero,
      universe: universe,
      parentContext: parentContext,
      createdAt: DateTime.now(),
      pages: [StoryPage.fromJson(Map<String, dynamic>.from(data['page']))],
    );
  }

  Future<StoryPage> next(Story story) async {
    final data = await _post('/next', {
      'age': story.age,
      'hero': story.hero.toJson(),
      'universe': story.universe,
      'title': story.title,
      'parentContext': story.parentContext,
      'pages': story.pages.map((p) => {'text': p.text, 'chosen': p.chosen}).toList(),
    });
    return StoryPage.fromJson(Map<String, dynamic>.from(data['page']));
  }

  /// Renvoie l'illustration, ou null si elle a été bloquée par les filtres.
  Future<Uint8List?> image({required String scene, required String heroSheet, Uint8List? reference}) async {
    final data = await _post(
      '/image',
      {
        'scene': scene,
        'heroSheet': heroSheet,
        if (reference != null) 'reference': base64Encode(reference),
        if (reference != null) 'referenceMime': 'image/png',
      },
      timeout: const Duration(seconds: 120),
    );
    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;
    final parts = (candidates.first['content'] ?? const {})['parts'];
    if (parts is! List) return null;
    for (final p in parts) {
      final inline = p['inlineData'] ?? p['inline_data'];
      if (inline is Map && inline['data'] is String) {
        return base64Decode(inline['data'] as String);
      }
    }
    return null;
  }
}

/// Réduit une image (pour la couverture et le modèle du héros).
Future<Uint8List> shrinkImage(Uint8List bytes, {int width = 384}) async {
  final codec = await ui.instantiateImageCodec(bytes, targetWidth: width);
  final frame = await codec.getNextFrame();
  final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
  frame.image.dispose();
  return data!.buffer.asUint8List();
}
