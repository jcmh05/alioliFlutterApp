import 'package:alioli/second_screens/second_screens.dart';
import 'package:alioli/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:alioli/screens/screens.dart';
import 'package:alioli/components/components.dart';
import 'package:alioli/provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

class Alioli extends StatelessWidget {
  final bool isLogged;
  const Alioli({Key? key, required this.isLogged}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(lazy: false,create: (_) => LoginProvider()),
        ChangeNotifierProvider(lazy: false,create: (_) => RegisterProvider()),
      ],
      child: MaterialApp(
        title: 'Alioli',
        theme: AppTheme.claro(),
        darkTheme: AppTheme.oscuro(),
        themeMode: ThemeMode.system,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'),
        ],
        home: isLogged ? MainScreen() : LocalStorage().getIsFirstTime() ? OverboardScreen() : LoginScreen(),
      ),
    );
  }
}
