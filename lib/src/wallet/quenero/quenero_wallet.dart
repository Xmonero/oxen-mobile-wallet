import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:quenero_coin/stake.dart' as quenero_stake;
import 'package:quenero_coin/transaction_history.dart' as transaction_history;
import 'package:quenero_coin/wallet.dart' as quenero_wallet;
import 'package:quenero_wallet/src/node/node.dart';
import 'package:quenero_wallet/src/node/sync_status.dart';
import 'package:quenero_wallet/src/wallet/balance.dart';
import 'package:quenero_wallet/src/wallet/quenero/account.dart';
import 'package:quenero_wallet/src/wallet/quenero/account_list.dart';
import 'package:quenero_wallet/src/wallet/quenero/quenero_balance.dart';
import 'package:quenero_wallet/src/wallet/quenero/subaddress.dart';
import 'package:quenero_wallet/src/wallet/quenero/subaddress_list.dart';
import 'package:quenero_wallet/src/wallet/quenero/transaction/quenero_stake_transaction_creation_credentials.dart';
import 'package:quenero_wallet/src/wallet/quenero/transaction/quenero_transaction_creation_credentials.dart';
import 'package:quenero_wallet/src/wallet/quenero/transaction/quenero_transaction_history.dart';
import 'package:quenero_wallet/src/wallet/transaction/pending_transaction.dart';
import 'package:quenero_wallet/src/wallet/transaction/transaction_creation_credentials.dart';
import 'package:quenero_wallet/src/wallet/transaction/transaction_history.dart';
import 'package:quenero_wallet/src/wallet/wallet.dart';
import 'package:quenero_wallet/src/wallet/wallet_info.dart';
import 'package:quenero_wallet/src/wallet/wallet_type.dart';
import 'package:rxdart/rxdart.dart';

const queneroBlockSize = 1000;

class QueneroWallet extends Wallet {
  QueneroWallet({this.walletInfoSource, this.walletInfo}) {
    _cachedBlockchainHeight = 0;
    _name = BehaviorSubject<String>();
    _address = BehaviorSubject<String>();
    _syncStatus = BehaviorSubject<SyncStatus>();
    _onBalanceChange = BehaviorSubject<QueneroBalance>();
    _account = BehaviorSubject<Account>()..add(Account(id: 0));
    _subaddress = BehaviorSubject<Subaddress>();
  }

  static Future<QueneroWallet> createdWallet(
      {Box<WalletInfo> walletInfoSource,
      String name,
      bool isRecovery = false,
      int restoreHeight = 0}) async {
    const type = WalletType.quenero;
    final id = walletTypeToString(type).toLowerCase() + '_' + name;
    final walletInfo = WalletInfo(
        id: id,
        name: name,
        type: type,
        isRecovery: isRecovery,
        restoreHeight: restoreHeight,
        timestamp: DateTime.now().millisecondsSinceEpoch);
    await walletInfoSource.add(walletInfo);

    return await configured(
        walletInfo: walletInfo, walletInfoSource: walletInfoSource);
  }

  static Future<QueneroWallet> load(
      Box<WalletInfo> walletInfoSource, String name, WalletType type) async {
    final id = walletTypeToString(type).toLowerCase() + '_' + name;
    final walletInfo = walletInfoSource.values
        .firstWhere((info) => info.id == id, orElse: () => null);
    return await configured(
        walletInfoSource: walletInfoSource, walletInfo: walletInfo);
  }

  static Future<QueneroWallet> configured(
      {@required Box<WalletInfo> walletInfoSource,
      @required WalletInfo walletInfo}) async {
    final wallet =
        QueneroWallet(walletInfoSource: walletInfoSource, walletInfo: walletInfo);

    if (walletInfo.isRecovery) {
      wallet.setRecoveringFromSeed();

      if (walletInfo.restoreHeight != null) {
        wallet.setRefreshFromBlockHeight(height: walletInfo.restoreHeight);
      }
    }

    return wallet;
  }

  @override
  String get address => _address.value;

  @override
  String get name => _name.value;

  @override
  WalletType getType() => WalletType.quenero;

  @override
  Observable<SyncStatus> get syncStatus => _syncStatus.stream;

  @override
  Observable<Balance> get onBalanceChange => _onBalanceChange.stream;

  @override
  Observable<String> get onNameChange => _name.stream;

  @override
  Observable<String> get onAddressChange => _address.stream;

  Observable<Account> get onAccountChange => _account.stream;

  Observable<Subaddress> get subaddress => _subaddress.stream;

  bool get isRecovery => walletInfo.isRecovery;

  Account get account => _account.value;

  Box<WalletInfo> walletInfoSource;
  WalletInfo walletInfo;

