import 'package:flutter/material.dart';
import 'package:alioli/components/components.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:day_night_time_picker/day_night_time_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Log = logger(NotificationsScreen);
  final double _separatorHeight = 25.0;
  bool _activeNotifications = false;
  bool _expiryDateNotifications = false;
  int _expiryHour = 12;
  int _expirtyMinute = 0;
  int _dayNotification = 1;

  void loadPreferences() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _activeNotifications = prefs.getBool("activeNotifications") ?? false;
      _expiryDateNotifications = prefs.getBool("expiryDateNotifications") ?? true;
      _expiryHour = prefs.getInt('expiryHour') ?? 12;
      _expirtyMinute = prefs.getInt('expiryMinute') ?? 0;
      _dayNotification = prefs.getInt("dayNotification") ?? 1;
    });
  }

  void setActiveNotifications2(bool value) async{
    setState(() {
      _activeNotifications = value;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("activeNotifications", value);
  }

  void setGeneralNotifications(bool value) async{
    var status = await Permission.notification.status;
    var statusExactAlarm = await Permission.scheduleExactAlarm.status;
    if (!status.isGranted) {
      final result = await Permission.notification.request();
      if (result.isGranted) {
        Log.i('Permiso notificaciones concedido');
        setActiveNotifications2(value);
      } else if( status.isPermanentlyDenied) {
        Log.e('Permiso notificaciones bloqueado');
        mostrarMensaje('Habilita el permiso de notificaciones primero');
        openAppSettings();
      } else {
        Log.e('Permiso notificaciones rechazado');
        mostrarMensaje('Habilita el permiso de notificaciones primero');
        openAppSettings();
      }
    }else{
      setActiveNotifications2(value);
    }
  }

  void setExpiryDateNotifications(bool value) async{
    setState(() {
      _expiryDateNotifications = value;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("expiryDateNotifications", value);
  }

  void setExpiryHour(Time time) async{
    setState(() {
      _expiryHour = time.hour;
      _expirtyMinute = time.minute;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("expiryHour", _expiryHour);
    prefs.setInt("expiryMinute", _expirtyMinute);

    await AlarmManagerService().setupDailyAlarm();
  }

  void setDayNotification(int days) async{
    setState(() {
      _dayNotification = days;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("dayNotification", days);
  }

  @override
  void didChangeDependencies() {
    loadPreferences();
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
  }

  Widget textOption(String title, String? description){
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Theme.of(context).dividerColor
            ),
          ),
          if ( description != null)
            Text(
              description,
              softWrap: true,
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

  Widget generalOption(String title, String? description,bool optionValue,Function action){
    return InkWell(
      onTap: (){
        action(!optionValue);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          textOption(title, description),
          Switch(
            value: optionValue,
            activeColor: Colors.white,
            activeTrackColor: Color(0xff00c723),
            inactiveTrackColor: Colors.transparent,
            onChanged: (value) {
              action(value);
            },
          ),
        ],
      ),
    );
  }

  Widget optionHour(){
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          showPicker(
            context: context,
            disableMinute: false,
            minuteInterval: TimePickerInterval.ONE,
            value: Time(hour: _expiryHour,minute: _expirtyMinute),
            sunrise: TimeOfDay(hour: 6, minute: 0),
            sunset: TimeOfDay(hour: 18, minute: 0),
            is24HrFormat: true,
            onChange: (p0) { setExpiryHour(p0);},
          ),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          textOption('Hora', null),
          Text(
            formatHour(Time(hour: _expiryHour, minute: _expirtyMinute)),
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.grey,
            ),
          )
        ],
      ),
    );
  }

  Widget optionDays(){
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          showPicker(
            context: context,
            disableHour: true,
            value: Time(hour: _expiryHour,minute: 0),
            sunrise: TimeOfDay(hour: 6, minute: 0),
            sunset: TimeOfDay(hour: 18, minute: 0),
            is24HrFormat: true,
            isInlinePicker: true,
            onChange: (p0) { setExpiryHour(p0);},
          ),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          textOption('Día', null),
          DropdownButton<int>(
            value: _dayNotification,
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.grey,
            ),
            underline: Container(
              height: 2,
              color: Colors.transparent,
            ),
            onChanged: (int? newValue) {
              setDayNotification(newValue ?? 1);
            },
            items: <int>[0, 1, 2, 3, 4, 5, 6, 7]
                .map<DropdownMenuItem<int>>((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text(
                  value == 0 ? 'El mismo día' :
                  '${value} día${value == 1 ? '' : 's'} antes',
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget infoOption(String title, String? description){
    return InkWell(
      onTap: (){
        Uri help = Uri.parse('https://alioliapp.github.io/home/notifications');
        launchUrl(help);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          textOption(title, description),
          Icon(
            Icons.help_outline,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget divider(){
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 15.0),
      child: Divider(
        thickness: 1.0,
      ),
    );
  }

  String formatHour(Time time){
    var hora = time.hour<10 ? '0'+time.hour.toString() : time.hour.toString();
    var minuto = time.minute<10 ? '0'+time.minute.toString() : time.minute.toString();

    return hora+':'+minuto;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_activeNotifications ? 'Notificaciones 🔔' : 'Notificaciones 🔕'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(15.0),
        child: Column(
          children: [
            generalOption('Mostrar Notificaciones',null,_activeNotifications,setGeneralNotifications),
            divider(),
            if (_activeNotifications)
              Column(
                children: [
                  generalOption('Caducidad', 'Recibe un aviso cuando un producto esté próximo a su fecha de caducidad',_expiryDateNotifications,setExpiryDateNotifications),
                  if( _expiryDateNotifications )
                    Column(
                      children: [
                        SizedBox(height: _separatorHeight,),
                        optionHour(),
                        SizedBox(height: _separatorHeight,),
                        optionDays(),
                      ],
                    ),
                  divider(),
                  infoOption('Ayuda', '¿Qué hago si no recibo notificaciones?'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
