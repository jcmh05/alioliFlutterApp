import 'package:alioli/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uuid/uuid.dart';

class AddToBasketButton extends StatefulWidget {
  final Ingredient ingredient;
  final List<Ingredient> basketIngredients;

  AddToBasketButton({required this.ingredient, required this.basketIngredients});

  @override
  _AddToBasketButtonState createState() => _AddToBasketButtonState();
}

class _AddToBasketButtonState extends State<AddToBasketButton> {


  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        setState(() {
          if (widget.basketIngredients.any((i) => i.id == widget.ingredient.id)) {
            String idIngredient = widget.basketIngredients.firstWhere((i) => i.id == widget.ingredient.id).idIngredient;
            IngredientDao().delete(idIngredient, 'basket');
            widget.basketIngredients.removeWhere((i) => i.id == widget.ingredient.id);
          } else {
            final producto = Ingredient(
                id: widget.ingredient.id,
                idIngredient: const Uuid().v1(),
                name: widget.ingredient.name,
                icon: widget.ingredient.icon,
                amount: widget.ingredient.amount,
                unit: 'und',
                barcode: '0',
                date: DateTime(3000, 1, 1),
            );

            IngredientDao().insert(producto, 'basket');
            widget.basketIngredients.add(producto);
          }
        });
      },
      icon: Icon(
          widget.basketIngredients.any((i) => i.id == widget.ingredient.id) ? Icons.check : Icons.add,
          color: Colors.black
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
              widget.basketIngredients.any((i) => i.id == widget.ingredient.id) ? 'Añadido a Cesta' : 'Añadir a Cesta',
              style: TextStyle(color: Colors.black)
          ),
          SizedBox(width: 8.0),
          SvgPicture.asset(
            'assets/basket.svg',
            height: 30.0,
          ),
        ],
      ),
    );
  }
}