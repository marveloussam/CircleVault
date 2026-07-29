abstract class FirestorePaths {
  static String usersCollection() => 'users';

  static String userDoc(String uid) => 'users/$uid';

  static String circlesCollection() => 'circles';

  static String circleDoc(String cid) => 'circles/$cid';

  static String membersCollection(String cid) => 'circles/$cid/members';

  static String memberDoc(String cid, String uid) => 'circles/$cid/members/$uid';

  static String transactionsCollection(String cid) => 'circles/$cid/transactions';

  static String rotationSlotsCollection(String cid) => 'circles/$cid/rotationSlots';

  static String rotationSlotDoc(String cid, int roundNumber) =>
      'circles/$cid/rotationSlots/$roundNumber';

  static String aiTipsCollection() => 'aiTips';

  static String aiTipDoc(String tipId) => 'aiTips/$tipId';
}
