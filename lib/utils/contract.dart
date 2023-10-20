import 'dart:io';

import 'package:web3dart/web3dart.dart';

Future<DeployedContract> perepareContract({
  required String fileName,
  required String contractName,
  required String address,
}) async {
  final abi = await _prepareContractAbi(contractName, fileName);
  final contract = DeployedContract(abi, EthereumAddress.fromHex(address));
  return contract;
}

Future<ContractAbi> _prepareContractAbi(String name, String fileName) async {
  final file = File('assets/$fileName.json');
  final abi = await file.readAsString();

  return ContractAbi.fromJson(abi, name);
}
