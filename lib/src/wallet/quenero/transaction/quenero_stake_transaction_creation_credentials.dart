import 'package:quenero_wallet/src/wallet/transaction/transaction_creation_credentials.dart';

class QueneroStakeTransactionCreationCredentials
    extends TransactionCreationCredentials {
  QueneroStakeTransactionCreationCredentials({this.address, this.amount});

  final String address;
  final String amount;
}
