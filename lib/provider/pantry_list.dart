import 'package:flutter/material.dart';
import 'package:alioli/models/models.dart';
import 'package:alioli/provider/provider.dart';
import 'package:provider/provider.dart';

class PantryListProvider extends ChangeNotifier {
  List<Ingredient> _ingredients = <Ingredient>[];
  List<Ingredient> get ingredients => List.unmodifiable(_ingredients);

  PantryListProvider(){
    initialList();
  }

  void initialList() async{
    _ingredients = await IngredientDao().readAll('pantry');
    notifyListeners();
  }

  void deleteIngredient(String id) {
    IngredientDao().delete(id, 'pantry');
    _ingredients.removeWhere((element) => element.idIngredient == id);
    notifyListeners();
  }
  void addIngredient(Ingredient item) {
    _ingredients.add(item);
    IngredientDao().insert(item, 'pantry');
    notifyListeners();
  }

  void updateIngredient(Ingredient item, String id) {
    final index = _ingredients.indexWhere((element) => element.idIngredient == id);
    if (index != -1) {
      _ingredients[index] = item;
      IngredientDao().update(item, 'pantry');
      notifyListeners();
    }
  }

  void moveToBasket(Ingredient item,BuildContext context){
    final manager = Provider.of<BasketListProvider>(context, listen: false);
    manager.addIngredient(item);
    deleteIngredient(item.idIngredient);
  }
}