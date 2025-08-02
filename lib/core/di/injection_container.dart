import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/emergency_repository.dart';
import '../../data/repositories/emergency_repository_impl.dart';
import '../../domain/usecases/emergency_usecases.dart';
import '../../providers/theme_provider.dart';
import '../../providers/emergency_provider.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // Core
  sl.registerLazySingleton<Logger>(() => Logger(
        printer: PrettyPrinter(
          methodCount: 2,
          errorMethodCount: 8,
          lineLength: 120,
          colors: true,
          printEmojis: true,
          dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
        ),
      ));

  // External
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);

  // Repository
  sl.registerLazySingleton<EmergencyRepository>(
    () => EmergencyRepositoryImpl(
      firestore: sl(),
      auth: sl(),
      logger: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetEmergencyContacts(sl()));
  sl.registerLazySingleton(() => AddEmergencyContact(sl()));
  sl.registerLazySingleton(() => UpdateEmergencyContact(sl()));
  sl.registerLazySingleton(() => DeleteEmergencyContact(sl()));
  sl.registerLazySingleton(() => GetEmergencyHistory(sl()));
  sl.registerLazySingleton(() => AddEmergencyHistory(sl()));
  sl.registerLazySingleton(() => UpdateEmergencyHistory(sl()));
  sl.registerLazySingleton(() => ResolveEmergency(sl()));
  sl.registerLazySingleton(() => GetEmergencyMessages(sl()));
  sl.registerLazySingleton(() => SaveCustomMessage(sl()));
  sl.registerLazySingleton(() => ActivateEmergency(sl()));

  // Providers
  sl.registerLazySingleton<ThemeProvider>(() => ThemeProvider());
  sl.registerLazySingleton<EmergencyProvider>(() => EmergencyProvider(
        getEmergencyContacts: sl(),
        addEmergencyContact: sl(),
        updateEmergencyContact: sl(),
        deleteEmergencyContact: sl(),
        getEmergencyHistory: sl(),
        addEmergencyHistory: sl(),
        updateEmergencyHistory: sl(),
        resolveEmergency: sl(),
        getEmergencyMessages: sl(),
        saveCustomMessage: sl(),
        activateEmergency: sl(),
      ));
}
