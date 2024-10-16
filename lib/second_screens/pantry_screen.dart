import 'package:flutter/material.dart ';
import 'package:fuzzy/fuzzy.dart';
import 'package:provider/provider.dart';
import 'package:checkmark/checkmark.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

import 'second_screens.dart';
import 'package:alioli/provider/provider.dart';
import 'package:alioli/components/components.dart';


class PantryScreen extends StatelessWidget {
  const PantryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<PantryListProvider>(context, listen: false);
    final _key = GlobalKey<ExpandableFabState>();

    return Scaffold(
      body: buildScreen(context),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton:  ExpandableFab(
        key: _key,
        distance: 70.0,
        overlayStyle: ExpandableFabOverlayStyle(
          blur: 5,
        ),
        type: ExpandableFabType.up,
        openButtonBuilder: RotateFloatingActionButtonBuilder(
          child: const Icon(Icons.add),
          backgroundColor: AppTheme.pantry,
        ),
        closeButtonBuilder: RotateFloatingActionButtonBuilder(
          child: const Icon(Icons.close),
          backgroundColor: AppTheme.pantry_third,
        ),
        children: [
          // ADD INGREDIENT BUTTON
          FloatingActionButton(
            backgroundColor: AppTheme.pantry,
            child: const Icon(Icons.edit,size: 27.0,),
            onPressed: () {
              final state = _key.currentState;
              if( state != null){
                state.toggle();
              }
              showBarModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  child: AddIngredientScreen(
                    pantry: true,
                    crearProducto: (ingredient) {
                      manager.addIngredient(ingredient);
                      Navigator.pop(context);
                    },
                    editarProducto: (ingredient) { },
                  ),
                ),
              );
            },
          ),
          // BARCODE BUTTON
          FloatingActionButton(
            backgroundColor: AppTheme.pantry,
            child: const Icon(FontAwesomeIcons.barcode,size: 27.0,),
            onPressed: () {
              // Se cierra el menú de botones
              final state = _key.currentState;
              if( state != null){
                state.toggle();
              }
              // Navega hasta la pantalla de escaneo
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => BarcodeScreen(
                        dynamicMode: true,
                        crearProducto: (ingredient) {
                          // Devuelve un alert dialog para elegir entre los posibles productos que coincidan con el nombre
                          showDialog(
                              context: context,
                              builder: (context) {
                                return IngredientSelectionDialog(ingredient: ingredient, manager: manager);
                              }
                          );
                        },
                      )
                  )
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildScreen(BuildContext context) {
    return Consumer<PantryListProvider>(
      builder: (context, manager, child) {
        if (manager.ingredients.isNotEmpty) {
          return ListPantryScreenFull(pantryList: manager);
        } else {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              placeholderIconText(context,'assets/pantry_empty.svg',"No hay productos todavía","Toca el botón + para añadir",1),
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            ],
          );
        }
      },
    );
  }

}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////LISTA LLENA/////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class ListPantryScreenFull extends StatefulWidget {
  const ListPantryScreenFull({Key? key, required this.pantryList}) : super(key:
  key);
  final PantryListProvider pantryList;

  @override
  State<ListPantryScreenFull> createState() => _ListPantryScreenFullState();
}

class _ListPantryScreenFullState extends State<ListPantryScreenFull> {
  String selectedOption = 'DEFECTO';
  bool seeDateExpiry = true;

  void load_preferences() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String option = prefs.getString('selectedOptionPantry') ?? 'DEFECTO';
    bool seeDate = prefs.getBool("seeDateExpiry") ?? true;
    setState(() {
      selectedOption = option;
      seeDateExpiry = seeDate;
    });
  }

  void updateDate() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("seeDateExpiry", !seeDateExpiry);
    setState(() {
      seeDateExpiry = !seeDateExpiry;
    });
  }

  void updateSelectedOption(String value) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedOptionPantry', value);
    setState(() {
      selectedOption = value;
    });
  }

  @override
  void didChangeDependencies() {
    load_preferences();
    super.didChangeDependencies();
  }



  @override
  Widget build(BuildContext context) {
    double appWidth = MediaQuery.of(context).size.width;

    var ingredients = widget.pantryList.ingredients;

    if (selectedOption == "ABC") {
      ingredients = List.from(ingredients)..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if( selectedOption == "Caducidad" ) {
      ingredients = List.from(ingredients)..sort((a, b) => a.date.compareTo(b.date));
    } else{
      ingredients = ingredients;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Container para el check de caducidad
                GestureDetector(
                  onTap: () {
                    updateDate();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: Colors.grey,
                        style: BorderStyle.solid,
                      ),
                      color: seeDateExpiry ? Color(0x5fa8e5b1) :
                      Colors.transparent,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          SizedBox(
                            height: 15,
                            width: 15,
                            child: CheckMark(
                              active: seeDateExpiry,
                              curve: Curves.decelerate,
                              duration: const Duration(milliseconds: 500),
                            ),
                          ),
                          SizedBox(width: 10.0),
                          Text(
                            'Mostrar caducidad',
                            style: TextStyle(
                              fontSize: appWidth * 0.045
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                Spacer(),
                // Seleccionar orden
                Container(
                  padding: EdgeInsets.only(left: 10.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: Colors.grey,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedOption,
                      items: [
                        DropdownMenuItem<String>(
                          value: 'DEFECTO',
                          child: Text(
                            'Por defecto',
                            style: TextStyle(
                              fontSize: appWidth * 0.04,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: 'ABC',
                          child: Text(
                            'Alfabético',
                            style: TextStyle(
                                fontWeight: FontWeight.w600
                            ),
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: 'Caducidad',
                          child: Text(
                            'Caducidad',
                            style: TextStyle(
                                fontWeight: FontWeight.w600
                            ),
                          ),
                        )
                      ],
                      onChanged: (value) {
                        updateSelectedOption(value!);
                      },
                    ),
                  ),
                ),
              ],
            ),
          )
          ,
          Expanded(
            child: ListView.builder(
              itemCount: ingredients.length + 1, // Se suma 1 para dejar un margen al final
              itemBuilder: (context, index) {
                if( index==ingredients.length) {
                  return Container(height: 70);
                }

                final ingredient = ingredients[index];
                return Dismissible(
                    key: Key(ingredient.idIngredient),
                    direction: DismissDirection.horizontal,
                    background: Container(
                      color: AppTheme.basket,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: SvgPicture.asset(
                                'assets/basket.svg',
                                height: appWidth * 0.1
                            ),
                          ),
                          Text(
                              'Cesta',
                            style: TextStyle(
                              fontSize: appWidth * 0.045,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    secondaryBackground: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                              'Eliminar',
                            style: TextStyle(
                              fontSize:  appWidth * 0.045,
                              color: Colors.white,
                            ),
                          ),
                          Icon(
                              Icons.delete_forever,
                              color: Colors.white,
                              size: 35.0
                          ),
                        ],
                      ),
                    ),
                    onDismissed: (direction) {
                      if (direction == DismissDirection.endToStart ){
                        widget.pantryList.deleteIngredient(ingredient.idIngredient);
                      }else if ( direction == DismissDirection.startToEnd ){
                        widget.pantryList.moveToBasket(ingredient, context);
                      }
                    },
                    child: BoxIngredient(pantry: true, ingredient: ingredient, basketList: BasketListProvider(), pantryList: widget.pantryList, seeDateExpiry: seeDateExpiry,)
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}