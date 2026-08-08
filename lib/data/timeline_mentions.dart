import 'db/app_database.dart';

/// Parses `@Name` tokens in [body] against nest [members] (name, first name, id).
List<String> parseTimelineMentions(
  String body,
  Iterable<NestMember> members,
) {
  final mentions = <String>{};
  final pattern = RegExp(r'@(\w+)');
  for (final match in pattern.allMatches(body)) {
    final token = match.group(1)!.toLowerCase();
    for (final member in members) {
      final name = member.name.trim();
      if (name.isEmpty) continue;
      final first = name.split(RegExp(r'\s+')).first.toLowerCase();
      if (name.toLowerCase() == token ||
          first == token ||
          member.id.toLowerCase() == token) {
        mentions.add(member.id);
      }
    }
  }
  return mentions.toList();
}

String? encodeMentionIds(List<String> ids) {
  if (ids.isEmpty) return null;
  return ids.join(',');
}

List<String> decodeMentionIds(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  return raw
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}
