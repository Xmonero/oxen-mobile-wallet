import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:quenero_coin/quenero_coin_structs.dart';
import 'package:quenero_coin/src/exceptions/creation_transaction_exception.dart';
import 'package:quenero_coin/src/quenero_api.dart';
import 'package:quenero_coin/src/structs/ut8_box.dart';
import 'package:quenero_coin/src/util/signatures.dart';
import 'package:quenero_coin/src/util/types.dart';

final stakeCountNative = queneroApi
    .lookup<NativeFunction<stake_count>>('stake_count')
    .asFunction<StakeCount>();

final stakeGetAllNative = queneroApi
    .lookup<NativeFunction<stake_get_all>>('stake_get_all')
    .asFunction<StakeGetAll>();

final stakeCreateNative = queneroApi
    .lookup<NativeFunction<stake_create>>('stake_create')
    .asFunction<StakeCreate>();

final canRequestUnstakeNative = queneroApi
    .lookup<NativeFunction<can_request_unstake>>('can_request_stake_unlock')
    .asFunction<CanRequestUnstake>();

final submitStakeUnlockNative = queneroApi
    .lookup<NativeFunction<submit_stake_unlock>>('submit_stake_unlock')
    .asFunction<SubmitStakeUnlock>();

PendingTransactionDescription createStakeSync(
    String serviceNodeKey, String amount) {
  final serviceNodeKeyPointer = Utf8.toUtf8(serviceNodeKey);
  final amountPointer = Utf8.toUtf8(amount);
  final errorMessagePointer = allocate<Utf8Box>();
  final pendingTransactionRawPointer = allocate<PendingTransactionRaw>();
  final created = stakeCreateNative(serviceNodeKeyPointer, amountPointer,
          errorMessagePointer, pendingTransactionRawPointer) !=
      0;

  free(serviceNodeKeyPointer);

  if (amountPointer != nullptr) {
    free(amountPointer);
  }

  if (!created) {
    final message = errorMessagePointer.ref.getValue();
    free(errorMessagePointer);
    throw CreationTransactionException(message: message);
  }

  return PendingTransactionDescription(
      amount: pendingTransactionRawPointer.ref.amount,
      fee: pendingTransactionRawPointer.ref.fee,
      hash: pendingTransactionRawPointer.ref.getHash(),
      pointerAddress: pendingTransactionRawPointer.address);
}

PendingTransactionDescription submitStakeUnlockSync(String serviceNodeKey) {
  final serviceNodeKeyPointer = Utf8.toUtf8(serviceNodeKey);
  final errorMessagePointer = allocate<Utf8Box>();
  final pendingTransactionRawPointer = allocate<PendingTransactionRaw>();
  final created = submitStakeUnlockNative(serviceNodeKeyPointer,
          errorMessagePointer, pendingTransactionRawPointer) !=
      0;

  free(serviceNodeKeyPointer);

  if (!created) {
    final message = errorMessagePointer.ref.getValue();
    free(errorMessagePointer);
    throw CreationTransactionException(message: message);
  }

  return PendingTransactionDescription(
      amount: pendingTransactionRawPointer.ref.amount,
      fee: pendingTransactionRawPointer.ref.fee,
      hash: pendingTransactionRawPointer.ref.getHash(),
      pointerAddress: pendingTransactionRawPointer.address);
}
