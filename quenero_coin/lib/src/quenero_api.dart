import 'dart:ffi';
import 'dart:io';

final DynamicLibrary queneroApi = Platform.isAndroid
    ? DynamicLibrary.open('libquenero_coin.so')
    : DynamicLibrary.process();
