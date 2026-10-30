'use strict';

const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { logger } = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');
const { v4: uuidv4 } = require('uuid');
const paystack = require('./utils/paystack');
const state = require('./utils/paymentState');
const paths = require('./utils/firestoreHelpers');

admin.initializeApp();
const db = admin.firestore();
const PAYSTACK_SECRET_KEY = defineSecret('PAYSTACK_SECRET_KEY');
const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');

const privatePaymentPath = (uid) => 'users/' + uid + '/private/payment';
const paymentSetupPath = (uid, reference) => 'users/' + uid + '/paymentSetups/' + reference;
const contributionAttemptPath = (circleId, round, uid) =>
  'circles/' + circleId + '/paymentAttempts/r' + round + '_' +
  state.stableReference('member', [uid]).slice(-16);
const contributionTransactionId = (round, uid) =>
  'contribution_r' + round + '_' + state.stableReference('member', [uid]).slice(-16);
const payoutTransactionId = (round) => 'payout_r' + round;

function requireAuth(request) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in is required.');
  return request.auth.uid;
}

function requireString(value, field, maxLength) {
  if (typeof value !== 'string' || value.trim().length === 0 || value.length > maxLength) {
    throw new HttpsError('invalid-argument', field + ' is invalid.');
  }
  return value.trim();
}

function timestampMillis(value) {
  return value && typeof value.toMillis === 'function' ? value.toMillis() : 0;
}

async function createCircleCallable(request) {
  const uid = requireAuth(request);
  const data = request.data || {};
  const name = requireString(data.name, 'name', 80);
  const amountKobo = Number(data.amountKobo);
  const totalMembers = Number(data.totalMembers);
  const frequency = data.frequency;
  if (name.length < 2 || !Number.isSafeInteger(amountKobo) || amountKobo < 1 ||
      amountKobo > 1000000000 || !Number.isSafeInteger(totalMembers) ||
      totalMembers < 2 || totalMembers > 30 ||
      !['weekly', 'biweekly', 'monthly'].includes(frequency)) {
    throw new HttpsError('invalid-argument', 'Circle configuration is invalid.');
  }
  const circleId = uuidv4();
  const now = admin.firestore.Timestamp.now();
  const batch = db.batch();
  batch.create(db.doc(paths.circleDoc(circleId)), {
    name, adminUid: uid, contributionAmount: amountKobo, currency: 'NGN',
    totalMembers, currentRound: 1, status: 'pending', frequency,
    nextContributionDate: now, createdAt: now, memberUids: [uid],
  });
  batch.create(db.doc(paths.memberDoc(circleId, uid)), {
    circleId, rotationPosition: 1, hasReceivedPayout: false,
    status: 'invited', totalContributed: 0, joinedAt: now,
  });
  batch.create(db.doc(paths.rotationSlotDoc(circleId, 1)), {
    circleId, roundNumber: 1, recipientUid: uid, disbursed: false,
    payoutStatus: 'not_started',
  });
  await batch.commit();
  return { circleId };
}
exports.createCircle = onCall({ region: 'us-central1' }, createCircleCallable);

