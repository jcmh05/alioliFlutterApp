import 'package:alioli/components/components.dart';
import 'package:flutter/material.dart';
import 'package:alioli/models/models.dart';
import 'package:alioli/provider/provider.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fuzzy/data/fuzzy_options.dart';
import 'package:fuzzy/fuzzy.dart';

class IngredientSelectionDialog extends StatefulWidget {
  final Ingredient ingredient;
  final ChangeNotifier manager;

  IngredientSelectionDialog({required this.ingredient, required this.manager});

  @override
  _IngredientSelectionDialogState createState() => _IngredientSelectionDialogState();
}

class _IngredientSelectionDialogState extends State<IngredientSelectionDialog> {
  List<Ingredient> filteredIngredients = [];
  List<Ingredient> suggestedIngredients = [];
  bool isSearchFieldEmpty = true;

  @override
  void initState() {
    super.initState();
    _generateSuggestions();
  }

  void _generateSuggestions() {
    var ingredientName = widget.ingredient.name;
    var fuse = Fuzzy(globalIngredients.map((ingredient) => ingredient.name).toList(), options: FuzzyOptions(isCaseSensitive: false, shouldSort: true));

    if (ingredientName.split(' ').length == 1) {
      var results = fuse.search(ingredientName);
      suggestedIngredients = results.take(3).map((result) => globalIngredients.firstWhere((ingredient) => ingredient.name == result.item)).toList();
    } else if (ingredientName.split(' ').length == 2) {
      var firstWord = ingredientName.split(' ')[0];
      var resultsFirstWord = fuse.search(firstWord);
      var resultsFullName = fuse.search(ingredientName);
      suggestedIngredients = [
        if (resultsFirstWord.isNotEmpty) globalIngredients.firstWhere((ingredient) => ingredient.name == resultsFirstWord[0].item),
        ...resultsFullName.take(2).map((result) => globalIngredients.firstWhere((ingredient) => ingredient.name == result.item)).toList()
      ];
    } else {
      var words = ingredientName.split(' ');
      var firstWord = words[0];
      var firstTwoWords = words.sublist(0, 2).join(' ');
      var resultsFirstWord = fuse.search(firstWord);
      var resultsFirstTwoWords = fuse.search(firstTwoWords);
      var resultsFullName = fuse.search(ingredientName);

      suggestedIngredients = [
        if (resultsFirstWord.isNotEmpty) globalIngredients.firstWhere((ingredient) => ingredient.name == resultsFirstWord[0].item),
        if (resultsFirstTwoWords.isNotEmpty) globalIngredients.firstWhere((ingredient) => ingredient.name == resultsFirstTwoWords[0].item),
        if (resultsFullName.isNotEmpty) globalIngredients.firstWhere((ingredient) => ingredient.name == resultsFullName[0].item)
      ];
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      isSearchFieldEmpty = value.isEmpty;
      if (isSearchFieldEmpty) {
        _generateSuggestions();
      } else {
        var fuse = Fuzzy(globalIngredients.map((ingredient) => ingredient.name).toList(), options: FuzzyOptions(isCaseSensitive: false, shouldSort: true));
        var results = fuse.search(value);
        filteredIngredients = results.map((result) => globalIngredients.firstWhere((ingredient) => ingredient.name == result.item)).take(3).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Selecciona categoría'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: "Buscar ingrediente",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15.0)),
                ),
              ),
            ),
            if (isSearchFieldEmpty) ...[
              SizedBox(height: 10),
              Text(
                'Creemos que puede ser:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 10),
              ...suggestedIngredients.map((ingredient) => Container(
                margin: EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: ListTile(
                  leading: SvgPicture.asset(
                    'assets/ingredients/${ingredient.icon}.svg',
                    height: 30.0,
                  ),
                  title: Center(child: Text(ingredient.name)),
                  onTap: () {
                    Ingredient ingredientAdd = widget.ingredient.copyConstructor(id: ingredient.id, icon: ingredient.icon);
                    if (widget.manager is PantryListProvider) {
                      (widget.manager as PantryListProvider).addIngredient(ingredientAdd);
                    } else if (widget.manager is BasketListProvider) {
                      (widget.manager as BasketListProvider).addIngredient(ingredientAdd);
                    }
                    Navigator.pop(context);
                  },
                ),
              )).toList(),
            ],
            if (!isSearchFieldEmpty) ...filteredIngredients.map((ingredient) => ListTile(
              leading: SvgPicture.asset(
                'assets/ingredients/${ingredient.icon}.svg',
                height: 30.0,
              ),
              title: Text(ingredient.name),
              onTap: () {
                Ingredient ingredientAdd = widget.ingredient.copyConstructor(id: ingredient.id, icon: ingredient.icon);
                if (widget.manager is PantryListProvider) {
                  (widget.manager as PantryListProvider).addIngredient(ingredientAdd);
                } else if (widget.manager is BasketListProvider) {
                  (widget.manager as BasketListProvider).addIngredient(ingredientAdd);
                }
                Navigator.pop(context);
              },
            )).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Ingredient ingredientAdd = widget.ingredient.copyConstructor(id: '0', icon: 'ingredient');
            if (widget.manager is PantryListProvider) {
              (widget.manager as PantryListProvider).addIngredient(ingredientAdd);
            } else if (widget.manager is BasketListProvider) {
              (widget.manager as BasketListProvider).addIngredient(ingredientAdd);
            }
            Navigator.pop(context);
          },
          child: Text('Guardar sin categoría'),
        ),
      ],
    );
  }
}
