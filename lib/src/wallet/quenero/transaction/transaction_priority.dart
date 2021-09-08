import 'package:quenero_wallet/generated/l10n.dart';
import 'package:quenero_wallet/src/domain/common/enumerable_item.dart';

class QueneroTransactionPriority extends EnumerableItem<int> with Serializable<int> {
  const QueneroTransactionPriority({String title, int raw})
      : super(title: title, raw: raw);

  static const all = [
    QueneroTransactionPriority.slow,
    QueneroTransactionPriority.blink
  ];

  static const slow = QueneroTransactionPriority(title: 'Slow', raw: 1);
  static const blink = QueneroTransactionPriority(title: 'Blink', raw: 5);
  static const standard = blink;

  static QueneroTransactionPriority deserialize({int raw}) {
    switch (raw) {
      case 1:
        return slow;
      case 5:
        return blink;
      default:
        return null;
    }
  }

  @override
  String toString() {
    switch (this) {
      case QueneroTransactionPriority.slow:
        return S.current.transaction_priority_slow;
      case QueneroTransactionPriority.blink:
        return S.current.transaction_priority_blink;
      default:
        return '';
    }
  }
}
