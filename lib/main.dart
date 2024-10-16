import 'package:alioli/models/models.dart';
import 'package:alioli/services/local_storage.dart';
import 'package:alioli/services/push_notification.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:alioli/screens/main_screen.dart';
import 'package:alioli/alioli.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'database/database_helper.dart';
import 'package:alioli/components/components.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const double VERSION = 2;

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  final Log = logger(MainScreen);

  // Inicializa el SDK de AdMob
  MobileAds.instance.initialize();

  // Inicializa el formato de fecha
  Intl.defaultLocale = 'es_ES';
  await initializeDateFormatting('es_ES', null);

  // Inicializa la base de datos sqflite
  await DataBaseHelper.instance.init();

  // Inicializa el servicio de notificaciones
  await PushNotificationService.initializeApp();

  // Inicializa Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializa timezone
  tz.initializeTimeZones();

  // Inicializa el servicio de notificaciones
  await NotificationService().init();

  // Inicializa el AndroidAlarmManager para programar notificaciones
  await AndroidAlarmManager.initialize();

  // Registra el callback
  await AndroidAlarmManager.oneShotAt(
    DateTime.now().add(Duration(seconds: 5)),
    0,
    AlarmManagerService.callback,
    exact: true,
    wakeup: true,
  );

  // Configura la alarma diaria
  await AlarmManagerService().setupDailyAlarm();

  // Bloquea la orientación a vertical
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicializa el almacenamiento local de Hive
  await LocalStorage().init();
  final String name = LocalStorage().getEmail();
  final isLogged = LocalStorage().getIsLoggedIn();


  // Comprueba si la versión actual es superior a la última versión guardada
  if (LocalStorage().getVersion() < VERSION) {
    Log.d('La aplicación se ha actualizado de la versión ' + LocalStorage().getVersion().toString()  + ' a la versión $VERSION.');

    // Actualizar lista de ingredientes a la nueva versión
    await DataBaseHelper.instance.reloadIngredients();

    LocalStorage().setVersion(VERSION);
  }

  Log.i('Iniciando la aplicación con el usuario:\n  name:' + name + "\n  isLogged: " + isLogged.toString());
  runApp(Alioli(isLogged: isLogged));

}