exports.addCircleMember = onCall({ region: 'us-central1' }, async (request) => {
  const callerUid = requireAuth(request);
  const circleId = requireString(request.data && request.data.circleId, 'circleId', 140);
  const uid = requireString(request.data && request.data.uid, 'uid', 140);
  const circleRef = db.doc(paths.circleDoc(circleId));
  const memberRef = db.doc(paths.memberDoc(circleId, uid));
  const userRef = db.doc(paths.userDoc(uid));
  await db.runTransaction(async (tx) => {
    const [circleSnap, memberSnap, userSnap] = await Promise.all([tx.get(circleRef), tx.get(memberRef), tx.get(userRef)]);
    if (!circleSnap.exists) throw new HttpsError('not-found', 'Circle not found.');
    const circle = circleSnap.data();
    if (circle.adminUid !== callerUid) throw new HttpsError('permission-denied', 'Only the circle admin can add members.');
    if (circle.status !== 'pending') throw new HttpsError('failed-precondition', 'Members can only be added before the circle starts.');
    if (!userSnap.exists) throw new HttpsError('not-found', 'CircleVault account not found.');
    const memberUids = Array.isArray(circle.memberUids) ? circle.memberUids : [];
    if (memberSnap.exists || memberUids.includes(uid)) throw new HttpsError('already-exists', 'User is already a circle member.');
    if (memberUids.length >= Number(circle.totalMembers)) throw new HttpsError('failed-precondition', 'Circle is full.');
    const position = memberUids.length + 1;
    const slotRef = db.doc(paths.rotationSlotDoc(circleId, position));
    const slotSnap = await tx.get(slotRef);
    if (slotSnap.exists) throw new HttpsError('already-exists', 'Rotation position is already assigned.');
    tx.create(memberRef, {
      circleId, rotationPosition: position, hasReceivedPayout: false,
      status: 'invited', totalContributed: 0,
      joinedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.create(slotRef, { circleId, roundNumber: position, recipientUid: uid, disbursed: false, payoutStatus: 'not_started' });
    tx.update(circleRef, { memberUids: memberUids.concat([uid]) });
  });
  return { success: true };
});

exports.startCircle = onCall({ region: 'us-central1' }, async (request) => {
  const callerUid = requireAuth(request);
  const circleId = requireString(request.data && request.data.circleId, 'circleId', 140);
  const circleRef = db.doc(paths.circleDoc(circleId));
  const membersRef = db.collection(paths.membersCollection(circleId));
  const slotsRef = db.collection(paths.rotationSlotsCollection(circleId));
  await db.runTransaction(async (tx) => {
    const circleSnap = await tx.get(circleRef);
    if (!circleSnap.exists) throw new HttpsError('not-found', 'Circle not found.');
    const circle = circleSnap.data();
    if (circle.adminUid !== callerUid) throw new HttpsError('permission-denied', 'Only the circle admin can start it.');
    if (circle.status !== 'pending') throw new HttpsError('failed-precondition', 'Circle is not pending.');
    const [membersSnap, slotsSnap] = await Promise.all([tx.get(membersRef), tx.get(slotsRef)]);
    const members = membersSnap.docs;
    if (members.length !== Number(circle.totalMembers) || circle.memberUids.length !== Number(circle.totalMembers) || slotsSnap.size !== Number(circle.totalMembers)) {
      throw new HttpsError('failed-precondition', 'The circle must be full before it starts.');
    }
    const slotsByPosition = new Map(slotsSnap.docs.map((doc) => [Number(doc.id), doc.data()]));
    for (const memberDoc of members) {
      const slot = slotsByPosition.get(Number(memberDoc.data().rotationPosition));
      if (!slot || slot.recipientUid !== memberDoc.id) throw new HttpsError('failed-precondition', 'Circle rotation order is incomplete.');
      tx.update(memberDoc.ref, { status: 'active' });
    }
    tx.update(circleRef, { status: 'active', nextContributionDate: admin.firestore.Timestamp.now() });
  });
  return { success: true };
});

exports.updateCircleStatus = onCall({ region: 'us-central1' }, async (request) => {
  const callerUid = requireAuth(request);
  const circleId = requireString(request.data && request.data.circleId, 'circleId', 140);
  const status = request.data && request.data.status;
  if (!['active', 'paused'].includes(status)) throw new HttpsError('invalid-argument', 'Only pause and resume are supported.');
  const circleRef = db.doc(paths.circleDoc(circleId));
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(circleRef);
    if (!snap.exists) throw new HttpsError('not-found', 'Circle not found.');
    const circle = snap.data();
    if (circle.adminUid !== callerUid) throw new HttpsError('permission-denied', 'Only the circle admin can change this status.');
    if ((status === 'paused' && circle.status !== 'active') || (status === 'active' && circle.status !== 'paused')) {
      throw new HttpsError('failed-precondition', 'Invalid circle status transition.');
    }
    tx.update(circleRef, { status });
  });
  return { success: true };
});

async function setAttemptState(attemptRef, status, extra) {
  await attemptRef.set({
    status,
    leaseUntilMillis: 0,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    ...(extra || {}),
  }, { merge: true });
}

