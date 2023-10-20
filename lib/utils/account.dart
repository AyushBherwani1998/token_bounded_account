import 'package:web3dart/web3dart.dart';

Credentials exportAccount(String privateKey) {
  return EthPrivateKey.fromHex(privateKey);
}

