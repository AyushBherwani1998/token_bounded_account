import 'package:token_bounded_account/utils/account.dart';
import 'package:token_bounded_account/utils/utils.dart';
import 'package:dotenv/dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

class ServiceLocator {
  const ServiceLocator._();

  static GetIt get getIt => GetIt.instance;

  static Future<void> setUp() async {
    final dotenv = DotEnv(includePlatformEnvironment: true)..load();
    getIt.registerSingleton<DotEnv>(dotenv);

    final privateKey = (dotenv['PRIVATE_KEY'] as String).append0x;
    final Credentials credentials = exportAccount(privateKey);

    getIt.registerSingleton<Credentials>(credentials);

    final Web3Client web3client = Web3Client(
      'https://rpc.ankr.com/polygon_mumbai',
      Client(),
    );

    getIt.registerSingleton<Web3Client>(web3client);

    getIt.registerLazySingleton<Logger>(() => Logger(printer: PrettyPrinter()));
  }
}
