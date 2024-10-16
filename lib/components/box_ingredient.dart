import 'package:flutter/material.dart';
import 'package:alioli/components/components.dart';
import 'package:alioli/models/models.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:alioli/provider/provider.dart';
import 'package:alioli/second_screens/second_screens.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class BoxIngredient extends StatelessWidget {
  final bool pantry;
  final Ingredient ingredient;
  final BasketListProvider basketList;
  final PantryListProvider pantryList;
  final bool seeDateExpiry;

  BoxIngredient({Key? key, required this.pantry, required this.ingredient, required this.basketList, required this.pantryList, required this.seeDateExpiry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double appHeight = MediaQuery.of(context).size.height;
    double appWidth = MediaQuery.of(context).size.width;

    Widget editbutton() {
      return IconButton(
        icon: Icon(Icons.edit),
        iconSize: 25.0,
        onPressed: () {
          showBarModalBottomSheet(
            context: context,
            builder: (context) => Container(
              child: AddIngredientScreen(
                pantry: pantry,
                productoOriginal: ingredient,
                editarProducto: (producto) {
                  pantry ? pantryList.updateIngredient(producto, producto.idIngredient) : basketList.updateIngredient(producto, producto.idIngredient);
                  Navigator.pop(context);
                },
                crearProducto: (producto) {},
              ),
            ),
          );
        },
      );
    }

    Widget widgetExpiryDate() {
      String date = ingredient.date.day.toString();

      if (ingredient.date.year == 3000) {
        date = 'N/E';
      } else {
        final Map<int, String> monthAbbreviations = {
          1: 'Ene',
          2: 'Feb',
          3: 'Mar',
          4: 'Abr',
          5: 'May',
          6: 'Jun',
          7: 'Jul',
          8: 'Ago',
          9: 'Sep',
          10: 'Oct',
          11: 'Nov',
          12: 'Dic',
        };

        date += " " + monthAbbreviations[ingredient.date.month]! + " " + ingredient.date.year.toString();
      }

      Duration difference = ingredient.date.difference(DateTime.now());

      return Text(
        date,
        style: TextStyle(
          fontSize: appWidth * 0.03,
          color: difference.inDays < 3
              ? Colors.redAccent
              : difference.inDays < 7 ? Colors.orange : Colors.grey,
        ),
      );
    }

    return Container(
      // Fila principal
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // Fila con icono, nombre, unidades y fecha caducidad
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return InfoIngredient(ingredient: ingredient);
                },
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(
                    'assets/ingredients/' + ingredient.icon + '.svg',
                    height: appWidth * 0.08
                ),
                SizedBox(width: 10.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          constraints: ingredient.amount==0 ? BoxConstraints(maxWidth: appWidth * 0.7) : BoxConstraints(maxWidth: appWidth * 0.50),
                          child: Text(
                            ingredient.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: appWidth * 0.045,
                                color: Theme.of(context).dividerColor
                            ),
                          ),
                        ),
                        if (ingredient.amount > 0)
                          Text(
                            ' (${ingredient.amount} ${ingredient.unit})',
                            style: TextStyle(
                              fontSize: 18.0, // Tamaño de fuente para la cantidad
                              color: Colors.grey, // Color del texto de la cantidad
                            ),
                          ),
                      ],
                    ),
                    if (seeDateExpiry)
                      widgetExpiryDate(),
                  ],
                ),
              ],
            ),
          ),
          editbutton(),
        ],
      ),
    );
  }
}
