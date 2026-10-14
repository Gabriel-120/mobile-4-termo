import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'services/local_service.dart';
import 'screens/mapa_screen.dart';
import 'dialogs/account_dialog.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MapaApp());
}

class MapaApp extends StatelessWidget {
  const MapaApp({super.key, this.home});
  final Widget? home;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Mapa de Locais',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: paper,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ink,
        primary: ink,
        surface: paper,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE5E9E3)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDCE2DC)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    ),
    home: home ?? const Bootstrap(),
  );
}

class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});
  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  late Future<Session> pending;
  static bool initialized = false;
  @override
  void initState() {
    super.initState();
    pending = start();
  }

  Future<Session> start() async {
    if (!initialized) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (const bool.fromEnvironment('USE_EMULATORS')) {
        const host = String.fromEnvironment(
          'EMULATOR_HOST',
          defaultValue: '10.0.2.2',
        );
        await FirebaseAuth.instance.useAuthEmulator(host, 9199);
        FirebaseFirestore.instance.useFirestoreEmulator(host, 8180);
      }
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
      );
      initialized = true;
    }
    return Session.iniciar().timeout(const Duration(seconds: 25));
  }

  Future<void> account(Session session) async {
    final refresh = await showAccount(context, session);
    if (refresh == true && mounted) setState(() => pending = start());
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Session>(
    future: pending,
    builder: (context, s) {
      if (s.hasData) {
        return MapaScreen(
          key: ValueKey('${s.data!.uid}-${s.data!.admin}'),
          repository: LocalService(),
          session: s.data!,
          account: () => account(s.data!),
        );
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Mapa de Locais')),
        body: LoadState(
          error: s.error,
          retry: () => setState(() => pending = start()),
        ),
      );
    },
  );
}
