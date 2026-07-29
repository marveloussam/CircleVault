enum CircleStatus {
  pending,
  active,
  completed,
  paused;

  String toValue() {
    switch (this) {
      case CircleStatus.pending:
        return 'pending';
      case CircleStatus.active:
        return 'active';
      case CircleStatus.completed:
        return 'completed';
      case CircleStatus.paused:
        return 'paused';
    }
  }

  static CircleStatus fromValue(String value) {
    switch (value) {
      case 'pending':
        return CircleStatus.pending;
      case 'active':
        return CircleStatus.active;
      case 'completed':
        return CircleStatus.completed;
      case 'paused':
        return CircleStatus.paused;
      default:
        throw ArgumentError('Unknown CircleStatus value: $value');
    }
  }

  String get displayLabel {
    switch (this) {
      case CircleStatus.pending:
        return 'PENDING';
      case CircleStatus.active:
        return 'ACTIVE';
      case CircleStatus.completed:
        return 'COMPLETED';
      case CircleStatus.paused:
        return 'PAUSED';
    }
  }
}
