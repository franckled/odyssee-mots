import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;

import 'models.dart';
import 'storage.dart';

class ApiException implements Exception {
  final String message;
  final String? code;
  ApiException(this.message, [this.code]);

  /// Quota du jour atteint (gratuit ou abonné).
  bool get isQuota => code == 'quota' || code == 'quota_premium' || code == 'global';

  @override
  String toString() => message;
}

class QuotaStatus {
  final bool admin;
  final bool premium;
  final int used;
  final int? limit;
  const QuotaStatus({required this.admin, required this.premium, required this.used, this.limit});

  int? get remaining => limit == null ? null : (limit! - used).clamp(0, limit!);
}

/// Dialogue avec le serveur Cloudflare (qui, lui, parle aux IA).
class StoryApi {
  Storage get _s => Storage.instance;

  Uri _uri(String path) {
    var base = _s.workerUrl;
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    return Uri.parse('$base$path');
  }

  /// Chaque installation reçoit automatiquement un jeton anonyme :
  /// la famille n'a rien à saisir.
  Future<void> _ensureToken() async {
    if (_s.accessCode.isNotEmpty || _s.deviceToken.isNotEmpty) return;
    final data = await _send('/register', const {}, const Duration(seconds: 20), auth: false);
    _s.deviceToken = (data['token'] ?? '').toString();
  }

  Map<String, String> _headers() {
    final h = {'Content-Type': 'application/json'};
    if (_s.accessCode.isNotEmpty) {
      h['X-Access-Code'] = _s.accessCode;
    } else if (_s.deviceToken.isNotEmpty) {
      h['Authorization'] = 'Bearer ${_s.deviceToken}';
    }
    return h;
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body,
      {Duration timeout = const Duration(seconds: 150)}) async {
    if (!_s.isConfigured) {
      throw ApiException("L'application n'est pas encore réglée. Demande à un parent d'ouvrir l'espace parents.");
    }
    await _ensureToken();
    try {
      return await _send(path, body, timeout);
    } on ApiException catch (e) {
      // Jeton perdu ou refusé : on en redemande un, une seule fois.
      if (e.code == 'token' && _s.accessCode.isEmpty) {
        _s.deviceToken = '';
        await _ensureToken();
        return _send(path, body, timeout);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _send(String path, Map<String, dynamic> body, Duration timeout,
      {bool auth = true}) async {
    http.Response res;
    try {
      res = await http
          .post(
            _uri(path),
            headers: auth ? _headers() : const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw ApiException('Le conteur met trop de temps à répondre. Réessaie dans un instant.');
    } catch (e) {
      throw ApiException('Impossible de joindre le conteur. Vérifie la connexion internet.\n\n(Détail technique : $e)');
    }
    Map<String, dynamic> data;
    try {
      data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Réponse inattendue du conteur (${res.statusCode}).');
    }
    if (res.statusCode != 200) {
      final code = data['code'] as String?;
      final msg = (data['error'] ?? 'Erreur ${res.statusCode}').toString();
      if (code != null || res.statusCode == 401) throw ApiException(msg, code);
      final detail = (data['detail'] ?? '').toString();
      throw ApiException(detail.isNotEmpty && !msg.contains(detail) ? '$msg\n\n(Détail technique : $detail)' : msg);
    }
    return data;
  }

  Future<QuotaStatus> status() async {
    final d = await _post('/status', const {}, timeout: const Duration(seconds: 20));
    return QuotaStatus(
      admin: d['admin'] == true,
      premium: d['premium'] == true,
      used: (d['used'] as num?)?.toInt() ?? 0,
      limit: (d['limit'] as num?)?.toInt(),
    );
  }

  /// Vérifie l'adresse du serveur et le code d'accès.
  Future<void> testConnection() async {
    await status();
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

  /// [chosenForLast] : prépare à l'avance la suite d'une option du choix en cours.
  Future<StoryPage> next(Story story, {String? chosenForLast}) async {
    final pages = [
      for (var i = 0; i < story.pages.length; i++)
        {
          'text': story.pages[i].text,
          'chosen': i == story.pages.length - 1 && chosenForLast != null ? chosenForLast : story.pages[i].chosen,
        }
    ];
    final data = await _post('/next', {
      'age': story.age,
      'hero': story.hero.toJson(),
      'universe': story.universe,
      'title': story.title,
      'parentContext': story.parentContext,
      'pages': pages,
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