  quenero_wallet.SyncListener _listener;
  BehaviorSubject<Account> _account;
  BehaviorSubject<QueneroBalance> _onBalanceChange;
  BehaviorSubject<SyncStatus> _syncStatus;
  BehaviorSubject<String> _name;
  BehaviorSubject<String> _address;
  BehaviorSubject<Subaddress> _subaddress;
  int _cachedBlockchainHeight;

  TransactionHistory _cachedTransactionHistory;
  SubaddressList _cachedSubaddressList;
  AccountList _cachedAccountList;
  Future<int> _cachedGetNodeHeightOrUpdateRequest;

  @override
  Future updateInfo() async {
    _name.value = await getName();
    final acccountList = getAccountList();
    acccountList.refresh();
    _account.value = acccountList.getAll().first;
    final subaddressList = getSubaddress();
    await subaddressList.refresh(
        accountIndex: _account.value != null ? _account.value.id : 0);
    final subaddresses = subaddressList.getAll();
    _subaddress.value = subaddresses.first;
    _address.value = await getAddress();
    setListeners();
  }

  @override
  Future<String> getFilename() async => quenero_wallet.getFilename();

  @override
  Future<String> getName() async => getFilename()
      .then((filename) => filename.split('/'))
      .then((splitted) => splitted.last);

  @override
  Future<String> getAddress() async => quenero_wallet.getAddress(
      accountIndex: _account.value.id, addressIndex: _subaddress.value.id);

  @override
  Future<String> getSeed() async => quenero_wallet.getSeed();

  @override
  Future<int> getFullBalance() async {
    final balance = await quenero_wallet.getFullBalance(accountIndex: _account.value.id);
    return balance;
  }

  @override
  Future<int> getUnlockedBalance() async {
    final balance = await quenero_wallet.getUnlockedBalance(accountIndex: _account.value.id);
    return balance;
  }

  @override
  int getCurrentHeight() => quenero_wallet.getCurrentHeight();

  @override
  bool isRefreshing() => quenero_wallet.isRefreshing();

  @override
  Future<int> getNodeHeight() async {
    _cachedGetNodeHeightOrUpdateRequest ??=
        quenero_wallet.getNodeHeight().then((value) {
      _cachedGetNodeHeightOrUpdateRequest = null;
      return value;
    });

    return _cachedGetNodeHeightOrUpdateRequest;
  }

  @override
  Future<bool> isConnected() async => quenero_wallet.isConnected();

  @override
  Future<Map<String, String>> getKeys() async => {
        'publicViewKey': quenero_wallet.getPublicViewKey(),
        'privateViewKey': quenero_wallet.getSecretViewKey(),
        'publicSpendKey': quenero_wallet.getPublicSpendKey(),
        'privateSpendKey': quenero_wallet.getSecretSpendKey()
      };

  @override
  TransactionHistory getHistory() {
    _cachedTransactionHistory ??= QueneroTransactionHistory();

    return _cachedTransactionHistory;
  }

  SubaddressList getSubaddress() {
    _cachedSubaddressList ??= SubaddressList();

    return _cachedSubaddressList;
  }

  AccountList getAccountList() {
    _cachedAccountList ??= AccountList();

    return _cachedAccountList;
  }

  @override
  Future close() async {
    _listener?.stop();
    quenero_wallet.closeCurrentWallet();
    await _name.close();
    await _address.close();
    await _subaddress.close();
  }

  @override
  Future connectToNode(
      {Node node, bool useSSL = false, bool isLightWallet = false}) async {
    try {
      _syncStatus.value = ConnectingSyncStatus();

      // Check if node is online to avoid crash
      final nodeIsOnline = await node.isOnline();
      if (!nodeIsOnline) {
        _syncStatus.value = FailedSyncStatus();
        return;
      }

      await quenero_wallet.setupNode(
          address: node.uri,
          login: node.login,
          password: node.password,
          useSSL: useSSL,
          isLightWallet: isLightWallet);
      _syncStatus.value = ConnectedSyncStatus();
    } catch (e) {
      _syncStatus.value = FailedSyncStatus();
      print(e);
    }
  }

  @override
  Future startSync() async {
    try {
      _setInitialHeight();
    } catch (_) {}

    print('Starting from height: ${getCurrentHeight()}');

    try {
      _syncStatus.value = StartingSyncStatus();
      quenero_wallet.startRefresh();
      _setListeners();
      _listener?.start();
    } catch (e) {
      _syncStatus.value = FailedSyncStatus();
      print(e);
      rethrow;
    }
  }

  Future<int> getNodeHeightOrUpdate(int baseHeight) async {
    if (_cachedBlockchainHeight < baseHeight) {
      _cachedBlockchainHeight = await getNodeHeight();
    }

    return _cachedBlockchainHeight;
  }

