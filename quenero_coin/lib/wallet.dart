import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:quenero_coin/src/exceptions/setup_wallet_exception.dart';
import 'package:quenero_coin/src/native/wallet.dart' as quenero_wallet;
import 'package:quenero_coin/src/util/convert_utf8_to_string.dart';

int _boolToInt(bool value) => value ? 1 : 0;

final statusSyncChannel =
    BasicMessageChannel<ByteData>('quenero_coin.sync_listener', BinaryCodec());

final queneroMethodChannel = MethodChannel('quenero_coin');

int getSyncingHeight() => quenero_wallet.getSyncingHeightNative();

bool isNeededToRefresh() => quenero_wallet.isNeededToRefreshNative() != 0;

bool isNewTransactionExist() => quenero_wallet.isNewTransactionExistNative() != 0;

String getFilename() =>
    convertUTF8ToString(pointer: quenero_wallet.getFileNameNative());

String getSeed() => convertUTF8ToString(pointer: quenero_wallet.getSeedNative());

String getAddress({int accountIndex = 0, int addressIndex = 0}) =>
    convertUTF8ToString(
        pointer: quenero_wallet.getAddressNative(accountIndex, addressIndex));

int _getFullBalanceSync(int accountIndex) =>
    quenero_wallet.getFullBalanceNative(accountIndex);

Future<int> getFullBalance({int accountIndex = 0}) =>
  compute<int, int>(_getFullBalanceSync, accountIndex);

int _getUnlockedBalanceSync(int accountIndex) =>
    quenero_wallet.getUnlockedBalanceNative(accountIndex);

Future<int> getUnlockedBalance({int accountIndex = 0}) =>
    compute<int, int>(_getUnlockedBalanceSync, accountIndex);

int getCurrentHeight() => quenero_wallet.getCurrentHeightNative();

int getNodeHeightSync() => quenero_wallet.getNodeHeightNative();

bool isRefreshingSync() => quenero_wallet.isRefreshingNative() != 0;

bool isConnectedSync() => quenero_wallet.isConnectedNative() != 0;

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
  final isSetupNode = quenero_wallet.setupNodeNative(
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

void startRefreshSync() => quenero_wallet.startRefreshNative();

Future<bool> connectToNode() async => quenero_wallet.connecToNodeNative() != 0;

void setRefreshFromBlockHeight({int height}) =>
    quenero_wallet.setRefreshFromBlockHeightNative(height);

void setRecoveringFromSeed({bool isRecovery}) =>
    quenero_wallet.setRecoveringFromSeedNative(_boolToInt(isRecovery));

void closeCurrentWallet() => quenero_wallet.closeCurrentWalletNative();

String getSecretViewKey() =>
    convertUTF8ToString(pointer: quenero_wallet.getSecretViewKeyNative());

String getPublicViewKey() =>
    convertUTF8ToString(pointer: quenero_wallet.getPublicViewKeyNative());

String getSecretSpendKey() =>
    convertUTF8ToString(pointer: quenero_wallet.getSecretSpendKeyNative());

String getPublicSpendKey() =>
    convertUTF8ToString(pointer: quenero_wallet.getPublicSpendKeyNative());

class SyncListener {
  SyncListener(this.onNewBlock, this.onNewTransaction) {
    _cachedBlockchainHeight = 0;
    _lastKnownBlockHeight = 0;
    _initialSyncHeight = 0;
  }

  void Function(int, int, double, bool) onNewBlock;
  void Function() onNewTransaction;

  Timer _updateSyncInfoTimer;
  int _cachedBlockchainHeight;
  int _lastKnownBlockHeight;
  int _initialSyncHeight;

  Future<int> getNodeHeightOrUpdate(int baseHeight) async {
    if (_cachedBlockchainHeight < baseHeight || _cachedBlockchainHeight == 0) {
      _cachedBlockchainHeight = await getNodeHeight();
    }

    return _cachedBlockchainHeight;
  }

  void start() {
    _cachedBlockchainHeight = 0;
    _lastKnownBlockHeight = 0;
    _initialSyncHeight = 0;
    _updateSyncInfoTimer ??=
        Timer.periodic(Duration(milliseconds: 1200), (_) async {
      // var syncHeight = getSyncingHeight();
      //
      // if (syncHeight <= 0) {
      //   syncHeight = getCurrentHeight();
      // }

      final syncHeight = getCurrentHeight();

      if (_initialSyncHeight <= 0) {
        _initialSyncHeight = syncHeight;
      }

      final bchHeight = await getNodeHeightOrUpdate(syncHeight);

      if (_lastKnownBlockHeight == syncHeight || syncHeight == null) {
        return;
      }

      _lastKnownBlockHeight = syncHeight;
      final track = bchHeight - _initialSyncHeight;
      final diff = track - (bchHeight - syncHeight);
      final ptc = diff <= 0 ? 0.0 : diff / track;
      final left = bchHeight - syncHeight;

      if (syncHeight < 0 || left < 0) {
        return;
      }

      final refreshing = isRefreshing();
      if (!refreshing) {
        if (isNewTransactionExist()) {
          onNewTransaction?.call();
        }
      }

      // 1. Actual new height; 2. Blocks left to finish; 3. Progress in percents;
      onNewBlock?.call(syncHeight, left, ptc, refreshing);
    });
  }

  void stop() => _updateSyncInfoTimer?.cancel();
}

SyncListener setListeners(void Function(int, int, double, bool) onNewBlock,
    void Function() onNewTransaction) {
  final listener = SyncListener(onNewBlock, onNewTransaction);
  quenero_wallet.setListenerNative();
  return listener;
}

void onStartup() => quenero_wallet.onStartupNative();

void _storeSync(Object _) => quenero_wallet.storeSync();

bool _setupNodeSync(Map args) {
  final address = args['address'] as String;
  final login = (args['login'] ?? '') as String;
  final password = (args['password'] ?? '') as String;
  final useSSL = args['useSSL'] as bool;
  final isLightWallet = args['isLightWallet'] as bool;

  return setupNodeSync(
      address: address,
      login: login,
      password: password,
      useSSL: useSSL,
      isLightWallet: isLightWallet);
}

bool _isConnected(Object _) => isConnectedSync();

bool isRefreshing() => isRefreshingSync();

int _getNodeHeight(Object _) => getNodeHeightSync();

void startRefresh() => startRefreshSync();

Future setupNode(
        {String address,
        String login,
        String password,
        bool useSSL = false,
        bool isLightWallet = false}) =>
    compute<Map<String, Object>, void>(_setupNodeSync, {
      'address': address,
      'login': login,
      'password': password,
      'useSSL': useSSL,
      'isLightWallet': isLightWallet
    });

Future store() => compute<int, void>(_storeSync, 0);

Future<bool> isConnected() => compute(_isConnected, 0);

Future<int> getNodeHeight() => compute(_getNodeHeight, 0);

void rescanBlockchainAsync() => quenero_wallet.rescanBlockchainAsyncNative();
