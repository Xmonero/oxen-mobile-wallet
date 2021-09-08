import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:quenero_coin/src/quenero_api.dart';
import 'package:quenero_coin/src/util/signatures.dart';
import 'package:quenero_coin/src/util/types.dart';

final accountSizeNative = queneroApi
    .lookup<NativeFunction<account_size>>('account_size')
    .asFunction<SubaddressSize>();

final accountRefreshNative = queneroApi
    .lookup<NativeFunction<account_refresh>>('account_refresh')
    .asFunction<AccountRefresh>();

final accountGetAllNative = queneroApi
    .lookup<NativeFunction<account_get_all>>('account_get_all')
    .asFunction<AccountGetAll>();

final accountAddNewNative = queneroApi
    .lookup<NativeFunction<account_add_new>>('account_add_row')
    .asFunction<AccountAddNew>();

final accountSetLabelNative = queneroApi
    .lookup<NativeFunction<account_set_label>>('account_set_label_row')
    .asFunction<AccountSetLabel>();

void addAccountSync({String label}) {
  final labelPointer = Utf8.toUtf8(label);
  accountAddNewNative(labelPointer);
  free(labelPointer);
}

void setLabelForAccountSync({int accountIndex, String label}) {
  final labelPointer = Utf8.toUtf8(label);
  accountSetLabelNative(accountIndex, labelPointer);
  free(labelPointer);
}
