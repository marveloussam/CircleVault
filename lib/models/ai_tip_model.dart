import 'package:cloud_firestore/cloud_firestore.dart';

class AiTipModel {
  final String id;
  final String uid;
  final String tipText;
  final String category; // 'savings' | 'debt' | 'investment' | 'general'
  final DateTime generatedAt;
  final bool wasDismissed;

  const AiTipModel({
    required this.id,
    required this.uid,
    required this.tipText,
    this.category = 'general',
    required this.generatedAt,
    this.wasDismissed = false,
  });

  factory AiTipModel.fromMap(Map<String, dynamic> map, String id) {
    return AiTipModel(
      id: id,
      uid: map['uid'] as String? ?? '',
      tipText: map['tipText'] as String? ?? '',
      category: map['category'] as String? ?? 'general',
      generatedAt: (map['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      wasDismissed: map['wasDismissed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'tipText': tipText,
      'category': category,
      'generatedAt': Timestamp.fromDate(generatedAt),
      'wasDismissed': wasDismissed,
    };
  }

  AiTipModel copyWith({
    String? id,
    String? uid,
    String? tipText,
    String? category,
    DateTime? generatedAt,
    bool? wasDismissed,
  }) {
    return AiTipModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      tipText: tipText ?? this.tipText,
      category: category ?? this.category,
      generatedAt: generatedAt ?? this.generatedAt,
      wasDismissed: wasDismissed ?? this.wasDismissed,
    );
  }

  @override
  String toString() =>
      'AiTipModel(id: $id, category: $category, dismissed: $wasDismissed)';
}
