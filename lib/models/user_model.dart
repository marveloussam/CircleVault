import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final DateTime createdAt;
  final bool isVerified;
  final bool hasLinkedCard;
  final bool canReceivePayouts;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.createdAt,
    required this.isVerified,
    this.hasLinkedCard = false,
    this.canReceivePayouts = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerified: map['isVerified'] as bool? ?? false,
      hasLinkedCard: map['hasLinkedCard'] as bool? ?? false,
      canReceivePayouts: map['canReceivePayouts'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'isVerified': isVerified,
      'hasLinkedCard': hasLinkedCard,
      'canReceivePayouts': canReceivePayouts,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    DateTime? createdAt,
    bool? isVerified,
    bool? hasLinkedCard,
    bool? canReceivePayouts,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
      hasLinkedCard: hasLinkedCard ?? this.hasLinkedCard,
      canReceivePayouts: canReceivePayouts ?? this.canReceivePayouts,
    );
  }

  bool get isEmailVerified => isVerified;

  @override
  String toString() => 'UserModel(uid: $uid, name: $name, email: $email, '
      'verified: $isVerified, hasCard: $hasLinkedCard, '
      'canReceivePayouts: $canReceivePayouts)';
}

