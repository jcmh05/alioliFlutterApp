import 'package:alioli/alioli.dart';
import 'package:alioli/components/components.dart';
import 'package:alioli/services/local_storage.dart';
import 'package:flutter_overboard/flutter_overboard.dart';
import 'package:flutter/material.dart';

class OverboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OverBoard(
        pages: _getPages(),
        showBullets: true,
        nextText: 'SIGUIENTE',
        skipText: 'SALTAR',
        finishText: 'EMPEZAR',
        finishCallback: () {
          LocalStorage().setIsFirstTime(false);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => Alioli(isLogged: false)),
                (Route<dynamic> route) => false,
          );
        },
      ),
    );
  }

  List<PageModel> _getPages() {
    return [
      PageModel(
          color: AppTheme.pantry,
          imageAssetPath: 'assets/overboard2.png',
          title: 'Bienvenid@ a Alioli',
          body: 'Descubre una nueva forma de gestionar tus ingredientes y recetas.',
          doAnimateImage: true),
      PageModel(
          color: Colors.orangeAccent,
          imageAssetPath: 'assets/overboard4.png',
          title: 'Descubre nuevas recetas',
          body: 'Encuentra justo la receta que necesitas para cada momento.',
          doAnimateImage: true),
      PageModel(
          color: AppTheme.basket,
          imageAssetPath: 'assets/overboard3.png',
          title: 'Evita el desperdicio de alimentos',
          body: 'Recibe notificaciones cuando un alimento esté próximo a caducar',
          doAnimateImage: true),
      PageModel(
          color: AppTheme.pantry,
          imageAssetPath: 'assets/overboard1.png',
          title: 'Alioli',
          body: 'Crea una cuenta nueva o inicia sesión para comenzar.',
          doAnimateImage: true),
    ];
  }
}