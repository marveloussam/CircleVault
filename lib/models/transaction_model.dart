import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/enums/transaction_type.dart';

class TransactionModel {
  final String id;
  final String circleId;
  final String memberUid;
  final TransactionType type;
  final int amountKobo;
  final String reference; // Paystack reference
  final DateTime timestamp;
  final int roundNumber;
  final String? notes;

  const TransactionModel({
    required this.id,
    required this.circleId,
    required this.memberUid,
    required this.type,
    required this.amountKobo,
    required this.reference,
    required this.timestamp,
    required this.roundNumber,
    this.notes,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      circleId: map['circleId'] as String? ?? '',
      memberUid: map['memberUid'] as String? ?? '',
      type: TransactionType.fromValue(map['type'] as String? ?? 'contribution'),
      amountKobo: map['amountKobo'] as int? ?? 0,
      reference: map['reference'] as String? ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      roundNumber: map['roundNumber'] as int? ?? 1,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'circleId': circleId,
      'memberUid': memberUid,
      'type': type.toValue(),
      'amountKobo': amountKobo,
      'reference': reference,
      'timestamp': Timestamp.fromDate(timestamp),
      'roundNumber': roundNumber,
      'notes': notes,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? circleId,
    String? memberUid,
    TransactionType? type,
    int? amountKobo,
    String? reference,
    DateTime? timestamp,
    int? roundNumber,
    String? notes,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      circleId: circleId ?? this.circleId,
      memberUid: memberUid ?? this.memberUid,
      type: type ?? this.type,
      amountKobo: amountKobo ?? this.amountKobo,
      reference: reference ?? this.reference,
      timestamp: timestamp ?? this.timestamp,
      roundNumber: roundNumber ?? this.roundNumber,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() =>
      'TransactionModel(id: $id, type: ${type.toValue()}, amount: $amountKobo kobo, round: $roundNumber)';
}
