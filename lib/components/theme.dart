import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {

  static Color pantry = Color(0xFF54b362);
  static Color pantry_second = Color(0xFF3d8249);
  static Color pantry_third = Color(0x8067dc78);
  static Color basket = Color(0xFF207c9e);
  static Color basket_second = Color(0xFF17566e);
  static Color basket_third = Color(0x7c2ba3d0);
  static Color grey1 = Color(0xFFededed);
  static Color grey2 = Color(0xFFe0e0e0);
  static Color black1 = Color(0xFF363636);
  static Color black2 = Color(0xFF262626);
  static Color googleButtonColor = Color(0xFF4285F4);
  static Color googleButtonSecondColor = Color(0xFF3B5998);

  // Definir las listas de iconos, colores y nombres en español
  static Map<String, IconData> categoryIcons = {
    'breakfast': Icons.breakfast_dining,
    'lunch': Icons.lunch_dining,
    'dinner': Icons.dinner_dining,
    'snack': FontAwesomeIcons.cookieBite,
    'appetizer': Icons.fastfood,
    'dessert': Icons.cake,
    'vegan': FontAwesomeIcons.leaf,
    'vegetarian': FontAwesomeIcons.seedling,
    'healthy': Icons.favorite,
    'high-protein': Icons.fitness_center,
    'low-fat': FontAwesomeIcons.droplet,
    'low-carb': FontAwesomeIcons.bowlFood,
    'low-calories': Icons.no_meals,
    'high-fiber': FontAwesomeIcons.wheatAwn,
    'halal': FontAwesomeIcons.mosque,
    'american': Icons.flag,
    'chinese': Icons.flag,
    'spanish': Icons.flag,
    'french': Icons.flag,
    'indian': Icons.flag,
    'italian': Icons.flag,
    'japanese': Icons.flag,
    'mexican': Icons.flag,
    'thai': Icons.flag,
    'turkish': Icons.flag,
    'argentine': Icons.flag,
    'greek': Icons.flag,
  };

  static Map<String, Color> categoryColors = {
    'breakfast': Color(0xffffab91),  //
    'lunch': Color(0xffffef6f),      //
    'dinner': Color(0xffffd54f),     //
    'snack': Color(0xff74e174),      //
    'appetizer': Color(0xffe6ef7c),  //
    'dessert': Color(0xfff8bbd0),    //
    'vegan': Color(0xffb2ff59),      //
    'vegetarian': Color(0xffc7ff85), //
    'healthy': Color(0xffe7a6a6),    //
    'high-protein': Color(0xffb3e5fc),//
    'low-fat': Color(0xffb2dfdb),    //
    'low-carb': Color(0xffd1c4e9),   //
    'low-calories': Color(0xffb2ebf2),//
    'high-fiber': Color(0xff909ad9), //
    'halal': Color(0xffd59476),      //
    'american': Color(0xffbbdefb),   //
    'chinese': Color(0xffffccbc),    //
    'spanish': Color(0xffff8181),    //
    'french': Color(0xffb3e5fc),     //
    'indian': Color(0xffffab91),     //
    'italian': Color(0xffffe082),    //
    'japanese': Color(0xff80deea),   //
    'mexican': Color(0xffffd54f),    //
    'thai': Color(0xffdcedc8),       //
    'turkish': Color(0xffffcdd2),    //
    'argentine': Color(0xffb2dfdb),  //
    'greek': Color(0xffb2ebf2),      //
  };


  static Map<String, String> categoryNames = {
    'breakfast': 'Desayuno',
    'lunch': 'Almuerzo',
    'dinner': 'Cena',
    'snack': 'Merienda',
    'appetizer': 'Aperitivo',
    'dessert': 'Postre',
    'vegan': 'Vegano',
    'vegetarian': 'Vegetariano',
    'healthy': 'Saludable',
    'high-protein': 'Alto en proteínas',
    'low-fat': 'Bajo en grasas',
    'low-carb': 'Bajo en calorías',
    'low-calories': 'Alto en calorías',
    'high-fiber': 'Alto en fibra',
    'halal': 'Halal',
    'american': '🇺🇸 Americana',
    'chinese': '🇨🇳 China',
    'spanish': '🇪🇸 Española',
    'french': '🇫🇷 Francesa',
    'indian': '🇮🇳 India',
    'italian': '🇮🇹 Italiana',
    'japanese': '🇯🇵 Japonesa',
    'mexican': '🇲🇽 Mexicana',
    'thai': '🇹🇭 Tailandesa',
    'turkish': '🇹🇷 Turca',
    'argentine': '🇦🇷 Argentina',
    'greek': '🇬🇷 Griega',
  };

  static Map<String, IconData> listIconsList = {
    '0': Icons.favorite_border_outlined,
    '1': Icons.turned_in_not,
    '2': Icons.star_border,
    '3': Icons.local_fire_department_outlined,
    '4': Icons.access_time,
    '5': Icons.local_mall_outlined,
    '6': Icons.local_bar_outlined,
    '7': Icons.local_pizza_outlined,
    '8': Icons.local_cafe_outlined,
    '9': Icons.bakery_dining_outlined,
    '10': Icons.fitness_center_sharp,
    '11': Icons.bedtime_outlined,
    '12': Icons.celebration_outlined,
    '13': Icons.chair_outlined,
    '14': Icons.dinner_dining,
    '15': Icons.bed_outlined,
    '16': Icons.kitchen,
    '17': FontAwesomeIcons.seedling,
    '18': Icons.blender_outlined,
    '19': Icons.local_dining,
    '20': Icons.cases_outlined,
    '21': Icons.campaign_outlined,
    '22': Icons.local_grocery_store,
    '23': Icons.soup_kitchen_outlined,
  };


  static TextTheme temaTextoClaro = TextTheme(
    bodyLarge: GoogleFonts.openSans(
      fontSize: 14.0,
      fontWeight: FontWeight.w700,
      color: Colors.black,
    ),
    displayLarge: GoogleFonts.openSans(
      fontSize: 32.0,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    displayMedium: GoogleFonts.openSans(
      fontSize: 21.0,
      fontWeight: FontWeight.w700,
      color: Colors.black,
    ),
    displaySmall: GoogleFonts.openSans(
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
    titleLarge: GoogleFonts.openSans(
      fontSize: 20.0,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
  );

  static TextTheme temaTextoOscuro = TextTheme(
    bodyLarge: GoogleFonts.openSans(
      fontSize: 14.0,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    displayLarge: GoogleFonts.openSans(
      fontSize: 32.0,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    displayMedium: GoogleFonts.openSans(
      fontSize: 21.0,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    displaySmall: GoogleFonts.openSans(
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    titleLarge: GoogleFonts.openSans(
      fontSize: 20.0,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  );

  static ThemeData claro() {
    Color BackgroundColor = Colors.white;
    return ThemeData(
      brightness: Brightness.light,
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateColor.resolveWith((states) {
          return Colors.black;
        },
        ),
      ),
      scaffoldBackgroundColor: Colors.white,
      cardColor: Colors.white,
      dividerColor: Colors.black,
      appBarTheme: const AppBarTheme(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButtonTheme: const
      FloatingActionButtonThemeData(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
      ),
      bottomNavigationBarTheme: const
      BottomNavigationBarThemeData(
        selectedItemColor: Colors.green,
      ),
      textTheme: temaTextoClaro,
    );
  }

  static ThemeData oscuro() {
    Color BackgroundColor = Color(0xFF1C1C1C);
    return ThemeData(
      brightness: Brightness.dark,
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateColor.resolveWith((states) {
          return Colors.white;
        },
        ),
      ),
      scaffoldBackgroundColor: BackgroundColor,
      cardColor: BackgroundColor,
      dividerColor: Colors.white,
      appBarTheme: const AppBarTheme(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black26,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: BackgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButtonTheme: const
      FloatingActionButtonThemeData(
        foregroundColor: Colors.white,
        backgroundColor: Colors.green,
      ),
      bottomNavigationBarTheme: const
      BottomNavigationBarThemeData(
        selectedItemColor: Colors.green,
      ),
      textTheme: temaTextoOscuro,
    );

  }
}