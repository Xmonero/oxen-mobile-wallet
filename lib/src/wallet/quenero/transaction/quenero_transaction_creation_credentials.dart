import 'package:quenero_wallet/src/wallet/quenero/transaction/transaction_priority.dart';
import 'package:quenero_wallet/src/wallet/transaction/transaction_creation_credentials.dart';

class QueneroTransactionCreationCredentials
    extends TransactionCreationCredentials {
  QueneroTransactionCreationCredentials(
      {this.address, this.priority, this.amount});

  final String address;
  final String amount;
  final QueneroTransactionPriority priority;
}
