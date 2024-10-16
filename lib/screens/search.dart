import 'dart:math';
import 'dart:ui';

import 'package:alioli/components/components.dart';
import 'package:alioli/models/models.dart';
import 'package:alioli/second_screens/second_screens.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fuzzy/fuzzy.dart';
class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin{

  // Diseño
  TabController? _tabController;
  bool viewList = false;

  // Variables
  List<Ingredient> _pantryIngredients = <Ingredient>[];
  List<String> _selectedIngredientIds = [];

  // Controladores
  final _ingredientSearchController = TextEditingController();
  final _searchController = TextEditingController();

  // Variables para crear un fondo estampado
  final int density = 4;
  final double width = 100.0;
  final double height = 100.0;
  List<Widget> svgWidgets = [];
  List<Offset> initialPositions = [];
  final List<String> svgAssets = [
    'assets/background/cheese0.svg',
    'assets/background/cherry0.svg',
    'assets/background/lemon0.svg',
    'assets/background/pear0.svg',
    'assets/background/pepper0.svg',
    'assets/background/tomato0.svg',
    'assets/background/onion0.svg',
    'assets/background/broccoli0.svg',
    'assets/background/pineapple0.svg',
    'assets/background/pepper1.svg',
    'assets/background/eggplant0.svg',
  ];

