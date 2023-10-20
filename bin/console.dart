import 'dart:typed_data';
import 'package:token_bounded_account/utils/contract.dart';
import 'package:token_bounded_account/utils/service_locator.dart';
import 'package:token_bounded_account/utils/utils.dart';
import 'package:dotenv/dotenv.dart';
import 'package:logger/logger.dart';
import 'package:web3dart/web3dart.dart';

void main() async {
  await ServiceLocator.setUp();

  final creds = ServiceLocator.getIt<Credentials>();
  final dotEnv = ServiceLocator.getIt<DotEnv>();
  final logger = ServiceLocator.getIt<Logger>();
  final web3client = ServiceLocator.getIt<Web3Client>();

  final DeployedContract nftContract = await perepareContract(
    address: dotEnv["NFT_ADDRESS"] as String,
    contractName: "NFT",
    fileName: 'nft',
  );

  final chainId = await web3client.getChainId();

  logger.i("Minting NFT");

  final mintTransction = Transaction.callContract(
    contract: nftContract,
    function: nftContract.function('safeMint'),
    parameters: [creds.address, ""],
  );

  final mintHash = await web3client.sendTransaction(
    creds,
    mintTransction,
    chainId: chainId.toInt(),
  );

  final mintStatus = await checkTransactionStatus(mintHash);

  if (!mintStatus) {
    logger.e("Minting failed");
    return;
  }

  logger.i("NFT Minted: $mintHash");

  final DeployedContract accountContract = await perepareContract(
    address: dotEnv["ACCOUNT_ADDRESS"] as String,
    contractName: "ERC6551Account",
    fileName: 'account',
  );

  final DeployedContract registryContract = await perepareContract(
    fileName: 'registry',
    contractName: "ERC6551Registry",
    address: dotEnv["REGISTRY_ADDRESS"] as String,
  );

  logger.i("Creating new token bounded account");

  final createAccountTransaction = Transaction.callContract(
    contract: registryContract,
    function: registryContract.function('createAccount'),
    parameters: [
      accountContract.address,
      chainId,
      nftContract.address,
      BigInt.one, // NFT Id
      BigInt.zero, // Salt
      Uint8List.fromList([]), // Empty data || 0x
    ],
  );

  final accountHash = await web3client.sendTransaction(
    creds,
    createAccountTransaction,
    chainId: chainId.toInt(),
  );

  final accountCreationStatus = await checkTransactionStatus(accountHash);

  if (!accountCreationStatus) {
    logger.e("Account creation failed");
    return;
  }

  logger.i("Account created: $accountHash");

  logger.i("Fetching account address");

  final result = await web3client.call(
    contract: registryContract,
    function: registryContract.function('account'),
    params: [
      accountContract.address,
      BigInt.from(80001),
      nftContract.address,
      BigInt.one,
      BigInt.zero,
    ],
  );

  final tokenBoundAccountAddress = result.first.hexEip55;

  logger.i("Token bound account address: $tokenBoundAccountAddress");

  logger.i("Transfering Matic to token bound account");

  final transferHash = await web3client.sendTransaction(
    creds,
    Transaction(
      value: EtherAmount.inWei(BigInt.from(1500000000000000)),
      to: EthereumAddress.fromHex(tokenBoundAccountAddress),
    ),
    chainId: chainId.toInt(),
  );

  final transferStatus = await checkTransactionStatus(transferHash);

  if (!transferStatus) {
    logger.i("Failed to transfer tokens");
    return;
  }

  logger.i("Transfer success: $transferHash");

  final tokenBoundAccount = await perepareContract(
    address: tokenBoundAccountAddress,
    fileName: 'account',
    contractName: 'ERC6551Account',
  );

  logger.i("Transfering Matic from token bound account");

  final transferFromTokenBound = await web3client.sendTransaction(
    creds,
    Transaction.callContract(
      contract: tokenBoundAccount,
      function: tokenBoundAccount.function('executeCall'),
      value: EtherAmount.zero(),
      parameters: [
        creds.address,
        BigInt.from(100000000000),
        Uint8List.fromList([]),
      ],
    ),
    chainId: chainId.toInt(),
  );

  final transferFromTokenBoundStatus = await checkTransactionStatus(
    transferFromTokenBound,
  );

  if (transferFromTokenBoundStatus) {
    logger.i("Transfer success: $transferFromTokenBound");
  } else {
    logger.e("Failed to transfer token from token bound account");
  }
}
