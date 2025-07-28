const { validate: isUUID } = require('uuid');
const isValidCurrency = require('currency-codes').code;
const moment = require('moment-timezone');
const validator = require('validator');

function validateTransaction(transaction) {
  const errors = [];
  const recommendations = [];

  if (transaction.amount <= 0) {
    errors.push("Amount must be greater than zero.");
    recommendations.push("Ensure the transaction amount is a positive number.");
  }

  if (!isValidCurrency(transaction.currency)) {
    errors.push("Currency must be a valid ISO 4217 code.");
    recommendations.push("Use accepted currency codes like USD, EUR, TND.");
  }

  if (!moment(transaction.timestamp, moment.ISO_8601, true).isValid()) {
    errors.push("Timestamp must be in valid ISO 8601 format.");
    recommendations.push("Use a standard timestamp like '2025-07-08T14:30:00Z'.");
  } else if (new Date(transaction.timestamp) > new Date()) {
    errors.push("Timestamp must not be in the future.");
    recommendations.push("Use a valid timestamp not ahead of current time.");
  }

  if (!isUUID(transaction.transactionId)) {
    errors.push("Transaction ID must be a valid UUID.");
    recommendations.push("Use a UUID v4 string for transaction ID.");
  }

  if (!validator.isIP(transaction.ipAddress || '')) {
    errors.push("IP Address must be a valid IPv4 or IPv6 address.");
    recommendations.push("Verify the client’s IP address format.");
  }

  const details = transaction.details || {};

  switch (transaction.type) {
    case 'bank_card':
      if (!validator.isCreditCard(details.cardNumber || '')) {
        errors.push("Card number must be valid (Luhn algorithm).");
        recommendations.push("Verify the card number format.");
      }
      if (!/^\d{3}$/.test(details.cvv || '')) {
        errors.push("CVV must be a 3-digit number.");
        recommendations.push("Ensure CVV is exactly 3 digits.");
      }
      if (!/^\d{6}$/.test(details.bin || '')) {
        errors.push("BIN must be 6 digits.");
        recommendations.push("Ensure the BIN is a 6-digit number.");
      }
      if (!moment(details.expiryDate, "MM/YY", true).isValid() ||
          moment(details.expiryDate, "MM/YY").isBefore(moment())) {
        errors.push("Expiry date must be in the future.");
        recommendations.push("Use a valid MM/YY date that’s not expired.");
      }
      if (!details.bank) {
        errors.push("Bank name must not be empty.");
        recommendations.push("Provide the issuing bank’s name.");
      }
      break;

    case 'bank_transfer':
      if (!/^([A-Z]{2})(\d{2})([A-Z0-9]{1,30})$/.test(details.iban || '')) {
        errors.push("IBAN must follow country format.");
        recommendations.push("Ensure the IBAN is well-formed (e.g., FR76...).");
      }
      if (!/^[A-Z]{8,11}$/.test(details.bic || '')) {
        errors.push("BIC must be 8 or 11 uppercase characters.");
        recommendations.push("Use a valid SWIFT/BIC code.");
      }
      if (!details.timezone || !moment.tz.zone(details.timezone)) {
        errors.push("Timezone must be a valid tz database name.");
        recommendations.push("Use formats like 'Europe/Paris'.");
      }
      break;

    case 'mobile_payment':
      if (!/^\+\d{6,15}$/.test(details.phoneNumber || '')) {
        errors.push("Phone number must follow international format.");
        recommendations.push("Use format like '+21650123456'.");
      }
      if (!['Ooredoo', 'Orange', 'Tunisie Telecom'].includes(details.operator)) {
        errors.push("Operator must be in known operator list.");
        recommendations.push("Use a known operator like Ooredoo.");
      }
      if (!['3G', '4G', '5G', 'WiFi'].includes(details.networkType)) {
        errors.push("Network type must be 3G, 4G, 5G, or WiFi.");
        recommendations.push("Ensure correct network type is used.");
      }
      break;

    case 'e_wallet':
      if (!['PayPal', 'Apple Pay', 'Google Pay'].includes(details.provider)) {
        errors.push("Provider must be PayPal, Apple Pay, or Google Pay.");
        recommendations.push("Use one of the supported wallet providers.");
      }
      if (!['debit', 'credit'].includes((details.linkedCardType || '').toLowerCase())) {
        errors.push("Linked card type must be debit or credit.");
        recommendations.push("Use 'debit' or 'credit' as card type.");
      }
      if (details.lastActivity && new Date(details.lastActivity) > new Date(transaction.timestamp)) {
        errors.push("Last activity must be before the transaction timestamp.");
        recommendations.push("Verify last usage timestamp.");
      }
      break;

    case 'electronic_check':
      if (details.signature !== 'Valid') {
        errors.push("Signature must be 'Valid'.");
        recommendations.push("Ensure the check signature is valid.");
      }
      if (!['accepted', 'rejected', 'pending'].includes(details.status)) {
        errors.push("Status must be accepted, rejected, or pending.");
        recommendations.push("Provide correct check status.");
      }
      if (!/^([A-Z]{2})(\d{2})([A-Z0-9]{1,30})$/.test(details.iban || '')) {
        errors.push("IBAN format must be respected.");
        recommendations.push("Provide a valid IBAN.");
      }
      break;

    case 'cryptocurrency':
      if (!/^[a-zA-Z0-9]{25,42}$/.test(details.walletAddress || '')) {
        errors.push("Wallet address format is invalid.");
        recommendations.push("Ensure wallet address matches crypto format.");
      }
      if (!(details.exchangeRate > 0)) {
        errors.push("Exchange rate must be greater than zero.");
        recommendations.push("Provide a positive exchange rate.");
      }
      if (!/^[a-fA-F0-9]{64}$/.test(details.txHash || '')) {
        errors.push("Hash must be 64-character hexadecimal string.");
        recommendations.push("Use proper hash format (SHA256).");
      }
      break;

    default:
      errors.push("Unknown transaction type.");
      recommendations.push("Use a supported transaction type.");
  }

  const isValid = errors.length === 0;

  return {
    isValid,
    errors,
    recommendations,
    enrichedTransaction: {
      ...transaction,
      validationStatus: isValid ? 'valid' : 'invalid',
      failureReasons: isValid ? [] : errors,
      recommendations: isValid ? [] : recommendations,
      processedAt: new Date().toISOString()
    }
  };
}

module.exports = { validateTransaction };
