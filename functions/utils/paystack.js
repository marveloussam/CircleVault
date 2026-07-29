const axios = require('axios');

const BASE_URL = 'https://api.paystack.co';

function headers() {
  const key = process.env.PAYSTACK_SECRET_KEY;
  if (!key) throw new Error('PAYSTACK_SECRET_KEY env var not set.');
  return {
    Authorization: `Bearer ${key}`,
    'Content-Type': 'application/json',
  };
}

/**
 * Charge a saved card using a reusable authorization code.
 * @param {string} authCode  - Paystack authorization_code
 * @param {string} email     - Customer email
 * @param {number} amountKobo - Amount in kobo
 * @param {string} reference  - Unique transaction reference
 */
async function chargeAuthorization(authCode, email, amountKobo, reference) {
  const { data } = await axios.post(
    `${BASE_URL}/charge/authorization`,
    {
      authorization_code: authCode,
      email,
      amount: amountKobo,
      reference,
    },
    { headers: headers() }
  );
  if (!data.status) throw new Error(data.message || 'Charge failed.');
  return data.data;
}

/**
 * Create a Paystack transfer recipient (bank account for payout).
 */
async function createTransferRecipient(name, accountNumber, bankCode) {
  const { data } = await axios.post(
    `${BASE_URL}/transferrecipient`,
    {
      type: 'nuban',
      name,
      account_number: accountNumber,
      bank_code: bankCode,
      currency: 'NGN',
    },
    { headers: headers() }
  );
  if (!data.status) throw new Error(data.message || 'Failed to create recipient.');
  return data.data;
}

/**
 * Initiate a transfer (payout) to a recipient code.
 * @param {string} recipientCode - Paystack recipient_code
 * @param {number} amountKobo
 * @param {string} reference     - Unique transfer reference
 * @param {string} reason        - Human-readable reason
 */
async function initiateTransfer(recipientCode, amountKobo, reference, reason) {
  const { data } = await axios.post(
    `${BASE_URL}/transfer`,
    {
      source: 'balance',
      amount: amountKobo,
      recipient: recipientCode,
      reference,
      reason: reason || 'ROSCA payout — Circle Vault',
    },
    { headers: headers() }
  );
  if (!data.status) throw new Error(data.message || 'Transfer failed.');
  return data.data;
}

/**
 * Verify a transfer by reference.
 */
async function verifyTransfer(reference) {
  const { data } = await axios.get(
    `${BASE_URL}/transfer/verify/${reference}`,
    { headers: headers() }
  );
  if (!data.status) throw new Error(data.message || 'Transfer verification failed.');
  return data.data;
}

module.exports = {
  chargeAuthorization,
  createTransferRecipient,
  initiateTransfer,
  verifyTransfer,
};
