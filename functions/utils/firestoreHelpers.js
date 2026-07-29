/**
 * Firestore path helpers mirroring lib/core/constants/firestore_paths.dart
 * Used exclusively inside Cloud Functions.
 */

const userDoc = (uid) => `users/${uid}`;
const circleDoc = (cid) => `circles/${cid}`;
const membersCollection = (cid) => `circles/${cid}/members`;
const memberDoc = (cid, uid) => `circles/${cid}/members/${uid}`;
const transactionsCollection = (cid) => `circles/${cid}/transactions`;
const rotationSlotDoc = (cid, round) => `circles/${cid}/rotationSlots/${round}`;

module.exports = {
  userDoc,
  circleDoc,
  membersCollection,
  memberDoc,
  transactionsCollection,
  rotationSlotDoc,
};
