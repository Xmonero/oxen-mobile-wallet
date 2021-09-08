import 'package:quenero_coin/transaction_history.dart';
import 'package:quenero_wallet/src/wallet/quenero/quenero_amount_format.dart';
import 'package:quenero_wallet/src/wallet/quenero/transaction/transaction_priority.dart';

double calculateEstimatedFee({QueneroTransactionPriority priority}) {
  return queneroAmountToDouble(estimateTransactionFee(priority.raw));
}
