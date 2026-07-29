import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../core/errors/app_exception.dart';
import '../core/enums/transaction_type.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  TransactionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ─── Real-time stream (shared ledger) ─────────────────────────────────────────

  /// Emits all transactions for [circleId] ordered newest-first.
  /// Every member of the circle subscribes to this same stream — shared ledger.
  Stream<List<TransactionModel>> transactionsStream(String circleId) {
    return _firestore
        .collection(FirestorePaths.transactionsCollection(circleId))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ─── Recent transactions for a user across all their circles ─────────────────

  /// Returns the most recent [limit] transactions for [uid] across all circles
  /// by querying a flat collectionGroup index on 'transactions'.
  /// Requires the Firestore index defined in firestore.indexes.json.
  Future<List<TransactionModel>> recentUserTransactions(
    String uid, {
    int limit = 10,
  }) async {
    try {
      final snap = await _firestore
          .collectionGroup('transactions')
          .where('memberUid', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snap.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      throw CircleException(
        'Failed to load recent transactions: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw CircleException('Unexpected error loading transactions: $e');
    }
  }

  // ─── Write transaction (client-side for dev/testing only) ─────────────────────

  /// In production this is called exclusively from Cloud Functions.
  /// Client-side writes are blocked by Firestore security rules in production.
  /// Exposed here for local development / emulator testing.
  Future<void> writeTransaction(TransactionModel tx) async {
    try {
      final docRef = _firestore
          .collection(FirestorePaths.transactionsCollection(tx.circleId))
          .doc(tx.id);
      await docRef.set(tx.toMap());
    } on FirebaseException catch (e) {
      throw CircleException(
        'Failed to write transaction: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw CircleException('Unexpected error writing transaction: $e');
    }
  }

  // ─── Round contribution count ─────────────────────────────────────────────────

  /// Returns how many contribution transactions exist for [circleId] in [round].
  /// Used by the disbursement check logic.
  Future<int> countContributionsForRound(String circleId, int round) async {
    try {
      final snap = await _firestore
          .collection(FirestorePaths.transactionsCollection(circleId))
          .where('type', isEqualTo: TransactionType.contribution.toValue())
          .where('roundNumber', isEqualTo: round)
          .count()
          .get();
      return snap.count ?? 0;
    } on FirebaseException catch (e) {
      throw CircleException(
        'Failed to count contributions: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw CircleException('Unexpected error counting contributions: $e');
    }
  }

  // ─── Contributions by circle for a specific member ────────────────────────────

  /// Returns all contribution transactions for [uid] inside [circleId].
  Future<List<TransactionModel>> memberContributions(
    String circleId,
    String uid,
  ) async {
    try {
      final snap = await _firestore
          .collection(FirestorePaths.transactionsCollection(circleId))
          .where('memberUid', isEqualTo: uid)
          .where('type', isEqualTo: TransactionType.contribution.toValue())
          .orderBy('timestamp', descending: true)
          .get();

      return snap.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      throw CircleException(
        'Failed to load member contributions: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw CircleException('Unexpected error loading member contributions: $e');
    }
  }
}
