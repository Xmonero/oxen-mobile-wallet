import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:quenero_coin/src/exceptions/setup_wallet_exception.dart';
import 'package:quenero_coin/src/quenero_api.dart';
import 'package:quenero_coin/src/util/convert_utf8_to_string.dart';
import 'package:quenero_coin/src/util/signatures.dart';
import 'package:quenero_coin/src/util/types.dart';

int _boolToInt(bool value) => value ? 1 : 0;

final statusSyncChannel =
    BasicMessageChannel<ByteData>('quenero_coin.sync_listener', BinaryCodec());

final queneroMethodChannel = MethodChannel('quenero_coin');

final getFileNameNative = queneroApi
    .lookup<NativeFunction<get_filename>>('get_filename')
    .asFunction<GetFilename>();

final getSeedNative =
    queneroApi.lookup<NativeFunction<get_seed>>('seed').asFunction<GetSeed>();

final getAddressNative = queneroApi
    .lookup<NativeFunction<get_address>>('get_address')
    .asFunction<GetAddress>();

final getFullBalanceNative = queneroApi
    .lookup<NativeFunction<get_full_balanace>>('get_full_balance')
    .asFunction<GetFullBalance>();

final getUnlockedBalanceNative = queneroApi
    .lookup<NativeFunction<get_unlocked_balanace>>('get_unlocked_balance')
    .asFunction<GetUnlockedBalance>();

final getCurrentHeightNative = queneroApi
    .lookup<NativeFunction<get_current_height>>('get_current_height')
    .asFunction<GetCurrentHeight>();

final getNodeHeightNative = queneroApi
    .lookup<NativeFunction<get_node_height>>('get_node_height')
    .asFunction<GetNodeHeight>();

final isRefreshingNative = queneroApi
    .lookup<NativeFunction<is_refreshing>>('is_refreshing')
    .asFunction<IsRefreshing>();

final isConnectedNative = queneroApi
    .lookup<NativeFunction<is_connected>>('is_connected')
    .asFunction<IsConnected>();

final setupNodeNative = queneroApi
    .lookup<NativeFunction<setup_node>>('setup_node')
    .asFunction<SetupNode>();

final startRefreshNative = queneroApi
    .lookup<NativeFunction<start_refresh>>('start_refresh')
    .asFunction<StartRefresh>();

final connecToNodeNative = queneroApi
    .lookup<NativeFunction<connect_to_node>>('connect_to_node')
    .asFunction<ConnectToNode>();

final setRefreshFromBlockHeightNative = queneroApi
    .lookup<NativeFunction<set_refresh_from_block_height>>(
        'set_refresh_from_block_height')
    .asFunction<SetRefreshFromBlockHeight>();

final setRecoveringFromSeedNative = queneroApi
    .lookup<NativeFunction<set_recovering_from_seed>>(
        'set_recovering_from_seed')
    .asFunction<SetRecoveringFromSeed>();

final storeNative =
    queneroApi.lookup<NativeFunction<store_c>>('store').asFunction<Store>();

final setListenerNative =
    queneroApi.lookupFunction<Void Function(), void Function()>('set_listener');

final getSyncingHeightNative = queneroApi
    .lookup<NativeFunction<get_syncing_height>>('get_syncing_height')
    .asFunction<GetSyncingHeight>();

final isNeededToRefreshNative = queneroApi
    .lookup<NativeFunction<is_needed_to_refresh>>('is_needed_to_refresh')
    .asFunction<IsNeededToRefresh>();

final isNewTransactionExistNative = queneroApi
    .lookup<NativeFunction<is_new_transaction_exist>>(
        'is_new_transaction_exist')
    .asFunction<IsNewTransactionExist>();

final getSecretViewKeyNative = queneroApi
    .lookup<NativeFunction<secret_view_key>>('secret_view_key')
    .asFunction<SecretViewKey>();

final getPublicViewKeyNative = queneroApi
    .lookup<NativeFunction<public_view_key>>('public_view_key')
    .asFunction<PublicViewKey>();

final getSecretSpendKeyNative = queneroApi
    .lookup<NativeFunction<secret_spend_key>>('secret_spend_key')
    .asFunction<SecretSpendKey>();

final getPublicSpendKeyNative = queneroApi
    .lookup<NativeFunction<secret_view_key>>('public_spend_key')
    .asFunction<PublicSpendKey>();

final closeCurrentWalletNative = queneroApi
    .lookup<NativeFunction<close_current_wallet>>('close_current_wallet')
    .asFunction<CloseCurrentWallet>();

final onStartupNative = queneroApi
    .lookup<NativeFunction<on_startup>>('on_startup')
    .asFunction<OnStartup>();

final rescanBlockchainAsyncNative = queneroApi
    .lookup<NativeFunction<rescan_blockchain>>('rescan_blockchain')
    .asFunction<RescanBlockchainAsync>();

int getNodeHeightSync() => getNodeHeightNative();

bool isRefreshingSync() => isRefreshingNative() != 0;

bool isConnectedSync() => isConnectedNative() != 0;

bool setupNodeSync(
    {String address,
    String login,
    String password,
    bool useSSL = false,
    bool isLightWallet = false}) {
  final addressPointer = Utf8.toUtf8(address);
  Pointer<Utf8> loginPointer;
  Pointer<Utf8> passwordPointer;

  if (login != null) {
    loginPointer = Utf8.toUtf8(login);
  }

  if (password != null) {
    passwordPointer = Utf8.toUtf8(password);
  }

  final errorMessagePointer = allocate<Utf8>();
  final isSetupNode = setupNodeNative(
          addressPointer,
          loginPointer,
          passwordPointer,
          _boolToInt(useSSL),
          _boolToInt(isLightWallet),
          errorMessagePointer) !=
      0;

  free(addressPointer);
  free(loginPointer);
  free(passwordPointer);

  if (!isSetupNode) {
    throw SetupWalletException(
        message: convertUTF8ToString(pointer: errorMessagePointer));
  }

  return isSetupNode;
}

void startRefreshSync() => startRefreshNative();

Future<bool> connectToNode() async => connecToNodeNative() != 0;

void setRefreshFromBlockHeight({int height}) =>
    setRefreshFromBlockHeightNative(height);

void setRecoveringFromSeed({bool isRecovery}) =>
    setRecoveringFromSeedNative(_boolToInt(isRecovery));

void storeSync() {
  final pathPointer = Utf8.toUtf8('');
  storeNative(pathPointer);
  free(pathPointer);
}
