import 'package:flutter/foundation.dart';
import 'package:quenero_coin/transaction_history.dart' as transaction_history;
import 'package:quenero_coin/quenero_coin_structs.dart';
import 'package:quenero_wallet/src/wallet/quenero/quenero_amount_format.dart';

class PendingTransaction {
  PendingTransaction(
      {@required this.amount, @required this.fee, @required this.hash});

  PendingTransaction.fromTransactionDescription(
      PendingTransactionDescription transactionDescription)
      : amount = queneroAmountToString(transactionDescription.amount),
        fee = queneroAmountToString(transactionDescription.fee),
        hash = transactionDescription.hash,
        _pointerAddress = transactionDescription.pointerAddress;

  final String amount;
  final String fee;
  final String hash;

  int _pointerAddress;

  Future<void> commit() async => transaction_history
      .commitTransactionFromPointerAddress(address: _pointerAddress);
}
