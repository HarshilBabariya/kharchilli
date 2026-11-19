import 'format.dart';

/// A payment read out of a bank or UPI message: [amount] is negative for money received.
typedef CapturedPayment = ({double amount, String merchant});

/// Decides whether a message is a completed payment and pulls out the amount and the other party.
/// Ported from HomeQuest's PaymentParser so both apps accept and reject the same messages.
class PaymentParser {
  static final _amount = RegExp(r'(?:₹|\brs\.?|\binr)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)', caseSensitive: false);
  static final _debit = RegExp(r'\b(paid|sent|debited|spent|payment of|purchase|withdrawn|transferred)\b', caseSensitive: false);
  static final _skip = RegExp(
      r'\b(otp|requested|request|failed|declined|reversed|pending|initiated|due on|is due|will be debited|will be credited|will be refunded|auto ?pay set|received your payment|payment received|salary|interest)\b',
      caseSensitive: false);
  static final _promo = RegExp(r'(?:₹|\brs\.?|\binr)\s*[0-9][0-9,]*\s*(?:off|discount)\b|\b[0-9]+\s*%\s*off\b|\b(offer|offers|coupon|promo ?code|use code|upto|up to|flat|shop now)\b', caseSensitive: false);
  static final _confirmation = RegExp(r'\b(debited|credited|spent|a/c|acct|avl\.? bal|ref(?: no)?|txn|upi ref)\b', caseSensitive: false);
  static final _paidYou = RegExp(r'\b(paid you|sent you)\b', caseSensitive: false);
  static final _credit = RegExp(r'\b(credited|received|refund|refunded|cashback)\b', caseSensitive: false);
  static final _sender = RegExp(
      r"^\s*([\p{L}0-9&.' ]{2,40}?)\s+(?:paid|sent) you\b|\bfrom\s+(?:vpa\s+)?([\p{L}0-9&.'@_ -]{2,40}?)(?=\s+(?:on|via|using|ref|upi|to|in|a/c|ac|is|has|was|processed)\b|[.,(]|$)",
      caseSensitive: false,
      unicode: true);
  static final _merchant = RegExp(r"\b(?:to|at|towards)\s+(?:vpa\s+)?([\p{L}0-9&.'@_ -]{2,40}?)(?=\s+(?:on|via|using|ref|upi|from|a/c|ac|for)\b|[.,(]|$)", caseSensitive: false, unicode: true);

  static CapturedPayment? parse(String text) {
    if (_skip.hasMatch(text)) return null;
    if (_promo.hasMatch(text) && !_confirmation.hasMatch(text)) return null;
    final debit = _debit.hasMatch(text);
    final credit = _paidYou.hasMatch(text) || (!debit && _credit.hasMatch(text));
    if (!credit && !debit) return null;
    final amount = double.tryParse(_amount.firstMatch(text)?.group(1)?.replaceAll(',', '') ?? '');
    if (amount == null || amount <= 0) return null;
    final String? party;
    if (credit) {
      final m = _sender.firstMatch(text);
      party = m?.group(1) ?? m?.group(2);
    } else {
      party = _merchant.firstMatch(text)?.group(1);
    }
    return (amount: credit ? -amount : amount, merchant: (party ?? '').trim().split('@').first.trim().capitalised);
  }
}
