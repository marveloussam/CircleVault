import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email; // Changed from phoneNumber to email

  // Paystack fields remain the same
  final String? paystackCustomerCode;
  final String? paystackAuthorizationCode;
  final String? paystackTransferRecipientCode;
  final String? paystackCardLast4;
  final String? paystackCardBank;
  final String? paystackCardSignature;

  final DateTime createdAt;
  final bool isVerified; // Tracks email verification status

  const UserModel({
    required this.uid,
    required this.name,
    required this.email, // Changed from phoneNumber
    this.paystackCustomerCode,
    this.paystackAuthorizationCode,
    this.paystackTransferRecipientCode,
    this.paystackCardLast4,
    this.paystackCardBank,
    this.paystackCardSignature,
    required this.createdAt,
    required this.isVerified,
  });

  factory UserModel.fromMap(
      Map<String, dynamic> map,
      String id,
      ) {
    return UserModel(
      uid: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '', // Changed from phoneNumber

      paystackCustomerCode: map['paystackCustomerCode'] as String?,
      paystackAuthorizationCode: map['paystackAuthorizationCode'] as String?,
      paystackTransferRecipientCode: map['paystackTransferRecipientCode'] as String?,
      paystackCardLast4: map['paystackCardLast4'] as String?,
      paystackCardBank: map['paystackCardBank'] as String?,
      paystackCardSignature: map['paystackCardSignature'] as String?,

      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerified: map['isVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email, // Changed from phoneNumber

      'paystackCustomerCode': paystackCustomerCode,
      'paystackAuthorizationCode': paystackAuthorizationCode,
      'paystackTransferRecipientCode': paystackTransferRecipientCode,
      'paystackCardLast4': paystackCardLast4,
      'paystackCardBank': paystackCardBank,
      'paystackCardSignature': paystackCardSignature,

      'createdAt': Timestamp.fromDate(createdAt),
      'isVerified': isVerified,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email, // Changed from phoneNumber
    String? paystackCustomerCode,
    String? paystackAuthorizationCode,
    String? paystackTransferRecipientCode,
    String? paystackCardLast4,
    String? paystackCardBank,
    String? paystackCardSignature,
    DateTime? createdAt,
    bool? isVerified,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email, // Changed from phoneNumber

      paystackCustomerCode: paystackCustomerCode ?? this.paystackCustomerCode,
      paystackAuthorizationCode: paystackAuthorizationCode ?? this.paystackAuthorizationCode,
      paystackTransferRecipientCode: paystackTransferRecipientCode ?? this.paystackTransferRecipientCode,
      paystackCardLast4: paystackCardLast4 ?? this.paystackCardLast4,
      paystackCardBank: paystackCardBank ?? this.paystackCardBank,
      paystackCardSignature: paystackCardSignature ?? this.paystackCardSignature,

      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  bool get hasLinkedCard =>
      paystackAuthorizationCode != null &&
          paystackAuthorizationCode!.isNotEmpty;

  bool get canReceivePayouts =>
      paystackTransferRecipientCode != null &&
          paystackTransferRecipientCode!.isNotEmpty;

  bool get isEmailVerified => isVerified; // Alias for clarity

  @override
  String toString() {
    return '''
UserModel(
  uid: $uid,
  name: $name,
  email: $email,
  verified: $isVerified,
  hasCard: $hasLinkedCard,
  canReceivePayouts: $canReceivePayouts
)
''';
  }
}