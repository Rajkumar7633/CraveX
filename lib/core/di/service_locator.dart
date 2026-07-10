import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zomato_clone/core/constants/app_constants.dart';
import 'package:zomato_clone/data/datasources/local/auth_local_datasource.dart';
import 'package:zomato_clone/data/datasources/local/auth_local_datasource_impl.dart';
import 'package:zomato_clone/data/datasources/remote/auth_remote_datasource.dart';
import 'package:zomato_clone/data/datasources/remote/auth_remote_datasource_impl.dart';
import 'package:zomato_clone/data/repositories/auth_repository_impl.dart';
import 'package:zomato_clone/domain/repositories/auth_repository.dart';
import 'package:zomato_clone/presentation/bloc/auth/auth_bloc.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton(() => sharedPreferences);

  // Core
  getIt.registerLazySingleton(() => Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      sendTimeout: const Duration(milliseconds: AppConstants.sendTimeout),
    ),
  ));

  // Data Sources
  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: getIt()),
  );

  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: getIt()),
  );

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: getIt(),
      localDataSource: getIt(),
    ),
  );

  // BLoCs
  getIt.registerFactory(
    () => AuthBloc(authRepository: getIt()),
  );
}
