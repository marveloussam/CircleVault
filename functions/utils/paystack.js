'use strict';

const axios = require('axios');

const BASE_URL = 'https://api.paystack.co';
const REQUEST_TIMEOUT_MS = 15000;

function headers(secretKey) {
  if (typeof secretKey !== 'string' || !secretKey) {
    throw new Error('Paystack secret is unavailable.');
  }
  return {
    Authorization: 'Bearer ' + secretKey,
    'Content-Type': 'application/json',
  };
}

async function request(method, path, secretKey, data) {
  try {
    const response = await axios.request({
      method,
      url: BASE_URL + path,
      headers: headers(secretKey),
      data,
      timeout: REQUEST_TIMEOUT_MS,
    });
    const envelope = response.data;
    if (!envelope || envelope.status !== true || !envelope.data) {
      const error = new Error('Paystack did not accept the request.');
      error.outcomeUnknown = true;
      throw error;
    }
    return envelope.data;
  } catch (cause) {
    if (cause && typeof cause.outcomeUnknown === 'boolean') throw cause;
    const httpStatus = cause && cause.response && cause.response.status;
    const error = new Error(httpStatus
      ? 'Paystack request failed with HTTP ' + httpStatus + '.'
      : 'Paystack request outcome is unknown.');
    error.outcomeUnknown = !httpStatus || httpStatus >= 500;
    throw error;
  }
}

function initializeTransaction(email, amountKobo, reference, secretKey) {
  return request('post', '/transaction/initialize', secretKey, {
    email,
    amount: amountKobo,
    reference,
    channels: ['card'],
  });
}

function verifyTransaction(reference, secretKey) {
  return request('get', '/transaction/verify/' + encodeURIComponent(reference), secretKey);
}

function chargeAuthorization(authCode, email, amountKobo, reference, secretKey) {
  return request('post', '/transaction/charge_authorization', secretKey, {
    authorization_code: authCode,
    email,
    amount: amountKobo,
    reference,
    currency: 'NGN',
    queue: true,
  });
}

function createTransferRecipient(name, accountNumber, bankCode, secretKey) {
  return request('post', '/transferrecipient', secretKey, {
    type: 'nuban',
    name,
    account_number: accountNumber,
    bank_code: bankCode,
    currency: 'NGN',
  });
}

function initiateTransfer(recipientCode, amountKobo, reference, reason, secretKey) {
  return request('post', '/transfer', secretKey, {
    source: 'balance',
    amount: amountKobo,
    recipient: recipientCode,
    reference,
    reason: reason || 'ROSCA payout - Circle Vault',
  });
}

function verifyTransfer(reference, secretKey) {
  return request('get', '/transfer/verify/' + encodeURIComponent(reference), secretKey);
}

function getBankList(secretKey) {
  return request('get', '/bank?country=nigeria&perPage=100', secretKey);
}

module.exports = {
  chargeAuthorization,
  createTransferRecipient,
  getBankList,
  initiateTransfer,
  initializeTransaction,
  verifyTransaction,
  verifyTransfer,
};

