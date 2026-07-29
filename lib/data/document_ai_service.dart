import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Draft extracted from a receipt, invitation, or PDF via Nestly AI.
class DocumentDraft {
  const DocumentDraft({
    required this.kind,
    required this.title,
    required this.confidence,
    required this.allDay,
    this.startsAt,
    this.endsAt,
    this.location,
    this.amount,
    this.currency,
    this.category,
    this.notes,
    this.summary,
  });

  final String kind; // event | expense | task | unknown
  final String title;
  final double confidence;
  final bool allDay;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? location;
  final double? amount;
  final String? currency;
  final String? category;
  final String? notes;
  final String? summary;

  bool get isLowConfidence => confidence < 0.55;

  factory DocumentDraft.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(dynamic value) {
      if (value is! String || value.trim().isEmpty) return null;
      return DateTime.tryParse(value.trim());
    }

    double? parseAmount(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return DocumentDraft(
      kind: (json['kind'] as String?)?.trim().toLowerCase() ?? 'unknown',
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : 'Untitled',
      confidence: (json['confidence'] is num)
          ? (json['confidence'] as num).toDouble()
          : 0.5,
      allDay: json['allDay'] == true,
      startsAt: parseDt(json['startsAt']),
      endsAt: parseDt(json['endsAt']),
      location: (json['location'] as String?)?.trim(),
      amount: parseAmount(json['amount']),
      currency: (json['currency'] as String?)?.trim(),
      category: (json['category'] as String?)?.trim(),
      notes: (json['notes'] as String?)?.trim(),
      summary: (json['summary'] as String?)?.trim(),
    );
  }
}

/// User-facing scan failure (avoids raw "Bad state:" snackbars).
class DocumentAiException implements Exception {
  const DocumentAiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DocumentAiService {
  DocumentAiService({
    FirebaseAuth? auth,
    http.Client? client,
    String? baseUrl,
    String? siteUrl,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _client = client ?? http.Client(),
        _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'NESTLY_AI_URL',
              defaultValue: '',
            ),
        _siteUrl = siteUrl ?? fallbackSiteUrl;

  final FirebaseAuth _auth;
  final http.Client _client;
  final String _baseUrl;
  final String _siteUrl;

  /// Production Netlify site hosting `/api/parse-document`.
  /// Override with `--dart-define=NESTLY_SITE_URL=https://…`
  static const fallbackSiteUrl = String.fromEnvironment(
    'NESTLY_SITE_URL',
    defaultValue: 'https://glowing-strudel-442ff8.netlify.app',
  );

  bool get isConfigured {
    try {
      _endpoint;
      return true;
    } catch (_) {
      return false;
    }
  }

  Uri get _endpoint {
    final configured = _baseUrl.trim();
    if (configured.isNotEmpty) {
      return Uri.parse(configured);
    }
    final site = _siteUrl.trim().replaceAll(RegExp(r'/$'), '');
    if (site.isNotEmpty) {
      return Uri.parse('$site/api/parse-document');
    }
    throw const DocumentAiException(
      'Document scan is not configured. Set NESTLY_SITE_URL to your '
      'Netlify site, then try again.',
    );
  }

  Future<DocumentDraft> parseDocument({
    required Uint8List bytes,
    required String mimeType,
    String? hint,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const DocumentAiException('Sign in to scan documents.');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw const DocumentAiException(
        'Could not get auth token. Sign out, sign back in, then try again.',
      );
    }

    if (bytes.length > 4 * 1024 * 1024) {
      throw const DocumentAiException(
        'That file is too large. Use a photo or PDF under about 4 MB.',
      );
    }

    final endpoint = _endpoint;

    try {
      final response = await _client
          .post(
            endpoint,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'mimeType': mimeType,
              'dataBase64': base64Encode(bytes),
              if (hint != null && hint.trim().isNotEmpty) 'hint': hint.trim(),
            }),
          )
          .timeout(const Duration(seconds: 60));

      Object? decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }

      if (response.statusCode >= 400) {
        throw DocumentAiException(
          _messageForStatus(response.statusCode, decoded),
        );
      }

      final draftJson = decoded is Map ? decoded['draft'] : null;
      if (draftJson is! Map) {
        throw const DocumentAiException(
          'Scan returned an unexpected response. Try another photo.',
        );
      }
      return DocumentDraft.fromJson(Map<String, dynamic>.from(draftJson));
    } on DocumentAiException {
      rethrow;
    } on http.ClientException {
      throw const DocumentAiException(
        'Could not reach the scan service. Check your connection and try again.',
      );
    } catch (e) {
      final text = '$e'.toLowerCase();
      if (text.contains('timeout')) {
        throw const DocumentAiException(
          'Scan timed out. Try a clearer photo or a smaller file.',
        );
      }
      if (text.contains('socket') || text.contains('failed host lookup')) {
        throw const DocumentAiException(
          'Could not reach the scan service. Check your connection and try again.',
        );
      }
      throw const DocumentAiException(
        'Could not finish the scan. Check your connection and try again.',
      );
    }
  }

  static String _messageForStatus(int status, Object? decoded) {
    final server = decoded is Map && decoded['error'] is String
        ? (decoded['error'] as String).trim()
        : '';
    final lower = server.toLowerCase();

    if (status == 401) {
      return 'Sign in required. Sign out, sign back in, then try again.';
    }
    if (status == 413) {
      return server.isNotEmpty
          ? server
          : 'That file is too large. Use a photo or PDF under about 4 MB.';
    }
    if (status == 400 && server.isNotEmpty) {
      return server;
    }
    if (lower.contains('api key') ||
        lower.contains('ai gateway') ||
        lower.contains('permission') ||
        lower.contains('unauthorized') ||
        lower.contains('credential')) {
      return 'AI Gateway is not ready on Netlify yet. Enable it in site '
          'settings, wait a minute, then try again.';
    }
    if (status >= 500) {
      if (server.isNotEmpty && server.length < 120) {
        return 'Scan service error: $server';
      }
      return 'Scan service had a problem. Try again in a moment.';
    }
    if (server.isNotEmpty) return server;
    return 'Scan failed ($status). Try again.';
  }
}
