import 'package:flutter/material.dart ';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:alioli/provider/provider.dart';
import 'package:alioli/components/components.dart';
import 'second_screens.dart';
import 'package:provider/provider.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

class BasketScreen extends StatelessWidget {
  const BasketScreen({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<BasketListProvider>(context, listen: false);
    manager.initialList();
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
          backgroundColor: AppTheme.basket,
        ),
        closeButtonBuilder: RotateFloatingActionButtonBuilder(
          child: const Icon(Icons.close),
          backgroundColor: AppTheme.basket_third,
        ),
        children: [
          FloatingActionButton(
            backgroundColor: AppTheme.basket,
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
                    pantry: false,
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
          // Barcode Scanner
          FloatingActionButton(
            backgroundColor: AppTheme.basket,
            child: const Icon(FontAwesomeIcons.barcode,size: 27.0,),
            onPressed: () {
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
    return Consumer<BasketListProvider>(
      builder: (context, manager, child) {
        if (manager.ingredients.isNotEmpty) {
          return ListBasketScreenFull(basketList: manager);
        } else {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              placeholderIconText(context,'assets/basket_empty.svg',"No hay productos todavía","Toca el botón + para añadir",1),
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            ]
          );
        }
      },
    );
  }

}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////LISTA LLENA/////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class ListBasketScreenFull extends StatefulWidget {
  const ListBasketScreenFull({Key? key, required this.basketList}) : super(key:
  key);
  final BasketListProvider basketList;

  @override
  State<ListBasketScreenFull> createState() => _ListBasketScreenFullState();
}

class _ListBasketScreenFullState extends State<ListBasketScreenFull> {
  String selectedOption = 'DEFECTO';

  void load_preferences() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String option = prefs.getString('selectedOptionBasket') ?? 'DEFECTO';
    setState(() {
      selectedOption = option;
    });
  }

  void updateSelectedOption(String value) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedOptionBasket', value);
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
    var ingredients = widget.basketList.ingredients;

    if (selectedOption == "ABC") {
      ingredients = List.from(ingredients)..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else {
      ingredients = ingredients;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Botón para compartir la lista de la compra
              IconButton(
                icon: Icon(
                  Icons.share,
                  color: AppTheme.basket,
                  size: 30.0,
                ),
                onPressed: () {
                  String text = "🛒Lista de la compra:\n";
                  for (var ingredient in ingredients) {
                    text += "- " + ingredient.name + "\n";
                  }
                  shareText(text);
                },
              ),
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
                    ],
                    onChanged: (value) {
                      updateSelectedOption(value!);
                    },
                  ),
                ),
              ),
            ],
          ),
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
                      color: Colors.red,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Icon(
                              Icons.delete_forever,
                              color: Colors.white,
                              size: 35.0
                          ),
                          Text(
                            'Eliminar',
                            style: TextStyle(
                              fontSize:  appWidth * 0.045,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    secondaryBackground: Container(
                      color: AppTheme.pantry,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Despensa',
                            style: TextStyle(
                                fontSize:  appWidth * 0.045,
                              color: Colors.white,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: SvgPicture.asset(
                                'assets/pantry.svg',
                                height:  appWidth * 0.1
                            ),
                          )
                        ],
                      ),
                    ),
                    onDismissed: (direction) {
                      if( direction == DismissDirection.endToStart ){
                        widget.basketList.moveToPantry(ingredient, context);
                      }else if ( direction == DismissDirection.startToEnd){
                        widget.basketList.deleteIngredient(ingredient.idIngredient);
                      }
                    },
                    child: BoxIngredient(pantry: false, ingredient: ingredient, basketList: widget.basketList, pantryList: PantryListProvider(), seeDateExpiry: false,)
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}