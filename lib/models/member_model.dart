import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/enums/member_status.dart';

class MemberModel {
  final String uid;
  final String circleId;
  final int rotationPosition; // 1-based
  final bool hasReceivedPayout;
  final MemberStatus status;
  final int totalContributed; // in kobo
  final DateTime joinedAt;

  const MemberModel({
    required this.uid,
    required this.circleId,
    required this.rotationPosition,
    this.hasReceivedPayout = false,
    this.status = MemberStatus.invited,
    this.totalContributed = 0,
    required this.joinedAt,
  });

  factory MemberModel.fromMap(Map<String, dynamic> map, String id) {
    return MemberModel(
      uid: id,
      circleId: map['circleId'] as String? ?? '',
      rotationPosition: map['rotationPosition'] as int? ?? 0,
      hasReceivedPayout: map['hasReceivedPayout'] as bool? ?? false,
      status: MemberStatus.fromValue(map['status'] as String? ?? 'invited'),
      totalContributed: map['totalContributed'] as int? ?? 0,
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'circleId': circleId,
      'rotationPosition': rotationPosition,
      'hasReceivedPayout': hasReceivedPayout,
      'status': status.toValue(),
      'totalContributed': totalContributed,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  MemberModel copyWith({
    String? uid,
    String? circleId,
    int? rotationPosition,
    bool? hasReceivedPayout,
    MemberStatus? status,
    int? totalContributed,
    DateTime? joinedAt,
  }) {
    return MemberModel(
      uid: uid ?? this.uid,
      circleId: circleId ?? this.circleId,
      rotationPosition: rotationPosition ?? this.rotationPosition,
      hasReceivedPayout: hasReceivedPayout ?? this.hasReceivedPayout,
      status: status ?? this.status,
      totalContributed: totalContributed ?? this.totalContributed,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  String toString() =>
      'MemberModel(uid: $uid, circle: $circleId, pos: $rotationPosition, status: ${status.toValue()})';
}
