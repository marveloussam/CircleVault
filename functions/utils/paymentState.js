'use strict';

const crypto = require('node:crypto');

function normalizeStatus(value) {
  return typeof value === 'string' ? value.trim().toLowerCase() : 'unknown';
}

function classifyChargeStatus(transaction) {
  const status = normalizeStatus(transaction && transaction.status);
  if (status === 'success') return 'succeeded';
  if (['failed', 'abandoned', 'reversed'].includes(status)) return 'failed';
  if (['pending', 'ongoing', 'processing', 'queued'].includes(status)) return 'pending';
  return 'unknown';
}

function isVerifiedContribution(transaction, expected) {
  return Boolean(transaction && expected &&
    normalizeStatus(transaction.status) === 'success' &&
    transaction.reference === expected.reference &&
    Number(transaction.amount) === expected.amountKobo &&
    String(transaction.currency || '').toUpperCase() === 'NGN');
}

function contributionAction(attempt, nowMillis) {
  if (!attempt) return { action: 'charge', attemptNumber: 1 };
  if (attempt.status === 'succeeded') return { action: 'skip' };
  if (attempt.status === 'failed') return { action: 'charge', attemptNumber: (attempt.attemptNumber || 0) + 1 };
  if (attempt.status === 'processing' && Number(attempt.leaseUntilMillis || 0) > nowMillis) return { action: 'skip' };
  if (['processing', 'pending', 'unknown'].includes(attempt.status)) return { action: 'reconcile' };
  return { action: 'review' };
}

function payoutAction(slot) {
  if (!slot) return 'initiate';
  if (slot.disbursed || slot.payoutStatus === 'succeeded') return 'skip';
  if (!slot.payoutStatus || slot.payoutStatus === 'not_started') return 'initiate';
  if (['processing', 'pending', 'unknown'].includes(slot.payoutStatus)) return 'reconcile';
  if (slot.payoutStatus === 'failed') return 'retry';
  return 'review';
}

function stableReference(prefix, parts) {
  const digest = crypto.createHash('sha256').update(parts.map(String).join('\0')).digest('hex').slice(0, 32);
  return prefix + '_' + digest;
}

function validPaystackSignature(rawBody, signature, secret) {
  if (!Buffer.isBuffer(rawBody) || typeof signature !== 'string' || !secret) return false;
  const expected = crypto.createHmac('sha512', secret).update(rawBody).digest('hex');
  const actualBuffer = Buffer.from(signature, 'utf8');
  const expectedBuffer = Buffer.from(expected, 'utf8');
  return actualBuffer.length === expectedBuffer.length && crypto.timingSafeEqual(actualBuffer, expectedBuffer);
}

module.exports = { classifyChargeStatus, contributionAction, isVerifiedContribution, payoutAction, stableReference, validPaystackSignature };

