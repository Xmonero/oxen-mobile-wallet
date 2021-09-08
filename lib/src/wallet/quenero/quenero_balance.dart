import 'package:flutter/foundation.dart';
import 'package:quenero_wallet/src/wallet/balance.dart';

class QueneroBalance extends Balance {
  QueneroBalance({@required this.fullBalance, @required this.unlockedBalance});

  final int fullBalance;
  final int unlockedBalance;
}
