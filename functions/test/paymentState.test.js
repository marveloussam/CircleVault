'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const { classifyChargeStatus, contributionAction, isVerifiedContribution, payoutAction, stableReference, validPaystackSignature } = require('../utils/paymentState');

test('only actual Paystack transaction status determines charge state', () => {
  assert.equal(classifyChargeStatus({ status: 'success' }), 'succeeded');
  for (const status of ['failed', 'abandoned', 'reversed']) assert.equal(classifyChargeStatus({ status }), 'failed');
  for (const status of ['pending', 'ongoing', 'processing', 'queued']) assert.equal(classifyChargeStatus({ status }), 'pending');
  assert.equal(classifyChargeStatus({ status: 'accepted' }), 'unknown');
  assert.equal(classifyChargeStatus(null), 'unknown');
});

test('contribution confirmation checks status, reference, exact amount, and NGN currency', () => {
  const expected = { reference: 'cv_contrib_test', amountKobo: 250000 };
  const verified = { status: 'success', reference: expected.reference, amount: expected.amountKobo, currency: 'NGN' };
  assert.equal(isVerifiedContribution(verified, expected), true);
  assert.equal(isVerifiedContribution({ ...verified, status: 'pending' }, expected), false);
  assert.equal(isVerifiedContribution({ ...verified, reference: 'other' }, expected), false);
  assert.equal(isVerifiedContribution({ ...verified, amount: 1 }, expected), false);
  assert.equal(isVerifiedContribution({ ...verified, currency: 'USD' }, expected), false);
});

test('contribution retries charge only when absent or conclusively failed', () => {
  assert.deepEqual(contributionAction(null, 1000), { action: 'charge', attemptNumber: 1 });
  assert.deepEqual(contributionAction({ status: 'succeeded' }, 1000), { action: 'skip' });
  assert.deepEqual(contributionAction({ status: 'failed', attemptNumber: 2 }, 1000), { action: 'charge', attemptNumber: 3 });
  assert.deepEqual(contributionAction({ status: 'pending' }, 1000), { action: 'reconcile' });
  assert.deepEqual(contributionAction({ status: 'unknown' }, 1000), { action: 'reconcile' });
  assert.deepEqual(contributionAction({ status: 'processing', leaseUntilMillis: 2000 }, 1000), { action: 'skip' });
  assert.deepEqual(contributionAction({ status: 'processing', leaseUntilMillis: 500 }, 1000), { action: 'reconcile' });
});

test('payout decisions reconcile unresolved operations and skip completed payouts', () => {
  assert.equal(payoutAction(null), 'initiate');
  for (const payoutStatus of ['pending', 'unknown', 'processing']) assert.equal(payoutAction({ payoutStatus }), 'reconcile');
  assert.equal(payoutAction({ payoutStatus: 'succeeded' }), 'skip');
  assert.equal(payoutAction({ disbursed: true, payoutStatus: 'failed' }), 'skip');
  assert.equal(payoutAction({ payoutStatus: 'failed' }), 'retry');
});

test('references are stable for a payment attempt and change between attempts', () => {
  const parts = ['circle-a', 4, 'member-a', 1];
  assert.equal(stableReference('cv_contrib', parts), stableReference('cv_contrib', parts));
  assert.notEqual(stableReference('cv_contrib', parts), stableReference('cv_contrib', [...parts.slice(0, 3), 2]));
  assert.match(stableReference('cv_payout', ['circle-a', 4, 1]), /^cv_payout_[a-f0-9]{32}$/);
});

test('webhook signatures use HMAC SHA512 and reject mismatches', () => {
  const rawBody = Buffer.from('{"event":"transfer.success"}');
  const secret = 'test-secret-only';
  const signature = crypto.createHmac('sha512', secret).update(rawBody).digest('hex');
  assert.equal(validPaystackSignature(rawBody, signature, secret), true);
  assert.equal(validPaystackSignature(rawBody, signature.slice(0, -1) + '0', secret), false);
  assert.equal(validPaystackSignature(rawBody, signature, 'wrong-secret'), false);
  assert.equal(validPaystackSignature(rawBody, signature, ''), false);
});

