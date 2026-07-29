/// Family roles for nest members (stored on NestMember.role).
abstract final class MemberRoles {
  static const adult = 'Adult';
  static const coParent = 'Co-parent';
  static const kid = 'Kid';
  static const grandparent = 'Grandparent';
  static const member = 'Member';

  static const all = <String>[
    adult,
    coParent,
    kid,
    grandparent,
    member,
  ];

  static String normalize(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return member;
    for (final role in all) {
      if (role.toLowerCase() == value.toLowerCase()) return role;
    }
    // Legacy / auth defaults
    if (value.toLowerCase() == 'adult') return adult;
    return member;
  }

  static bool isKid(String role) => normalize(role) == kid;

  /// Suitable for chores, expenses, pickups (not young kids by default).
  static bool isAdultLike(String role) {
    final r = normalize(role);
    return r == adult || r == coParent || r == grandparent || r == member;
  }

  /// Sort key: kids first (for school/activity assignment).
  static int kidsFirst(String a, String b) {
    final ak = isKid(a) ? 0 : 1;
    final bk = isKid(b) ? 0 : 1;
    return ak.compareTo(bk);
  }

  /// Sort key: adult-like first (for chores, bills, scan assignees).
  static int adultLikeFirst(String a, String b) {
    final aa = isAdultLike(a) ? 0 : 1;
    final ba = isAdultLike(b) ? 0 : 1;
    return aa.compareTo(ba);
  }
}
