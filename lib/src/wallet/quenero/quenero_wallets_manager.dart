import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quenero_coin/wallet_manager.dart' as quenero_wallet_manager;
import 'package:quenero_wallet/src/wallet/wallet_info.dart';
import 'package:quenero_wallet/src/wallet/wallet_type.dart';
import 'package:quenero_wallet/src/wallet/wallets_manager.dart';
import 'package:quenero_wallet/src/wallet/wallet.dart';
import 'package:quenero_wallet/src/wallet/wallet_description.dart';

import 'package:quenero_wallet/src/wallet/quenero/quenero_wallet.dart';
import 'package:quenero_wallet/devtools.dart';

Future<String> pathForWallet({String name}) async {
  final directory = await getApplicationDocumentsDirectory();
  final pathDir = directory.path + '/$name';
  final dir = Directory(pathDir);

  if (!await dir.exists()) {
    await dir.create();
  }

  return pathDir + '/$name';
}

class QueneroWalletsManager extends WalletsManager {
  QueneroWalletsManager({@required this.walletInfoSource});

  static const type = WalletType.quenero;
  static const nettype = isTestnet ? 1 : 0; // Mainnet: 0 Testnet: 1

  Box<WalletInfo> walletInfoSource;

  @override
  Future<Wallet> create(String name, String password, String language) async {
    try {
      const isRecovery = false;
      final path = await pathForWallet(name: name);

      await quenero_wallet_manager.createWallet(path: path, password: password, language: language, nettype: nettype);

      final wallet = await QueneroWallet.createdWallet(
          walletInfoSource: walletInfoSource,
          name: name,
          isRecovery: isRecovery);
      await wallet.updateInfo();

      return wallet;
    } catch (e) {
      print('QueneroWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future<Wallet> restoreFromSeed(
      String name, String password, String seed, int restoreHeight) async {
    try {
      const isRecovery = true;
      final path = await pathForWallet(name: name);

      await quenero_wallet_manager.restoreFromSeed(
          path: path,
          password: password,
          seed: seed,
          restoreHeight: restoreHeight,
        nettype: nettype
      );

      final wallet = await QueneroWallet.createdWallet(
          walletInfoSource: walletInfoSource,
          name: name,
          isRecovery: isRecovery,
          restoreHeight: restoreHeight);
      await wallet.updateInfo();

      return wallet;
    } catch (e) {
      print('QueneroWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future<Wallet> restoreFromKeys(
      String name,
      String password,
      String language,
      int restoreHeight,
      String address,
      String viewKey,
      String spendKey) async {
    try {
      const isRecovery = true;
      final path = await pathForWallet(name: name);

      await quenero_wallet_manager.restoreFromKeys(
          path: path,
          password: password,
          language: language,
          restoreHeight: restoreHeight,
          nettype: nettype,
          address: address,
          viewKey: viewKey,
          spendKey: spendKey);

      final wallet = await QueneroWallet.createdWallet(
          walletInfoSource: walletInfoSource,
          name: name,
          isRecovery: isRecovery,
          restoreHeight: restoreHeight);
      await wallet.updateInfo();

      return wallet;
    } catch (e) {
      print('QueneroWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future<Wallet> openWallet(String name, String password) async {
    print('opening a Wallet with nettype $nettype');
    try {
      final path = await pathForWallet(name: name);
      quenero_wallet_manager.openWallet(path: path, password: password, nettype: nettype);
      final wallet = await QueneroWallet.load(walletInfoSource, name, type);
      await wallet.updateInfo();
      return wallet;
    } catch (e) {
      print('QueneroWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isWalletExit(String name) async {
    try {
      final path = await pathForWallet(name: name);
      return quenero_wallet_manager.isWalletExist(path: path);
    } catch (e) {
      print('QueneroWalletsManager Error: $e');
      rethrow;
    }
  }

  @override
  Future remove(WalletDescription wallet) async {
    final dir = await getApplicationDocumentsDirectory();
    final root = dir.path.replaceAll('app_flutter', 'files');
    final walletFilePath = root + '/quenero_coin/' + wallet.name;
    final keyPath = walletFilePath + '.keys';
    final addressFilePath = walletFilePath + '.address.txt';
    final walletFile = File(walletFilePath);
    final keyFile = File(keyPath);
    final addressFile = File(addressFilePath);

    if (await walletFile.exists()) {
      await walletFile.delete();
    }

    if (await keyFile.exists()) {
      await keyFile.delete();
    }

    if (await addressFile.exists()) {
      await addressFile.delete();
    }

    final id =
        walletTypeToString(wallet.type).toLowerCase() + '_' + wallet.name;
    final info = walletInfoSource.values
        .firstWhere((info) => info.id == id, orElse: () => null);

    await info?.delete();
  }
}
