import 'package:cloud_firestore/cloud_firestore.dart';

class RotationSlotModel {
  final String circleId;
  final int roundNumber;
  final String recipientUid;
  final bool disbursed;
  final DateTime? disbursedAt;
  final String? paystackTransferCode;

  const RotationSlotModel({
    required this.circleId,
    required this.roundNumber,
    required this.recipientUid,
    this.disbursed = false,
    this.disbursedAt,
    this.paystackTransferCode,
  });

  factory RotationSlotModel.fromMap(Map<String, dynamic> map) {
    return RotationSlotModel(
      circleId: map['circleId'] as String? ?? '',
      roundNumber: map['roundNumber'] as int? ?? 0,
      recipientUid: map['recipientUid'] as String? ?? '',
      disbursed: map['disbursed'] as bool? ?? false,
      disbursedAt: (map['disbursedAt'] as Timestamp?)?.toDate(),
      paystackTransferCode: map['paystackTransferCode'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'circleId': circleId,
      'roundNumber': roundNumber,
      'recipientUid': recipientUid,
      'disbursed': disbursed,
      'disbursedAt': disbursedAt != null ? Timestamp.fromDate(disbursedAt!) : null,
      'paystackTransferCode': paystackTransferCode,
    };
  }

  RotationSlotModel copyWith({
    String? circleId,
    int? roundNumber,
    String? recipientUid,
    bool? disbursed,
    DateTime? disbursedAt,
    String? paystackTransferCode,
  }) {
    return RotationSlotModel(
      circleId: circleId ?? this.circleId,
      roundNumber: roundNumber ?? this.roundNumber,
      recipientUid: recipientUid ?? this.recipientUid,
      disbursed: disbursed ?? this.disbursed,
      disbursedAt: disbursedAt ?? this.disbursedAt,
      paystackTransferCode: paystackTransferCode ?? this.paystackTransferCode,
    );
  }

  @override
  String toString() =>
      'RotationSlotModel(circle: $circleId, round: $roundNumber, recipient: $recipientUid, disbursed: $disbursed)';
}
