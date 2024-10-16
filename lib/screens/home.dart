import 'package:flutter/material.dart';
import 'package:alioli/components/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:alioli/second_screens/basket_screen.dart';
import 'package:alioli/second_screens/pantry_screen.dart';
import 'package:provider/provider.dart';
import 'package:alioli/provider/provider.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool pantry = true; // Determina si se debe mostrar la despensa o la cesta

  @override
  Widget build(BuildContext context) {
    double appHeight = MediaQuery.of(context).size.height * 0.2; // Altura relativa para los elementos de la pantalla
    double appWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        // Barra principal con los botones superiores
          appBar: AppBar(
            toolbarHeight: appHeight,
            title: Row(
              // Posicionamiento de los botones en la fila
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Botones de la barra
                Button3d(
                  height: appHeight*0.8,// La altura de los botones será el 90% de la del AppBar
                  width: appWidth * 0.4,
                  style: Button3dStyle(
                      topColor: pantry ? AppTheme.pantry : Color(0xFF858585),
                      backColor: pantry ? AppTheme.pantry_second : Color(0xFF686869),
                      borderRadius: BorderRadius.all(Radius.circular(10))
                  ),
                  onPressed: () {
                    if( pantry != true){
                      setState(() {
                        pantry = true;
                      });
                    }
                  },
                  child: Column(
                    // Posicionamiento de los elementos dentro del botón
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Elementos del botón
                      SvgPicture.asset(
                          pantry ? 'assets/pantry.svg' : 'assets/pantry_gray.svg',
                          height: appHeight * 0.5
                      ),
                      Text(
                        'Despensa',
                        style: TextStyle(
                          color: pantry ? Colors.white : Color(0xFFCECECE),
                          fontSize: appHeight * 0.14, // Tamaño del texto relativo al botón
                        ),
                      ),
                    ],
                  ),
                ),
                Button3d( // Botón despensa
                  height: appHeight*0.8,
                  width: appWidth * 0.4,
                  style: Button3dStyle(
                      topColor: pantry ? Color(0xFF858585) : AppTheme.basket,
                      backColor: pantry ? Color(0xFF686869) : AppTheme.basket_second,
                      borderRadius: BorderRadius.all(Radius.circular(10))
                  ),
                  onPressed: () {
                    if (pantry != false){
                      setState(() {
                        pantry = false;
                      });
                    }
                  },
                  child: Column(
                    // Posicionamiento de los elementos dentro del botón
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Elementos del botón
                      SvgPicture.asset(
                          pantry ? 'assets/basket_gray.svg' : 'assets/basket.svg',
                          height: appHeight * 0.5
                      ),
                      Text(
                        'Cesta',
                        style: TextStyle(
                          color: pantry ? Color(0xFFCECECE) : Colors.white,
                          fontSize: appHeight * 0.14, // Tamaño del texto relativo al botón
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,

          ),
          body: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (context) => BasketListProvider()),
              ChangeNotifierProvider(create: (context) => PantryListProvider()),
            ],
            child:  pantry ? PantryScreen() : BasketScreen(),
          )
      ),
    );
  }
}

