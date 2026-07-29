enum MemberStatus {
  invited,
  active,
  defaulted,
  removed;

  String toValue() {
    switch (this) {
      case MemberStatus.invited:
        return 'invited';
      case MemberStatus.active:
        return 'active';
      case MemberStatus.defaulted:
        return 'defaulted';
      case MemberStatus.removed:
        return 'removed';
    }
  }

  static MemberStatus fromValue(String value) {
    switch (value) {
      case 'invited':
        return MemberStatus.invited;
      case 'active':
        return MemberStatus.active;
      case 'defaulted':
        return MemberStatus.defaulted;
      case 'removed':
        return MemberStatus.removed;
      default:
        throw ArgumentError('Unknown MemberStatus value: $value');
    }
  }
}
