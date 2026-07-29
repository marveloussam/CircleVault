const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { logger } = require('firebase-functions');
const admin = require('firebase-admin');
const { v4: uuidv4 } = require('uuid');
const paystack = require('./utils/paystack');
const paths = require('./utils/firestoreHelpers');

admin.initializeApp();
const db = admin.firestore();

// NOTE: sendOtp / verifyOtp / issueCustomToken / loginWithPassword have been
// removed. Signup, login, email verification, and password reset are now
// handled directly by the Firebase Auth client SDK (email/password provider),
// which requires no reCAPTCHA and no custom Cloud Functions. `request.auth`
// below is now populated automatically from the client's Firebase ID token.

// ─────────────────────────────────────────────────────────────────────────────
// 1. SCHEDULED CONTRIBUTIONS
//    Runs daily at 08:00 WAT. Charges all active members of due circles.
// ─────────────────────────────────────────────────────────────────────────────

exports.processContributions = onSchedule(
  {
    schedule: '0 8 * * *',
    timeZone: 'Africa/Lagos',
    region: 'us-central1',
  },
  async (_event) => {
    logger.info('[processContributions] Starting daily contribution run.');

    const today = admin.firestore.Timestamp.now();

    const circlesSnap = await db
      .collection('circles')
      .where('status', '==', 'active')
      .where('nextContributionDate', '<=', today)
      .get();

    if (circlesSnap.empty) {
      logger.info('[processContributions] No circles due today.');
      return;
    }

    for (const circleDoc of circlesSnap.docs) {
      const circle = circleDoc.data();
      const circleId = circleDoc.id;
      logger.info(`[processContributions] Processing circle: ${circleId}`);
      try {
        await _processCircleContributions(circleId, circle);
      } catch (err) {
        logger.error(
          `[processContributions] Error on circle ${circleId}:`,
          err
        );
      }
    }
  }
);

async function _processCircleContributions(circleId, circle) {
  const membersSnap = await db
    .collection(paths.membersCollection(circleId))
    .where('status', '==', 'active')
    .get();

  let allSucceeded = true;

  for (const memberDoc of membersSnap.docs) {
    const uid = memberDoc.id;
    try {
      const userSnap = await db.doc(paths.userDoc(uid)).get();
      if (!userSnap.exists) {
        logger.warn(`[contributions] User doc missing for uid: ${uid}`);
        allSucceeded = false;
        continue;
      }

      const user = userSnap.data();
      const authCode = user.paystackAuthorizationCode;

      if (!authCode) {
        logger.warn(`[contributions] No auth code for uid: ${uid} — marking defaulted.`);
        await memberDoc.ref.update({ status: 'defaulted' });
        allSucceeded = false;
        continue;
      }

      const email = user.email || `${uid}@circlevault.app`;
      const reference = `cv_contrib_${circleId}_r${circle.currentRound}_${uid.substring(0, 6)}_${uuidv4().replace(/-/g, '').substring(0, 8)}`;

      const chargeResult = await paystack.chargeAuthorization(
        authCode,
        email,
        circle.contributionAmount,
        reference
      );

      logger.info(`[contributions] Charged uid ${uid} — ref: ${reference}, status: ${chargeResult.status}`);

      const txRef = db
        .collection(paths.transactionsCollection(circleId))
        .doc(uuidv4());

      await txRef.set({
        circleId,
        memberUid: uid,
        type: 'contribution',
        amountKobo: circle.contributionAmount,
        reference,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        roundNumber: circle.currentRound,
        notes: `Automated contribution — Round ${circle.currentRound}`,
      });

      await memberDoc.ref.update({
        totalContributed: admin.firestore.FieldValue.increment(
          circle.contributionAmount
        ),
      });
    } catch (err) {
      logger.error(`[contributions] Failed to charge uid ${uid}:`, err.message);
      await memberDoc.ref.update({ status: 'defaulted' }).catch(() => {});
      allSucceeded = false;
    }
  }

  // Advance nextContributionDate
  const nextDate = _addFrequency(
    circle.nextContributionDate.toDate(),
    circle.frequency
  );
  await db.doc(paths.circleDoc(circleId)).update({
    nextContributionDate: admin.firestore.Timestamp.fromDate(nextDate),
  });

  if (allSucceeded) {
    logger.info(`[contributions] All paid for circle ${circleId} — triggering disbursement.`);
    await _processDisbursementInternal(circleId, circle.currentRound);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. DISBURSEMENT ENGINE — HTTPS callable
// ─────────────────────────────────────────────────────────────────────────────

exports.processDisbursement = onCall(
  { region: 'us-central1' },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be signed in.');
    }

    const { circleId, roundNumber } = request.data;
    if (!circleId || !roundNumber) {
      throw new HttpsError(
        'invalid-argument',
        'circleId and roundNumber are required.'
      );
    }

    try {
      await _processDisbursementInternal(circleId, roundNumber);
      return { success: true };
    } catch (err) {
      logger.error('[processDisbursement] Error:', err.message);
      throw new HttpsError('internal', err.message);
    }
  }
);