async function finalizeContribution(circleId, round, memberUid, attemptRef, transaction) {
  const amountKobo = Number(transaction.amount);
  const txRef = db.doc(paths.transactionsCollection(circleId) + '/' +
    contributionTransactionId(round, memberUid));
  const memberRef = db.doc(paths.memberDoc(circleId, memberUid));

  return db.runTransaction(async (tx) => {
    const [attemptSnap, txSnap, memberSnap] = await Promise.all([
      tx.get(attemptRef), tx.get(txRef), tx.get(memberRef),
    ]);
    if (!memberSnap.exists) throw new Error('Contribution member record is missing.');
    if (!txSnap.exists) {
      tx.create(txRef, {
        circleId,
        memberUid,
        type: 'contribution',
        status: 'succeeded',
        amountKobo,
        reference: transaction.reference,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        roundNumber: round,
        notes: 'Automated contribution - Round ' + round,
      });
      tx.update(memberRef, {
        totalContributed: admin.firestore.FieldValue.increment(amountKobo),
      });
    }
    if (!attemptSnap.exists || attemptSnap.data().reference !== transaction.reference) {
      throw new Error('Contribution attempt reference does not match.');
    }
    tx.set(attemptRef, {
      status: 'succeeded',
      leaseUntilMillis: 0,
      verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return !txSnap.exists;
  });
}

async function reconcileContribution(circleId, round, memberUid, attemptRef, attempt) {
  try {
    const verified = await paystack.verifyTransaction(attempt.reference, PAYSTACK_SECRET_KEY.value());
    const classification = state.classifyChargeStatus(verified);
    if (classification === 'succeeded' && state.isVerifiedContribution(verified, {
      reference: attempt.reference,
      amountKobo: attempt.amountKobo,
    })) {
      await finalizeContribution(circleId, round, memberUid, attemptRef, verified);
      return true;
    }
    await setAttemptState(attemptRef, classification === 'failed' ? 'failed' :
      classification === 'pending' ? 'pending' : 'unknown');
    return false;
  } catch (error) {
    logger.warn('[contributions] Verification unresolved; preserving attempt for reconciliation.', {
      circleId, round, memberUid, code: error && error.code,
    });
    await setAttemptState(attemptRef, 'unknown');
    return false;
  }
}

async function processMemberContribution(circleId, circle, memberDoc) {
  const uid = memberDoc.id;
  const round = Number(circle.currentRound);
  const amountKobo = Number(circle.contributionAmount);
  const attemptRef = db.doc(contributionAttemptPath(circleId, round, uid));

  if (!Number.isSafeInteger(round) || round < 1 ||
      !Number.isSafeInteger(amountKobo) || amountKobo <= 0) {
    logger.error('[contributions] Invalid round or contribution amount.', { circleId, round });
    return false;
  }

  const [userSnap, paymentSnap] = await Promise.all([
    db.doc(paths.userDoc(uid)).get(),
    db.doc(privatePaymentPath(uid)).get(),
  ]);
  if (!userSnap.exists || !paymentSnap.exists || !paymentSnap.data().authorizationCode) {
    logger.warn('[contributions] Member has no server-side payment method.', { circleId, round, memberUid: uid });
    return false;
  }

  const user = userSnap.data();
  const payment = paymentSnap.data();
  const email = user.email;
  if (typeof email !== 'string' || !email.includes('@')) {
    logger.warn('[contributions] Member email is unavailable.', { circleId, round, memberUid: uid });
    return false;
  }

  const now = Date.now();
  const claim = await db.runTransaction(async (tx) => {
    const snap = await tx.get(attemptRef);
    const attempt = snap.exists ? snap.data() : null;
    const decision = state.contributionAction(attempt, now);
    if (decision.action !== 'charge') return { ...decision, attempt };

    const reference = state.stableReference('cv_contrib', [
      circleId, round, uid, decision.attemptNumber,
    ]);
    const nextAttempt = {
      circleId,
      roundNumber: round,
      memberUid: uid,
      amountKobo,
      attemptNumber: decision.attemptNumber,
      reference,
      status: 'processing',
      leaseUntilMillis: now + 120000,
      startedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    tx.set(attemptRef, nextAttempt);
    return { action: 'charge', attempt: nextAttempt };
  });

  if (claim.action === 'skip') return claim.attempt && claim.attempt.status === 'succeeded';
  if (claim.action === 'review') return false;
  if (claim.action === 'reconcile') {
    return reconcileContribution(circleId, round, uid, attemptRef, claim.attempt);
  }

  const attempt = claim.attempt;
  try {
    await paystack.chargeAuthorization(
      payment.authorizationCode, email, amountKobo, attempt.reference,
      PAYSTACK_SECRET_KEY.value()
    );
  } catch (error) {
    await setAttemptState(attemptRef, error && error.outcomeUnknown === false ? 'failed' : 'unknown', {
      errorCode: error && error.code ? String(error.code).slice(0, 80) : null,
    });
    logger.warn('[contributions] Charge result requires reconciliation.', {
      circleId, round, memberUid: uid, outcomeUnknown: !error || error.outcomeUnknown !== false,
    });
    return false;
  }

  // The charge endpoint's accepted response is not proof of a successful payment.
  return reconcileContribution(circleId, round, uid, attemptRef, attempt);
}

async function _processCircleContributions(circleId, circle) {
  const membersSnap = await db.collection(paths.membersCollection(circleId))
    .where('status', '==', 'active').get();
  if (membersSnap.empty) return false;

  let allSucceeded = true;
  for (const memberDoc of membersSnap.docs) {
    try {
      const succeeded = await processMemberContribution(circleId, circle, memberDoc);
      if (!succeeded) allSucceeded = false;
    } catch (error) {
      logger.error('[contributions] Member contribution processing failed.', {
        circleId, round: circle.currentRound, memberUid: memberDoc.id,
        message: error && error.message,
      });
      allSucceeded = false;
    }
  }

  if (allSucceeded) await _processDisbursementInternal(circleId, Number(circle.currentRound));
  return allSucceeded;
}

exports.processContributions = onSchedule(
  {
    schedule: '0 8 * * *',
    timeZone: 'Africa/Lagos',
    region: 'us-central1',
    secrets: [PAYSTACK_SECRET_KEY],
  },
  async () => {
    logger.info('[processContributions] Starting scheduled contribution reconciliation.');
    const now = admin.firestore.Timestamp.now();
    const circlesSnap = await db.collection('circles')
      .where('status', '==', 'active')
      .where('nextContributionDate', '<=', now)
      .get();

    for (const circleDoc of circlesSnap.docs) {
      try {
        await _processCircleContributions(circleDoc.id, circleDoc.data());
      } catch (error) {
        logger.error('[processContributions] Circle processing failed.', {
          circleId: circleDoc.id, message: error && error.message,
        });
      }
    }
  }
);

async function finalizePayout(circleId, round, slotRef, transfer) {
  return db.runTransaction(async (tx) => {
    const circleRef = db.doc(paths.circleDoc(circleId));
    const slotSnap = await tx.get(slotRef);
    const circleSnap = await tx.get(circleRef);
    if (!slotSnap.exists || !circleSnap.exists) throw new Error('Payout records are missing.');
    const slot = slotSnap.data();
    const circle = circleSnap.data();
    if (slot.disbursed || slot.payoutStatus === 'succeeded') return false;
    if (slot.payoutReference !== transfer.reference ||
        Number(slot.payoutAmountKobo) !== Number(transfer.amount)) {
      throw new Error('Verified transfer does not match the payout record.');
    }
    const memberRef = db.doc(paths.memberDoc(circleId, slot.recipientUid));
    const txRef = db.doc(paths.transactionsCollection(circleId) + '/' + payoutTransactionId(round));
    const [memberSnap, payoutSnap] = await Promise.all([tx.get(memberRef), tx.get(txRef)]);
    if (!memberSnap.exists) throw new Error('Payout recipient is no longer a circle member.');

    tx.set(txRef, {
      circleId,
      memberUid: slot.recipientUid,
      type: 'payout',
      status: 'succeeded',
      amountKobo: Number(transfer.amount),
      reference: transfer.reference,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      roundNumber: round,
      notes: 'Automated ROSCA payout - Round ' + round,
    });
    tx.update(memberRef, { hasReceivedPayout: true });
    const nextRound = round + 1;
    const completed = nextRound > Number(circle.totalMembers);
    const nextDate = circle.nextContributionDate && circle.nextContributionDate.toDate
      ? circle.nextContributionDate.toDate()
      : new Date();
    if (!completed) {
      switch (circle.frequency) {
        case 'weekly': nextDate.setDate(nextDate.getDate() + 7); break;
        case 'biweekly': nextDate.setDate(nextDate.getDate() + 14); break;
        default: nextDate.setMonth(nextDate.getMonth() + 1);
      }
    }
    tx.update(slotRef, {
      disbursed: true,
      payoutStatus: 'succeeded',
      disbursedAt: admin.firestore.FieldValue.serverTimestamp(),
      paystackTransferCode: transfer.transfer_code || null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.update(circleRef, {
      currentRound: nextRound,
      status: completed ? 'completed' : 'active',
      ...(completed ? {} : { nextContributionDate: admin.firestore.Timestamp.fromDate(nextDate) }),
    });
    return !payoutSnap.exists;
  });
}

async function reconcilePayout(circleId, round, slotRef, slot) {
  try {
    const verified = await paystack.verifyTransfer(slot.payoutReference, PAYSTACK_SECRET_KEY.value());
    const status = String(verified.status || '').toLowerCase();
    if (status === 'success' &&
        Number(verified.amount) === Number(slot.payoutAmountKobo) &&
        verified.reference === slot.payoutReference) {
      await finalizePayout(circleId, round, slotRef, verified);
      return true;
    }
    if (['failed', 'reversed', 'abandoned'].includes(status)) {
      await slotRef.update({
        payoutStatus: status === 'failed' ? 'failed' : 'review',
        disbursed: false,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return false;
    }
    await slotRef.update({
      payoutStatus: 'pending',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return false;
  } catch (error) {
    logger.warn('[disbursement] Transfer status remains unresolved.', {
      circleId, round, code: error && error.code,
    });
    await slotRef.update({
      payoutStatus: 'unknown',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return false;
  }
}

async function _processDisbursementInternal(circleId, round) {
  const circleRef = db.doc(paths.circleDoc(circleId));
  const circleSnap = await circleRef.get();
  if (!circleSnap.exists) throw new Error('Circle does not exist.');
  const circle = circleSnap.data();

  const membersSnap = await db.collection(paths.membersCollection(circleId))
    .where('status', '==', 'active').get();
  if (!membersSnap.size || !Number.isSafeInteger(Number(circle.contributionAmount))) return false;

  const contributionDocs = await db.collection(paths.transactionsCollection(circleId))
    .where('type', '==', 'contribution')
    .where('roundNumber', '==', round)
    .where('status', '==', 'succeeded').get();
  const paidUids = new Set(contributionDocs.docs.map((doc) => doc.data().memberUid));
  if (membersSnap.docs.some((member) => !paidUids.has(member.id))) return false;

  const slotRef = db.doc(paths.rotationSlotDoc(circleId, round));
  const slotSnap = await slotRef.get();
  if (!slotSnap.exists) throw new Error('Rotation slot does not exist.');
  const slot = slotSnap.data();
  if (!membersSnap.docs.some((member) => member.id === slot.recipientUid)) {
    throw new Error('Rotation recipient is not an active circle member.');
  }
  const existingPayout = state.payoutAction(slot);
  if (existingPayout === 'skip' || existingPayout === 'review') return false;
  if (existingPayout === 'reconcile') return reconcilePayout(circleId, round, slotRef, slot);

  const paymentSnap = await db.doc(privatePaymentPath(slot.recipientUid)).get();
  const recipientCode = paymentSnap.exists && paymentSnap.data().transferRecipientCode;
  if (!recipientCode) {
    logger.warn('[disbursement] Recipient has no server-side transfer recipient.', { circleId, round });
    return false;
  }
  const amountKobo = Number(circle.contributionAmount) * membersSnap.size;
  if (!Number.isSafeInteger(amountKobo) || amountKobo <= 0) throw new Error('Invalid payout amount.');
  const attemptNumber = Number(slot.payoutAttemptNumber || 0) + 1;
  const reference = state.stableReference('cv_payout', [circleId, round, attemptNumber]);
  const claim = await db.runTransaction(async (tx) => {
    const latest = await tx.get(slotRef);
    const current = latest.data() || {};
    if (state.payoutAction(current) !== 'initiate' &&
        state.payoutAction(current) !== 'retry') return null;
    tx.update(slotRef, {
      payoutStatus: 'processing',
      payoutReference: reference,
      payoutAmountKobo: amountKobo,
      payoutAttemptNumber: attemptNumber,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return true;
  });
  if (!claim) return false;

  try {
    const initiated = await paystack.initiateTransfer(
      recipientCode, amountKobo, reference,
      'CircleVault ROSCA payout - ' + circle.name + ' round ' + round,
      PAYSTACK_SECRET_KEY.value()
    );
    await slotRef.update({
      payoutStatus: 'pending',
      paystackTransferCode: initiated.transfer_code || null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    await slotRef.update({
      payoutStatus: error && error.outcomeUnknown === false ? 'failed' : 'unknown',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    logger.warn('[disbursement] Transfer initiation requires reconciliation.', {
      circleId, round, outcomeUnknown: !error || error.outcomeUnknown !== false,
    });
  }
  return false;
}

// Only the scheduler can reach the disbursement function. There is intentionally
// no client-callable processDisbursement endpoint.
exports.processDisbursements = onSchedule(
  {
    schedule: 'every 15 minutes',
    timeZone: 'Africa/Lagos',
    region: 'us-central1',
    secrets: [PAYSTACK_SECRET_KEY],
  },
  async () => {
    const circlesSnap = await db.collection('circles').where('status', '==', 'active').get();
    for (const circleDoc of circlesSnap.docs) {
      const circle = circleDoc.data();
      if (Number(circle.currentRound) < 1) continue;
      try {
        await _processDisbursementInternal(circleDoc.id, Number(circle.currentRound));
      } catch (error) {
        logger.error('[processDisbursements] Circle payout check failed.', {
          circleId: circleDoc.id, message: error && error.message,
        });
      }
    }
  }
);

exports.initializeCardSetup = onCall(
  { region: 'us-central1', secrets: [PAYSTACK_SECRET_KEY] },
  async (request) => {
    const uid = requireAuth(request);
    const userSnap = await db.doc(paths.userDoc(uid)).get();
    const email = (request.auth.token.email ||
      (userSnap.exists && userSnap.data().email) || '').trim().toLowerCase();
    if (!email.includes('@')) throw new HttpsError('failed-precondition', 'A valid account email is required.');
    const reference = state.stableReference('cv_card', [uid, uuidv4()]);
    const amountKobo = 5000;
    const setupRef = db.doc(paymentSetupPath(uid, reference));
    await setupRef.create({ uid, reference, amountKobo, email, status: 'initializing', createdAt: admin.firestore.FieldValue.serverTimestamp() });
    let result;
    try { result = await paystack.initializeTransaction(email, amountKobo, reference, PAYSTACK_SECRET_KEY.value()); await setupRef.update({ status: 'initialized' }); }
    catch (error) { await setupRef.update({ status: 'initialization_failed' }); throw error; }
    return { authorizationUrl: result.authorization_url, reference };
  }
);

exports.completeCardSetup = onCall(
  { region: 'us-central1', secrets: [PAYSTACK_SECRET_KEY] },
  async (request) => {
    const uid = requireAuth(request);
    const reference = requireString(request.data && request.data.reference, 'reference', 120);
    const setupRef = db.doc(paymentSetupPath(uid, reference));
    const setupSnap = await setupRef.get();
    if (!setupSnap.exists || setupSnap.data().uid !== uid) {
      throw new HttpsError('permission-denied', 'Card setup reference is not authorized.');
    }
    if (setupSnap.data().status === 'completed') {
      const publicUser = await db.doc(paths.userDoc(uid)).get();
      const data = publicUser.data() || {};
      return { hasLinkedCard: true, last4: data.paystackCardLast4 || '', bank: data.paystackCardBank || '' };
    }
    const verified = await paystack.verifyTransaction(reference, PAYSTACK_SECRET_KEY.value());
    const setup = setupSnap.data();
    if (!state.isVerifiedContribution(verified, {
      reference, amountKobo: setup.amountKobo,
    }) || String((verified.customer || {}).email || '').toLowerCase() !== String(setup.email).toLowerCase() || !verified.authorization || verified.authorization.reusable !== true) {
      throw new HttpsError('failed-precondition', 'Paystack did not verify a reusable successful card.');
    }
    const privateRef = db.doc(privatePaymentPath(uid));
    const publicRef = db.doc(paths.userDoc(uid));
    const authorization = verified.authorization;
    const customer = verified.customer || {};
    const batch = db.batch();
    batch.set(privateRef, {
      authorizationCode: authorization.authorization_code,
      customerCode: customer.customer_code || null,
      cardSignature: authorization.signature || null,
      cardLast4: authorization.last4 || '',
      cardBank: authorization.bank || '',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    batch.set(publicRef, {
      hasLinkedCard: true,
      paystackCardLast4: authorization.last4 || '',
      paystackCardBank: authorization.bank || '',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      paystackCustomerCode: admin.firestore.FieldValue.delete(),
      paystackAuthorizationCode: admin.firestore.FieldValue.delete(),
      paystackCardSignature: admin.firestore.FieldValue.delete(),
    }, { merge: true });
    batch.update(setupRef, { status: 'completed', completedAt: admin.firestore.FieldValue.serverTimestamp() });
    await batch.commit();
    return { hasLinkedCard: true, last4: authorization.last4 || '', bank: authorization.bank || '' };
  }
);

exports.getPaymentMethod = onCall({ region: 'us-central1' }, async (request) => {
  const uid = requireAuth(request);
  const userSnap = await db.doc(paths.userDoc(uid)).get();
  const data = userSnap.exists ? userSnap.data() : {};
  return {
    hasLinkedCard: data.hasLinkedCard === true,
    last4: data.paystackCardLast4 || '',
    bank: data.paystackCardBank || '',
    canReceivePayouts: data.canReceivePayouts === true,
  };
});

exports.removePaymentMethod = onCall({ region: 'us-central1' }, async (request) => {
  const uid = requireAuth(request);
  const privateRef = db.doc(privatePaymentPath(uid));
  const userRef = db.doc(paths.userDoc(uid));
  const batch = db.batch();
  batch.set(privateRef, {
    authorizationCode: admin.firestore.FieldValue.delete(),
    customerCode: admin.firestore.FieldValue.delete(),
    cardSignature: admin.firestore.FieldValue.delete(),
    cardLast4: admin.firestore.FieldValue.delete(),
    cardBank: admin.firestore.FieldValue.delete(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
  batch.set(userRef, {
    hasLinkedCard: false,
    paystackCardLast4: admin.firestore.FieldValue.delete(),
    paystackCardBank: admin.firestore.FieldValue.delete(),
    paystackCustomerCode: admin.firestore.FieldValue.delete(),
    paystackAuthorizationCode: admin.firestore.FieldValue.delete(),
    paystackCardSignature: admin.firestore.FieldValue.delete(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
  await batch.commit();
  return { success: true };
});

exports.getBankList = onCall(
  { region: 'us-central1', secrets: [PAYSTACK_SECRET_KEY] },
  async (request) => {
    requireAuth(request);
    const banks = await paystack.getBankList(PAYSTACK_SECRET_KEY.value());
    return { banks: banks.map((bank) => ({ name: bank.name, code: bank.code })) };
  }
);

exports.createTransferRecipient = onCall(
  { region: 'us-central1', secrets: [PAYSTACK_SECRET_KEY] },
  async (request) => {
    const uid = requireAuth(request);
    const name = requireString(request.data && request.data.accountName, 'accountName', 120);
    const accountNumber = requireString(request.data && request.data.accountNumber, 'accountNumber', 20);
    const bankCode = requireString(request.data && request.data.bankCode, 'bankCode', 20);
    if (!/^[0-9]{10}$/.test(accountNumber)) throw new HttpsError('invalid-argument', 'Nigerian account number must contain ten digits.');
    const recipient = await paystack.createTransferRecipient(name, accountNumber, bankCode, PAYSTACK_SECRET_KEY.value());
    if (!recipient.recipient_code) throw new HttpsError('internal', 'Paystack did not return a recipient code.');
    const privateRef = db.doc(privatePaymentPath(uid));
    const publicRef = db.doc(paths.userDoc(uid));
    const batch = db.batch();
    batch.set(privateRef, {
      transferRecipientCode: recipient.recipient_code,
      transferRecipientName: name,
      transferRecipientBankCode: bankCode,
      transferRecipientAccountLast4: accountNumber.slice(-4),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    batch.set(publicRef, {
      canReceivePayouts: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      paystackTransferRecipientCode: admin.firestore.FieldValue.delete(),
    }, { merge: true });
    await batch.commit();
    return { canReceivePayouts: true, accountLast4: accountNumber.slice(-4) };
  }
);

exports.syncEmailVerification = onCall({ region: 'us-central1' }, async (request) => {
  const uid = requireAuth(request);
  if (request.auth.token.email_verified !== true) {
    throw new HttpsError('permission-denied', 'Firebase has not verified this email address.');
  }
  await db.doc(paths.userDoc(uid)).set({
    isVerified: true,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
  return { isVerified: true };
});

exports.lookupUserByEmail = onCall({ region: 'us-central1' }, async (request) => {
  const callerUid = requireAuth(request);
  const email = requireString(request.data && request.data.email, 'email', 254).toLowerCase();
  const circleId = requireString(request.data && request.data.circleId, 'circleId', 140);
  const circleSnap = await db.doc(paths.circleDoc(circleId)).get();
  if (!circleSnap.exists || circleSnap.data().adminUid !== callerUid || circleSnap.data().status !== 'pending') {
    throw new HttpsError('permission-denied', 'Only the admin of a pending circle can look up members.');
  }
  const matches = await db.collection(paths.usersCollection()).where('email', '==', email).limit(1).get();
  if (matches.empty) return null;
  const doc = matches.docs[0];
  const data = doc.data();
  return { uid: doc.id, name: String(data.name || '').slice(0, 120) };
});

exports.generateFinancialTip = onCall(
  { region: 'us-central1', secrets: [GEMINI_API_KEY] },
  async (request) => {
    const uid = requireAuth(request);
    const context = requireString(request.data && request.data.context, 'context', 2000);
    const usageRef = db.doc('aiUsage/' + uid);
    const now = Date.now();
    const allowed = await db.runTransaction(async (tx) => {
      const snap = await tx.get(usageRef);
      const last = snap.exists ? Number(snap.data().lastRequestMillis || 0) : 0;
      if (now - last < 60000) return false;
      tx.set(usageRef, { lastRequestMillis: now }, { merge: true });
      return true;
    });
    if (!allowed) throw new HttpsError('resource-exhausted', 'Please wait before requesting another tip.');
    try {
      const response = await axios.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent',
        {
          systemInstruction: { parts: [{ text: 'You are a personal finance advisor for Nigerian users in a ROSCA savings group called Circle Vault. Give one concise, actionable, culturally relevant financial tip. Use warm, plain English, under 80 words, no bullets.' }] },
          contents: [{ role: 'user', parts: [{ text: context }] }],
          generationConfig: { maxOutputTokens: 256, temperature: 0.8, topP: 0.95 },
          safetySettings: [
            { category: 'HARM_CATEGORY_HARASSMENT', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
            { category: 'HARM_CATEGORY_HATE_SPEECH', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
          ],
        },
        { params: { key: GEMINI_API_KEY.value() }, timeout: 20000 }
      );
      const candidate = response.data && response.data.candidates && response.data.candidates[0];
      const tipText = candidate && candidate.content && candidate.content.parts &&
        candidate.content.parts[0] && candidate.content.parts[0].text;
      if (!tipText || !String(tipText).trim()) {
        throw new HttpsError('unavailable', 'The advisory service returned no tip.');
      }
      return { tipText: String(tipText).trim() };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error('[generateFinancialTip] Provider request failed.', { status: error.response && error.response.status });
      throw new HttpsError('unavailable', 'The advisory service is temporarily unavailable.');
    }
  }
);

exports.paystackWebhook = onRequest(
  { region: 'us-central1', secrets: [PAYSTACK_SECRET_KEY] },
  async (request, response) => {
    if (request.method !== 'POST') return response.status(405).send('Method not allowed.');
    const signature = request.get('x-paystack-signature') || '';
    const rawBody = request.rawBody;
    if (!state.validPaystackSignature(rawBody, signature, PAYSTACK_SECRET_KEY.value())) {
      logger.warn('[paystackWebhook] Rejected invalid signature.');
      return response.status(401).send('Invalid signature.');
    }
    const event = request.body || {};
    const data = event.data || {};
    const eventKey = state.stableReference('evt', [event.event || '', data.reference || '', data.id || '', data.status || '']);
    const eventRef = db.doc('paystackWebhookEvents/' + eventKey);
    try {
      try { await eventRef.create({ event: String(event.event || '').slice(0, 80), receivedAt: admin.firestore.FieldValue.serverTimestamp() }); }
      catch (claimError) {
        if (claimError.code === 6 || claimError.code === 'already-exists') return response.status(200).send('Duplicate accepted.');
        throw claimError;
      }
      if (event.event === 'charge.success' && typeof data.reference === 'string') {
        const attempts = await db.collectionGroup('paymentAttempts')
          .where('reference', '==', data.reference).limit(1).get();
        if (!attempts.empty) {
          const attemptDoc = attempts.docs[0];
          const match = attemptDoc.ref.path.match(/^circles\/([^/]+)\/paymentAttempts\/([^/]+)$/);
          if (match && state.isVerifiedContribution(data, {
            reference: attemptDoc.data().reference,
            amountKobo: attemptDoc.data().amountKobo,
          })) {
            await finalizeContribution(match[1], Number(attemptDoc.data().roundNumber),
              attemptDoc.data().memberUid, attemptDoc.ref, data);
          }
        }
      } else if (['transfer.success', 'transfer.failed', 'transfer.reversed'].includes(event.event) &&
          typeof data.reference === 'string') {
        const slots = await db.collectionGroup('rotationSlots')
          .where('payoutReference', '==', data.reference).limit(1).get();
        if (!slots.empty) {
          const slotRef = slots.docs[0].ref;
          const match = slotRef.path.match(/^circles\/([^/]+)\/rotationSlots\/([^/]+)$/);
          const slot = slots.docs[0].data();
          if (match && Number(data.amount) === Number(slot.payoutAmountKobo)) {
            const round = Number(match[2]);
            if (event.event === 'transfer.success') {
              const verified = await paystack.verifyTransfer(data.reference, PAYSTACK_SECRET_KEY.value());
              if (verified.status === 'success' && verified.reference === data.reference &&
                  Number(verified.amount) === Number(slot.payoutAmountKobo)) {
                await finalizePayout(match[1], round, slotRef, verified);
              }
            } else if (event.event === 'transfer.failed') {
              await slotRef.update({
                payoutStatus: 'failed',
                disbursed: false,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              });
            } else {
              await slotRef.update({
                payoutStatus: 'review',
                payoutReversedAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              });
            }
          } else {
            logger.error('[paystackWebhook] Transfer event did not match payout record.', { reference: data.reference });
          }
        }
      }
      return response.status(200).send('Accepted.');
    } catch (error) {
      await eventRef.delete().catch(() => {});
      logger.error('[paystackWebhook] Event processing failed.', {
        event: String(event.event || '').slice(0, 40),
        message: error && error.message,
      });
      return response.status(500).send('Retry later.');
    }
  }
);

