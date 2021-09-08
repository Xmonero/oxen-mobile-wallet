import 'package:intl/intl.dart';
import 'package:quenero_wallet/src/wallet/crypto_amount_format.dart';

const queneroAmountDivider = 1000000000;

String queneroAmountToString(int amount,
    {AmountDetail detail = AmountDetail.ultra}) {
  final queneroAmountFormat = NumberFormat()
    ..maximumFractionDigits = detail.fraction
    ..minimumFractionDigits = 1;
  return queneroAmountFormat.format(queneroAmountToDouble(amount));
}

double queneroAmountToDouble(int amount) =>
    cryptoAmountToDouble(amount: amount, divider: queneroAmountDivider);
