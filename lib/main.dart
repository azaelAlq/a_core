import 'package:a_core/core/app_theme.dart';
import 'package:a_core/core/routes/app_router.dart';
import 'package:a_core/features/auth/presentation/provider/auth_provider.dart';
import 'package:a_core/features/diario/presentation/provider/diary_provider.dart';
import 'package:a_core/features/finanzas/presentation/provider/finanzas_provider.dart';
import 'package:a_core/features/gastos/presentation/provider/gastos_provider.dart';
import 'package:a_core/features/gym/presentation/provider/gym_provider.dart';
import 'package:a_core/features/libretas/presentation/provider/libretas_provider.dart';
import 'package:a_core/features/logros/presentation/provider/logros_provider.dart';
import 'package:a_core/features/sistemas/presentation/provider/sistemas_provider.dart';
import 'package:a_core/features/user/presentation/provider/user_provider.dart';
import 'package:a_core/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('es', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => DiaryProvider()),
        ChangeNotifierProvider(create: (_) => LogrosProvider()),
        ChangeNotifierProvider(create: (_) => FinanzasProvider()),
        ChangeNotifierProvider(create: (_) => GastosProvider()),
        ChangeNotifierProvider(create: (_) => LibretasProvider()),
        ChangeNotifierProvider(create: (_) => SistemasProvider()),
        ChangeNotifierProvider(create: (_) => GymProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(context);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver a primer plano sincroniza los registros capturados desde
    // los widgets del inicio (sin esto solo se sincronizaban al arrancar).
    if (state == AppLifecycleState.resumed) {
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid != null) {
        context.read<GastosProvider>().init(uid);
        context.read<FinanzasProvider>().init(uid);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userProv = context.read<UserProvider>();
      if (auth.user != null) {
        userProv.watchUser(auth.user!.uid);
        // Sincroniza registros capturados desde los widgets del inicio y
        // actualiza los resúmenes que éstos muestran.
        context.read<GastosProvider>().init(auth.user!.uid);
        context.read<FinanzasProvider>().init(auth.user!.uid);
      } else {
        userProv.stopWatching();
      }
    });

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: _router,
    );
  }
}
