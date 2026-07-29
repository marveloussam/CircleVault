import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/enums/circle_status.dart';

class CircleModel {
  final String id;
  final String name;
  final String adminUid;
  final int contributionAmount; // in kobo
  final String currency;
  final int totalMembers;
  final int currentRound; // 1-based
  final CircleStatus status;
  final String frequency; // 'weekly' | 'biweekly' | 'monthly'
  final DateTime nextContributionDate;
  final DateTime createdAt;
  final List<String> memberUids; // ordered — index = rotation slot

  const CircleModel({
    required this.id,
    required this.name,
    required this.adminUid,
    required this.contributionAmount,
    this.currency = 'NGN',
    required this.totalMembers,
    this.currentRound = 1,
    this.status = CircleStatus.pending,
    required this.frequency,
    required this.nextContributionDate,
    required this.createdAt,
    this.memberUids = const [],
  });

  factory CircleModel.fromMap(Map<String, dynamic> map, String id) {
    return CircleModel(
      id: id,
      name: map['name'] as String? ?? '',
      adminUid: map['adminUid'] as String? ?? '',
      contributionAmount: map['contributionAmount'] as int? ?? 0,
      currency: map['currency'] as String? ?? 'NGN',
      totalMembers: map['totalMembers'] as int? ?? 0,
      currentRound: map['currentRound'] as int? ?? 1,
      status: CircleStatus.fromValue(map['status'] as String? ?? 'pending'),
      frequency: map['frequency'] as String? ?? 'monthly',
      nextContributionDate:
          (map['nextContributionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      memberUids: List<String>.from(map['memberUids'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'adminUid': adminUid,
      'contributionAmount': contributionAmount,
      'currency': currency,
      'totalMembers': totalMembers,
      'currentRound': currentRound,
      'status': status.toValue(),
      'frequency': frequency,
      'nextContributionDate': Timestamp.fromDate(nextContributionDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'memberUids': memberUids,
    };
  }

  CircleModel copyWith({
    String? id,
    String? name,
    String? adminUid,
    int? contributionAmount,
    String? currency,
    int? totalMembers,
    int? currentRound,
    CircleStatus? status,
    String? frequency,
    DateTime? nextContributionDate,
    DateTime? createdAt,
    List<String>? memberUids,
  }) {
    return CircleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      adminUid: adminUid ?? this.adminUid,
      contributionAmount: contributionAmount ?? this.contributionAmount,
      currency: currency ?? this.currency,
      totalMembers: totalMembers ?? this.totalMembers,
      currentRound: currentRound ?? this.currentRound,
      status: status ?? this.status,
      frequency: frequency ?? this.frequency,
      nextContributionDate: nextContributionDate ?? this.nextContributionDate,
      createdAt: createdAt ?? this.createdAt,
      memberUids: memberUids ?? this.memberUids,
    );
  }

  /// Whether the circle is full (all slots taken).
  bool get isFull => memberUids.length >= totalMembers;

  /// Returns the uid that should receive payout for a given round (1-based).
  String? recipientForRound(int round) {
    final index = round - 1;
    if (index < 0 || index >= memberUids.length) return null;
    return memberUids[index];
  }

  @override
  String toString() =>
      'CircleModel(id: $id, name: $name, status: ${status.toValue()}, round: $currentRound/$totalMembers)';
}