  @override
  Future<PendingTransaction> createStake(
      TransactionCreationCredentials credentials) async {
    final _credentials = credentials as QueneroStakeTransactionCreationCredentials;
    if (_credentials.amount == null || _credentials.address == null) {
      return Future.error('Amount and address cannot be null.');
    }
    final transactionDescription =
    await quenero_stake.createStake(_credentials.address, _credentials.amount);

    return PendingTransaction.fromTransactionDescription(
        transactionDescription);
  }

  @override
  Future<PendingTransaction> createTransaction(
      TransactionCreationCredentials credentials) async {
    final _credentials = credentials as QueneroTransactionCreationCredentials;
    final transactionDescription = await transaction_history.createTransaction(
        address: _credentials.address,
        amount: _credentials.amount,
        priorityRaw: _credentials.priority.serialize(),
        accountIndex: _account.value.id);

    return PendingTransaction.fromTransactionDescription(
        transactionDescription);
  }

  @override
  Future rescan({int restoreHeight = 0}) async {
    _syncStatus.value = StartingSyncStatus();
    setRefreshFromBlockHeight(height: restoreHeight);
    quenero_wallet.rescanBlockchainAsync();
    _syncStatus.value = StartingSyncStatus();
  }

  void setRecoveringFromSeed() =>
      quenero_wallet.setRecoveringFromSeed(isRecovery: true);

  void setRefreshFromBlockHeight({int height}) =>
      quenero_wallet.setRefreshFromBlockHeight(height: height);

  Future setAsRecovered() async {
    walletInfo.isRecovery = false;
    await walletInfo.save();
  }

  Future askForUpdateBalance() async {
    final fullBalance = await getFullBalance();
    final unlockedBalance = await getUnlockedBalance();
    final needToChange = _onBalanceChange.value != null
        ? _onBalanceChange.value.fullBalance != fullBalance ||
        _onBalanceChange.value.unlockedBalance != unlockedBalance
        : true;

    if (!needToChange) {
      return;
    }

    _onBalanceChange.add(QueneroBalance(
        fullBalance: fullBalance, unlockedBalance: unlockedBalance));
  }

  Future askForUpdateTransactionHistory() async {
    await getHistory().update();
  }

  void changeCurrentSubaddress(Subaddress subaddress) =>
      _subaddress.value = subaddress;

  void changeAccount(Account account) {
    _account.add(account);

    getSubaddress()
        .refresh(accountIndex: account.id)
        .then((dynamic _) => getSubaddress().getAll())
        .then((subaddresses) => _subaddress.value = subaddresses[0]);
  }

  quenero_wallet.SyncListener setListeners() =>
      quenero_wallet.setListeners(_onNewBlock, _onNewTransaction);

  Future _onNewBlock(int height, int blocksLeft, double ptc, bool isRefreshing) async {
    try {
      if (isRefreshing) {
        _syncStatus.add(SyncingSyncStatus(blocksLeft, ptc));
      } else {
        await askForUpdateTransactionHistory();
        await askForUpdateBalance();

        if (blocksLeft < 100) {
          _syncStatus.add(SyncedSyncStatus());
          await quenero_wallet.store();

          if (walletInfo.isRecovery) {
            await setAsRecovered();
          }
        }

        if (blocksLeft <= 1) {
          quenero_wallet.setRefreshFromBlockHeight(height: height);
        }
      }
    } catch (e) {
      print(e.toString());
    }
  }

  void _setListeners() {
    _listener?.stop();
    _listener = quenero_wallet.setListeners(_onNewBlock, _onNewTransaction);
  }

  void _setInitialHeight() {
    if (walletInfo.isRecovery) {
      return;
    }

    final currentHeight = getCurrentHeight();
    print('setInitialHeight() $currentHeight');

    if (currentHeight <= 1) {
      final height = _getHeightByDate(walletInfo.date);
      quenero_wallet.setRecoveringFromSeed(isRecovery: true);
      quenero_wallet.setRefreshFromBlockHeight(height: height);
    }
  }

  int _getHeightDistance(DateTime date) {
    final distance =
        DateTime.now().millisecondsSinceEpoch - date.millisecondsSinceEpoch;
    final daysTmp = (distance / 86400).round();
    final days = daysTmp < 1 ? 1 : daysTmp;

    return days * 1000;
  }

  int _getHeightByDate(DateTime date) {
    final nodeHeight = quenero_wallet.getNodeHeightSync();
    final heightDistance = _getHeightDistance(date);

    if (nodeHeight <= 0) {
      return 0;
    }

    return nodeHeight - heightDistance;
  }

  Future _onNewTransaction() async {
    try {
      await askForUpdateTransactionHistory();
      await askForUpdateBalance();
    } catch (e) {
      print(e.toString());
    }
  }
}
