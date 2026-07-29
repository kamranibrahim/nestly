import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

/// User-facing scan failure (avoids raw exception snackbars).
class DocumentAiException implements Exception {
  const DocumentAiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Quiet document scan via **Firebase AI Logic → Vertex AI Gemini**.
///
/// Requires a Blaze Firebase project with Vertex AI Gemini enabled.
class DocumentAiService {
  DocumentAiService({
    FirebaseAuth? auth,
    String location = 'us-central1',
  })  : _auth = auth ?? FirebaseAuth.instance,
        _location = location;

  final FirebaseAuth _auth;
  final String _location;

  /// Always available when Firebase is configured; user must be signed in to call.
  bool get isConfigured => true;

  Future<DocumentDraft> parseDocument({
    required Uint8List bytes,
    required String mimeType,
    String? hint,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const DocumentAiException('Sign in to scan documents.');
    }

    if (bytes.length > 4 * 1024 * 1024) {
      throw const DocumentAiException(
        'That file is too large. Use a photo or PDF under about 4 MB.',
      );
    }

    final today = DateTime.now().toIso8601String().split('T').first;
    final hintLine = (hint == null || hint.trim().isEmpty)
        ? ''
        : 'User hint: ${hint.trim()}\n';

    final prompt = '''
You extract structured family-organizer data from a photo or PDF (receipt, invitation, school notice, appointment card, flyer).
Today's date is $today (use this to resolve relative dates like "tomorrow" or weekday-only dates).
$hintLine
Return ONLY valid JSON (no markdown) with this shape:
{
  "kind": "event" | "expense" | "task" | "unknown",
  "confidence": number between 0 and 1,
  "title": string,
  "startsAt": string | null (ISO-8601 datetime if known),
  "endsAt": string | null,
  "allDay": boolean,
  "location": string | null,
  "amount": number | null (receipt total if present),
  "currency": string | null (e.g. "USD"),
  "category": string | null,
  "notes": string | null,
  "summary": string (one short sentence of what you saw)
}

Rules:
- Prefer kind "event" for invitations, appointments, school/sports schedules.
- Prefer kind "expense" for store receipts with a clear total.
- Prefer kind "task" for todo-like notes without a firm datetime.
- If unsure of datetime, set startsAt to null and allDay false.
- Do not invent a title; use the clearest label from the document.
''';

    try {
      final model = FirebaseAI.vertexAI(location: _location).generativeModel(
        // Vertex requires a concrete model id (aliases like gemini-flash-latest
        // are Gemini Developer API only).
        model: 'gemini-2.5-flash',
        generationConfig: GenerationConfig(
          temperature: 0.2,
          responseMimeType: 'application/json',
        ),
      );

      final response = await model.generateContent([
        Content.multi([
          InlineDataPart(mimeType, bytes),
          TextPart(prompt),
        ]),
      ]).timeout(const Duration(seconds: 60));

      final text = response.text?.trim() ?? '';
      if (text.isEmpty) {
        throw const DocumentAiException(
          'Scan returned an empty result. Try a clearer photo.',
        );
      }

      final jsonMap = _decodeJsonObject(text);
      return DocumentDraft.fromJson(jsonMap);
    } on DocumentAiException {
      rethrow;
    } catch (e) {
      throw DocumentAiException(_friendlyFirebaseError(e));
    }
  }

  static Map<String, dynamic> _decodeJsonObject(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (match != null) {
        final decoded = jsonDecode(match.group(0)!);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    }
    throw const DocumentAiException(
      'Scan returned an unexpected response. Try another photo.',
    );
  }

  static String _friendlyFirebaseError(Object e) {
    final text = '$e';
    final lower = text.toLowerCase();
    if (lower.contains('billing') ||
        lower.contains('blaze') ||
        lower.contains('payment') ||
        lower.contains('enable billing')) {
      return 'Vertex AI needs the Firebase Blaze plan. Upgrade billing in '
          'Firebase Console, enable Vertex AI, then try again.';
    }
    if (lower.contains('permission') ||
        lower.contains('permission_denied') ||
        lower.contains('not enabled') ||
        lower.contains('ai logic') ||
        lower.contains('api key') ||
        lower.contains('unauthenticated') ||
        lower.contains('vertex')) {
      return 'Vertex AI Gemini is not ready. In Firebase Console enable '
          'AI Logic with the Vertex AI Gemini API (Blaze), then try again.';
    }
    if (lower.contains('timeout')) {
      return 'Scan timed out. Try a clearer photo or a smaller file.';
    }
    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('unavailable')) {
      return 'Could not reach Vertex AI. Check your connection and try again.';
    }
    if (lower.contains('quota') || lower.contains('resource exhausted')) {
      return 'AI quota reached for today. Try again later.';
    }
    return text
        .replaceFirst(RegExp(r'^\[firebase_ai[^\]]*\]\s*'), '')
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .trim();
  }
}
