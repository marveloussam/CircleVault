enum TransactionType {
  contribution,
  payout,
  refund,
  fee;

  String toValue() {
    switch (this) {
      case TransactionType.contribution:
        return 'contribution';
      case TransactionType.payout:
        return 'payout';
      case TransactionType.refund:
        return 'refund';
      case TransactionType.fee:
        return 'fee';
    }
  }

  static TransactionType fromValue(String value) {
    switch (value) {
      case 'contribution':
        return TransactionType.contribution;
      case 'payout':
        return TransactionType.payout;
      case 'refund':
        return TransactionType.refund;
      case 'fee':
        return TransactionType.fee;
      default:
        throw ArgumentError('Unknown TransactionType value: $value');
    }
  }

  String get displayLabel {
    switch (this) {
      case TransactionType.contribution:
        return 'CONTRIBUTION';
      case TransactionType.payout:
        return 'PAYOUT';
      case TransactionType.refund:
        return 'REFUND';
      case TransactionType.fee:
        return 'FEE';
    }
  }
}
