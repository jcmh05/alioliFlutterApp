import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'package:alioli/models/models.dart';
import 'package:alioli/database/database_helper.dart';
import 'package:alioli/components/components.dart';

class AlarmManagerService {
  final Log = logger(AlarmManagerService);
  static final AlarmManagerService _alarmManagerService = AlarmManagerService._internal();

  factory AlarmManagerService() {
    return _alarmManagerService;
  }

  AlarmManagerService._internal();

  Future<void> setupDailyAlarm() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final int expiryHour = prefs.getInt('expiryHour') ?? 12;
    final int expiryMinute = prefs.getInt('expiryMinute') ?? 0;

    final DateTime now = DateTime.now();
    DateTime alarmTime = DateTime(now.year, now.month, now.day, expiryHour, expiryMinute);

    if (alarmTime.isBefore(now)) {
      alarmTime = alarmTime.add(Duration(days: 1));
    }

    await AndroidAlarmManager.cancel(0);  // Cancelar cualquier alarma anterior
    await AndroidAlarmManager.oneShotAt(
      alarmTime,
      0,
      callback,
      exact: true,
      wakeup: true,
    );
    Log.i('Alarma diaria programada a las ' + alarmTime.toString());
  }

  @pragma('vm:entry-point')
  static Future<void> callback() async {
    final DateTime now = DateTime.now();
    print("Alarm fired at $now");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool activeNotifications = prefs.getBool('activeNotifications') ?? false;
    bool expiryDateNotifications = prefs.getBool("expiryDateNotifications") ?? true;

    print("Notificaciones activas: $activeNotifications, Notificaciones de caducidad: $expiryDateNotifications");

    if (activeNotifications && expiryDateNotifications) {
      print("Sending expiry notifications");
      await DataBaseHelper.instance.init();
      List<Ingredient> pantryItems = await IngredientDao().readAll('pantry') ?? [];
      List<Ingredient> alerts = [];

      final int daysBefore = prefs.getInt("dayNotification") ?? 1;
      for (var item in pantryItems) {
        DateTime expiryDate = item.date.subtract(Duration(days: daysBefore));
        if (sameDay(expiryDate, DateTime.now())) {
          alerts.add(item);
        }
      }

      if (alerts.isNotEmpty) {
        String alertBody = generateAlertBody(alerts, daysBefore);
        await NotificationService().showNotification("Aviso de caducidad⌛", alertBody);
      }
    }
  }

  static String generateAlertBody(List<Ingredient> alerts, int daysBefore) {
    String body = "";
    if (alerts.length == 1) {
      body += "El producto  ${alerts[0].name} caduca";
    } else if (alerts.length == 2) {
      body += "Los productos ${alerts[0].name} y ${alerts[1].name} caducan";
    } else {
      body += "Los productos ${alerts[0].name}, ${alerts[1].name} y otros caducan";
    }

    body += daysBefore > 1 ? " en $daysBefore días" : daysBefore == 1 ? " mañana" : " hoy";
    return body;
  }

  static bool sameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }
}

