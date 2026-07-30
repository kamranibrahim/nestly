/// Normalize pasted invite codes: strip spaces/dashes, keep A–Z0–9, uppercase.
String normalizeInviteCode(String raw) {
  final cleaned = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  return cleaned.length <= 6 ? cleaned : cleaned.substring(0, 6);
}
