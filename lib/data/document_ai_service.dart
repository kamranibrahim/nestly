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

class DocumentAiService {
  DocumentAiService({
    FirebaseAuth? auth,
    http.Client? client,
    String? baseUrl,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _client = client ?? http.Client(),
        _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'NESTLY_AI_URL',
              defaultValue: '',
            );

  final FirebaseAuth _auth;
  final http.Client _client;
  final String _baseUrl;

  /// Production Netlify site URL hosting `/api/parse-document`.
  /// Override with `--dart-define=NESTLY_AI_URL=https://yoursite.netlify.app`
  static const fallbackSiteUrl = String.fromEnvironment(
    'NESTLY_SITE_URL',
    defaultValue: '',
  );

  Uri get _endpoint {
    final configured = _baseUrl.trim();
    if (configured.isNotEmpty) {
      return Uri.parse(configured);
    }
    final site = fallbackSiteUrl.trim().replaceAll(RegExp(r'/$'), '');
    if (site.isNotEmpty) {
      return Uri.parse('$site/api/parse-document');
    }
    throw StateError(
      'Set NESTLY_SITE_URL or NESTLY_AI_URL so Nestly can reach the AI API.',
    );
  }

  Future<DocumentDraft> parseDocument({
    required Uint8List bytes,
    required String mimeType,
    String? hint,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in to scan documents.');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Could not get auth token.');
    }

    final response = await _client
        .post(
          _endpoint,
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

    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      final message = decoded is Map && decoded['error'] is String
          ? decoded['error'] as String
          : 'Scan failed (${response.statusCode})';
      throw StateError(message);
    }

    final draftJson = decoded is Map ? decoded['draft'] : null;
    if (draftJson is! Map) {
      throw StateError('Unexpected AI response');
    }
    return DocumentDraft.fromJson(Map<String, dynamic>.from(draftJson));
  }
}
