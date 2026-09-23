import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'screens/auth_screens.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'data/local_db.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await LocalDb.instance.init();
  runApp(const TitanFitApp());
}

class TitanFitApp extends StatelessWidget {
  const TitanFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'TitanFit',
        debugShowCheckedModeBanner: false,
        theme: TitanTheme.dark(),
        home: const SplashScreen(),
      ),
    );
  }
}
