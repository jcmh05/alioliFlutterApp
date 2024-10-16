import 'package:flutter/material.dart';
import 'package:alioli/models/models.dart';
import 'package:alioli/provider/provider.dart';
import 'package:provider/provider.dart';

class BasketListProvider extends ChangeNotifier {
  List<Ingredient> _ingredients = <Ingredient>[];
  List<Ingredient> get ingredients => List.unmodifiable(_ingredients);

  BasketListProvider(){
    initialList();
  }

  void initialList() async{
    _ingredients = await IngredientDao().readAll('basket');
    notifyListeners();
  }

  void deleteIngredient(String id) {
    IngredientDao().delete(id, 'basket');
    _ingredients.removeWhere((element) => element.idIngredient == id);
    notifyListeners();
  }
  void addIngredient(Ingredient item) {
    _ingredients.add(item);
    IngredientDao().insert(item, 'basket');
    notifyListeners();
  }

  void updateIngredient(Ingredient item, String id) {
    final index = _ingredients.indexWhere((element) => element.idIngredient == id);
    if (index != -1) {
      _ingredients[index] = item;
      IngredientDao().update(item, 'basket');
      notifyListeners();
    }
  }

  void moveToPantry(Ingredient item, BuildContext context){
    item = item.copyConstructor(date: DateTime(3000, 1, 1));

    final manager = Provider.of<PantryListProvider>(context, listen: false);
    manager.addIngredient(item);
    deleteIngredient(item.idIngredient);
  }
}