async function _processDisbursementInternal(circleId, roundNumber) {
  logger.info(`[disbursement] Starting for circle ${circleId} round ${roundNumber}`);

  const circleSnap = await db.doc(paths.circleDoc(circleId)).get();
  if (!circleSnap.exists) throw new Error(`Circle ${circleId} not found.`);
  const circle = circleSnap.data();

  const contribSnap = await db
    .collection(paths.transactionsCollection(circleId))
    .where('type', '==', 'contribution')
    .where('roundNumber', '==', roundNumber)
    .get();

  const activeMembersSnap = await db
    .collection(paths.membersCollection(circleId))
    .where('status', '==', 'active')
    .get();

  const activeMemberCount = activeMembersSnap.size;

  if (contribSnap.size < activeMemberCount) {
    logger.warn(
      `[disbursement] Only ${contribSnap.size}/${activeMemberCount} contributions received. Aborting.`
    );
    return;
  }

  const slotSnap = await db
    .doc(paths.rotationSlotDoc(circleId, roundNumber))
    .get();
  if (!slotSnap.exists) {
    throw new Error(`Rotation slot ${roundNumber} not found for circle ${circleId}.`);
  }
  const slot = slotSnap.data();

  if (slot.disbursed) {
    logger.warn(`[disbursement] Round ${roundNumber} already disbursed. Skipping.`);
    return;
  }

  const recipientUid = slot.recipientUid;

  const recipientSnap = await db.doc(paths.userDoc(recipientUid)).get();
  if (!recipientSnap.exists) {
    throw new Error(`Recipient user ${recipientUid} not found.`);
  }
  const recipient = recipientSnap.data();

  if (!recipient.paystackCustomerCode) {
    throw new Error(`Recipient ${recipientUid} has no Paystack customer code.`);
  }

  const recipientCode = recipient.paystackTransferRecipientCode;
  if (!recipientCode) {
    logger.warn(
      `[disbursement] No transfer recipient code for ${recipientUid}. ` +
      `User must register bank account first.`
    );
    return;
  }

  const totalPayout = circle.contributionAmount * activeMemberCount;
  const payoutReference = `cv_payout_${circleId}_r${roundNumber}_${uuidv4()
    .replace(/-/g, '')
    .substring(0, 8)}`;

  const transferResult = await paystack.initiateTransfer(
    recipientCode,
    totalPayout,
    payoutReference,
    `Circle Vault ROSCA payout — ${circle.name} Round ${roundNumber}`
  );

  logger.info(`[disbursement] Transfer initiated — ref: ${payoutReference}`);

  const txRef = db
    .collection(paths.transactionsCollection(circleId))
    .doc(uuidv4());

  await txRef.set({
    circleId,
    memberUid: recipientUid,
    type: 'payout',
    amountKobo: totalPayout,
    reference: payoutReference,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    roundNumber,
    notes: `Automated ROSCA payout — Round ${roundNumber}`,
  });

  await db.doc(paths.rotationSlotDoc(circleId, roundNumber)).update({
    disbursed: true,
    disbursedAt: admin.firestore.FieldValue.serverTimestamp(),
    paystackTransferCode: transferResult.transfer_code || payoutReference,
  });

  await db.doc(paths.memberDoc(circleId, recipientUid)).update({
    hasReceivedPayout: true,
  });

  const nextRound = roundNumber + 1;
  const isComplete = nextRound > circle.totalMembers;

  await db.doc(paths.circleDoc(circleId)).update({
    currentRound: nextRound,
    status: isComplete ? 'completed' : 'active',
  });

  if (isComplete) {
    logger.info(`[disbursement] Circle ${circleId} completed all rounds!`);
  }

  const topic = `circle_${circleId}`;
  const recipientName = recipient.name || 'A member';

  await admin.messaging().sendToTopic(topic, {
    notification: {
      title: '🎉 Payout sent!',
      body: `${recipientName} received the Round ${roundNumber} payout from ${circle.name}.`,
    },
    data: {
      type: 'payout',
      circleId,
      roundNumber: String(roundNumber),
    },
  });

  logger.info(`[disbursement] Round ${roundNumber} complete for circle ${circleId}.`);
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

function _addFrequency(from, frequency) {
  const d = new Date(from);
  switch (frequency) {
    case 'weekly':
      d.setDate(d.getDate() + 7);
      break;
    case 'biweekly':
      d.setDate(d.getDate() + 14);
      break;
    case 'monthly':
    default:
      d.setMonth(d.getMonth() + 1);
      break;
  }
  return d;
}