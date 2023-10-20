import 'dart:async';

import 'package:token_bounded_account/utils/service_locator.dart';
import 'package:web3dart/web3dart.dart';

extension HexExtension on String {
  String get append0x {
    return "0x$this";
  }
}

Future<bool> checkTransactionStatus(String hash) async {
  final completer = Completer<bool>();
  Timer.periodic(Duration(seconds: 1), (timer) async {
    final client = ServiceLocator.getIt<Web3Client>();
    final receipt = await client.getTransactionReceipt(
      hash,
    );

    if (receipt != null && receipt.status is bool) {
      if (!completer.isCompleted) {
        completer.complete(receipt.status!);
        return;
      }
    }
  });

  return await completer.future;
}