  @override
  void initState() {
    super.initState();
    initialList();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      generateSvgWidgets(); // Llama a la generación inicial después de construir el widget
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void generateSvgWidgets() {
    final size = MediaQuery.of(context).size;
    final int rowCount = sqrt(density * density).floor();
    final double baseSpacing = min(size.width, size.height) / rowCount;

    svgWidgets.clear();
    final random = Random();

    List<Offset> positions = [];

    while (positions.length < density * density) {
      double dx = random.nextDouble() * size.width;
      double dy = random.nextDouble() * size.height;

      // Asegurarse de que no esté demasiado cerca de otras posiciones
      bool tooClose = positions.any((pos) => (pos.dx - dx).abs() < baseSpacing && (pos.dy - dy).abs() < baseSpacing);
      if (!tooClose) {
        positions.add(Offset(dx, dy));
      }
    }

    for (int i = 0; i < positions.length; i++) {
      final dx = positions[i].dx;
      final dy = positions[i].dy;
      final assetIndex = i % svgAssets.length;
      final asset = svgAssets[assetIndex];
      final rotation = (random.nextDouble() * 0.4) - 0.2; // Rotación aleatoria entre -0.2 y 0.2 radianes

      svgWidgets.add(Positioned(
        left: dx - width / 2, // Centra el SVG horizontalmente en dx
        top: dy - height / 2, // Centra el SVG verticalmente en dy
        child: Transform.rotate(
          angle: rotation,
          child: SvgPicture.asset(
            asset, width: width, height: height,
            color: MediaQuery.of(context).platformBrightness == Brightness.dark ? Color(0xFF252424) : Color(0xFFF8F8F8),
          ),
        ),
      ));
    }
  }

  Widget buildIngredientSuggestions() {
    var fuse = Fuzzy(globalIngredients.map((ingredient) => ingredient.name).toList(), options: FuzzyOptions(isCaseSensitive: false, shouldSort: true));
    var results = fuse.search(_ingredientSearchController.text);
    var filteredIngredients = results.map((result) => globalIngredients.firstWhere((ingredient) => ingredient.name == result.item)).toList();
    return Container(
      height: 250.0,
      child: ListView(
        children: filteredIngredients.map((ingredient) {
          return ListTile(
            leading: SvgPicture.asset(
              'assets/ingredients/${ingredient.icon}.svg',
              height: 30.0,
            ),
            title: Text(
              ingredient.head ? ingredient.name + ' (Cualquiera)' : ingredient.name,
            ),
            onTap: () {
              setState(() {
                _selectedIngredientIds.add(ingredient.id);
                viewList = false;
                _ingredientSearchController.clear();
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget buildSelectedIngredients() {
    List<Widget> chips = [];

    for (int i = 0; i < _selectedIngredientIds.length; i++) {
      Ingredient ingredient = globalIngredients.firstWhere((ingredient) => ingredient.id == _selectedIngredientIds[i]);

      chips.add(
        Chip(
          avatar: SvgPicture.asset(
            'assets/ingredients/${ingredient.icon}.svg',
            height: 30.0,
          ),
          label: Text(
            '${ingredient.name}',
          ),
          onDeleted: () {
            setState(() {
              _selectedIngredientIds.removeAt(i);
            });
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
      );
    }

    return Container(
      height: 250.0,
      decoration: BoxDecoration(
        color: _selectedIngredientIds.length > 0 ? Theme.of(context).brightness == Brightness.dark ? Color(0xFF1C1C1C) : Colors.white : Colors.transparent,
        border: Border.all(
          color: _selectedIngredientIds.length > 0 ? Colors.grey : Colors.transparent,
          width: _selectedIngredientIds.length > 0 ? 1.0 : 0.0,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ( _selectedIngredientIds.length > 0)
        // Construye la vista de los ingredientes seleccionados
        ? Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ingredientes seleccionados:',
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _selectedIngredientIds.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
              if ( _selectedIngredientIds.length > 30 )
                Text(
                  _selectedIngredientIds.length.toString() + ' / 30',
                ),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.start,
                    alignment: WrapAlignment.start,
                    runAlignment: WrapAlignment.start,
                    spacing: 8.0,  // Espacio entre chips
                    runSpacing: 4.0,  // Espacio entre filas
                    children: chips,
                  ),
                ),
              ),
            ],
          )
        // Construye la vista por defecto
        : Button3d(
        height: 120.0,
        width: double.infinity,
        style: Button3dStyle(
            borderRadius: BorderRadius.circular(12),
            topColor: AppTheme.pantry,
            backColor: AppTheme.pantry_second,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 8.0,),
            SvgPicture.asset(
              'assets/pantry.svg',
              fit: BoxFit.contain,
              height: 60.0,
            ),
            SizedBox(height: 8.0,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                'Usar ingredientes de la despensa',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        onPressed:() {
          for (int i = 0; i < _pantryIngredients.length; i++) {
            if (!_selectedIngredientIds.contains(_pantryIngredients[i].id)) {
              _selectedIngredientIds.add(_pantryIngredients[i].id);
            }
          }
          setState(() {});
        },
      )
    );
  }

  void initialList() async {
    _pantryIngredients = await IngredientDao().readAll('pantry');
  }

  @override
  Widget build(BuildContext context) {
    double appWidth = MediaQuery.of(context).size.width;
    double appHeight = MediaQuery.of(context).size.height;


    Widget buildIngredientInput() {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ingredientSearchController,
                  decoration: InputDecoration(
                    fillColor: Theme.of(context).brightness == Brightness.dark ? Color(0xFF1C1C1C) : Colors.white,
                    filled: true,
                    prefixIcon: Icon(FontAwesomeIcons.carrot, color: AppTheme.pantry),
                    hintText: 'Buscar ingredientes',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30.0)),
                    ),
                  ),
                  onTapOutside: (event) {
                    viewList = false;
                  },
                  onEditingComplete: () {
                    viewList = false;
                  },
                  onChanged: (value) {
                    if (value == '') {
                      viewList = false;
                    } else {
                      viewList = true;
                    }
                    setState(() {});
                  },
                ),
              ),
              SizedBox(width: 10.0,),
              // BOTON INGRREDIENTES
              if ( _selectedIngredientIds.length > 0 )
                Button3d(
                  width: 60.0,
                  height: 60.0,
                  style: Button3dStyle(
                      topColor: AppTheme.pantry,
                      backColor: AppTheme.pantry_second,
                      borderRadius: BorderRadius.all(Radius.circular(10))
                  ),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1.3,
                      child: SvgPicture.asset(
                        'assets/pantry.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  onPressed: () {
                    for (int i = 0; i < _pantryIngredients.length; i++) {
                      if (!_selectedIngredientIds.contains(_pantryIngredients[i].id)) {
                        _selectedIngredientIds.add(_pantryIngredients[i].id);
                      }
                    }
                    setState(() {});
                  },
                ),
            ],
          ),
        ],
      );
    }

    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          toolbarHeight: 80.0,
          title: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TabBar(
              labelColor: AppTheme.pantry,
              indicatorColor: AppTheme.pantry_second,
              controller: _tabController,
              tabs: [
                Tab(
                  child: Column(
                    children: [
                      Text('Ingredientes', style: TextStyle(fontSize: 17.0,fontWeight: FontWeight.bold),),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    children: [
                      Text('Nombre de Receta', style: TextStyle(fontSize: 17.0,fontWeight: FontWeight.bold),),
                    ],
                  ),
                ),
              ],
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Stack(
                      children: [
                        ...svgWidgets,
                        Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: 20.0,),
                            buildIngredientInput(),
                            SizedBox(height: 20.0,),
                            if (viewList)
                              buildIngredientSuggestions(),
                            if (!viewList)
                              buildSelectedIngredients(),
                            if ( _selectedIngredientIds.length > 30 )
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text('Sólo se buscarán los primeros 30 ingredientes'),
                                  ),
                                ],
                              ),
                            Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 40.0),
                              child: Rounded3dButton('Buscar recetas', AppTheme.pantry, AppTheme.pantry_second, icon: Icons.search, height: 60.0,
                                      (){
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => SearchResults(title: "Buscar por Ingredientes",ingredientsId: _selectedIngredientIds)));
                                  }
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Stack(
                      children: [
                        ...svgWidgets,
                        Center(
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  onSubmitted: (value) {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => SearchResults(title: "Resultados para '$value'",recipeName: value)));
                                  },
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    fillColor: Theme.of(context).brightness == Brightness.dark ? Color(0xFF1C1C1C) : Colors.white,
                                    filled: true,
                                    labelText: "Buscar",
                                    labelStyle: TextStyle(color: Colors.grey),
                                    hintText: "Tortilla, Burritos, etc.",
                                    prefixIcon: Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(15.0)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.green, width: 2.0),
                                      borderRadius: BorderRadius.all(Radius.circular(15.0)),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.0,),
                              Button3d(
                                width: 60.0,
                                height: 60.0,
                                style: Button3dStyle(
                                    topColor: AppTheme.pantry,
                                    backColor: AppTheme.pantry_second,
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                ),
                                child: Center(
                                  child: Icon(Icons.search, color: Colors.white,),
                                ),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => SearchResults(title: "Resultados para '" + _searchController.text + "'",recipeName: _searchController.text)));
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
