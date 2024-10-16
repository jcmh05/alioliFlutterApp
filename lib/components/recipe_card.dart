import 'package:alioli/components/components.dart';
import 'package:alioli/models/models.dart';
import 'package:alioli/second_screens/second_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final int mode;
  final bool offline_mode;
  final List<String>? ingredientsSearch;

  RecipeCard({
    required this.recipe,
    this.mode = 0,
    this.offline_mode = false,
    this.ingredientsSearch,
  });

  // Función para construir un chip
  Widget buildChip(String label) {
    return Chip(
      visualDensity: VisualDensity(horizontal: VisualDensity.minimumDensity, vertical: VisualDensity.minimumDensity),
      //avatar: Icon(AppTheme.categoryIcons[label], color: Colors.black, size: 16.0),
      label: Text(AppTheme.categoryNames[label]!, style: TextStyle(color: Colors.black, fontSize: 12.0)), // Tamaño de fuente reducido
      backgroundColor: AppTheme.categoryColors[label],
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.transparent, width: 0),
        borderRadius: BorderRadius.circular(20.0),
      ),
    );
  }

  // Función para generar los chips
  Widget generateChips() {
    List<Widget> chips = [];

    // Agregar chip para tiempo
    chips.add(Chip(
      visualDensity: VisualDensity(horizontal: VisualDensity.minimumDensity, vertical: VisualDensity.minimumDensity),
      //avatar: Icon(Icons.timer, color: Colors.black,size: 16.0),
      label: Text('${recipe.minutes} min', style: TextStyle(color: Colors.black, fontSize: 12.0)),
      backgroundColor: Color(0xffadeaff),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.transparent, width: 0),
        borderRadius: BorderRadius.circular(20.0),
      ),
    ));

    // Agregar chip para region
    if (recipe.region != null &&
        AppTheme.categoryNames.containsKey(recipe.region) &&
        AppTheme.categoryColors.containsKey(recipe.region) &&
        AppTheme.categoryIcons.containsKey(recipe.region)) {
      chips.add(buildChip(recipe.region!));
    }

// Agregar chips para tags
    for (String tag in recipe.tags) {
      if (AppTheme.categoryNames.containsKey(tag) &&
          AppTheme.categoryColors.containsKey(tag) &&
          AppTheme.categoryIcons.containsKey(tag)) {
        chips.add(buildChip(tag));
      }
    }

// Agregar chips para mealtime
    for (String mealtime in recipe.mealtime) {
      if (AppTheme.categoryNames.containsKey(mealtime) &&
          AppTheme.categoryColors.containsKey(mealtime) &&
          AppTheme.categoryIcons.containsKey(mealtime)) {
        chips.add(buildChip(mealtime));
      }
    }

    // Muestra el wrap limitado a una altura fija
    return Container(
      height: 65.0, // Aumenta la altura para permitir dos filas
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Wrap(
          spacing: 4.0,
          children: chips,
        ),
      ),
    );
  }

  Widget buildIngredientsList(BuildContext context) {
    List<InlineSpan> matchingSpans = [];
    List<InlineSpan> nonMatchingSpans = [];

    for (int i = 0; i < recipe.ingredients.length; i++) {
      var id = recipe.ingredients[i];
      Ingredient ingredient = globalIngredients.firstWhere(
              (ingredient) => ingredient.id == id,
          orElse: () => Ingredient(
            id: '0',
            idIngredient: '0',
            name: id,
            icon: 'ingredient',
            amount: 0,
            unit: 'und',
            date: DateTime(3000, 1, 1),
            barcode: '0',
          ));

      WidgetSpan iconSpan = WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: SvgPicture.asset(
          'assets/ingredients/${ingredient.icon}.svg',
          height: 14.0,
        ),
      );

      TextSpan nameSpan;
      // Check if ingredientsSearch exists and is not empty
      if (ingredientsSearch != null && ingredientsSearch!.isNotEmpty) {
        // Check if the ingredient id is in ingredientsSearch
        if (ingredientsSearch!.contains(id)) {
          // If it is, add the ingredient name in bold
          nameSpan = TextSpan(text: " ${ingredient.name}", style: TextStyle(fontWeight: FontWeight.bold));
          matchingSpans.add(iconSpan);
          matchingSpans.add(nameSpan);
          // If it's not the last matching ingredient, add a comma
          if (i != recipe.ingredients.length - 1 && ingredientsSearch!.contains(recipe.ingredients[i + 1])) {
            matchingSpans.add(TextSpan(text: ", "));
          }
        } else {
          // If it's not, add the ingredient name normally
          nameSpan = TextSpan(text: " ${ingredient.name}");
          nonMatchingSpans.add(iconSpan);
          nonMatchingSpans.add(nameSpan);
          // If it's not the last non-matching ingredient, add a comma
          if (i != recipe.ingredients.length - 1 && !ingredientsSearch!.contains(recipe.ingredients[i + 1])) {
            nonMatchingSpans.add(TextSpan(text: ", "));
          }
        }
      } else {
        // If ingredientsSearch doesn't exist or is empty, add the ingredient name normally
        nameSpan = TextSpan(text: " ${ingredient.name}");
        nonMatchingSpans.add(iconSpan);
        nonMatchingSpans.add(nameSpan);
        // If it's not the last ingredient, add a comma
        if (i != recipe.ingredients.length - 1) {
          nonMatchingSpans.add(TextSpan(text: ", "));
        }
      }
    }

    // Combine the two lists, putting matching ingredients first
    List<InlineSpan> spans = [];
    if (matchingSpans.isNotEmpty && nonMatchingSpans.isNotEmpty) {
      spans = []..addAll(matchingSpans)..add(TextSpan(text: ", "))..addAll(nonMatchingSpans);
    } else {
      spans = []..addAll(matchingSpans)..addAll(nonMatchingSpans);
    }

    return Container(
      padding: EdgeInsets.all(8.0),
      child: RichText(
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: spans,
          style: DefaultTextStyle.of(context).style,
        ),
        maxLines: 2,
      ),
    );
  }

  Widget recipeCard0(BuildContext context){
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: MediaQuery.of(context).platformBrightness==Brightness.light ? AppTheme.grey1 : AppTheme.black1, // Cambiado a transparente
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 10.0,top: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(recipe.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), maxLines: 2,overflow: TextOverflow.ellipsis,),
                  Spacer(),
                  generateChips(),
                  Spacer(),
                  buildIngredientsList(context),
                ],
              ),
            ),
          ),
          Container(
            height: 200,
            width: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.transparent, Colors.black],
                    stops: [0.1, 0.15],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: Image.memory(
                  recipe.image,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget recipeCard1(BuildContext context){
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: MediaQuery.of(context).platformBrightness==Brightness.light ? AppTheme.grey1 : AppTheme.black1,
      ),
      child: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.memory(
                    recipe.image,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // Elementos de la derecha (ingredientes y tiempo)
                        Icon(
                          FontAwesomeIcons.carrot,
                          color: Colors.white,
                          size: 18,
                          shadows: <Shadow>[
                            Shadow(
                              offset: Offset(1.0, 1.0),
                              blurRadius: 3.0,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                            Shadow(
                              offset: Offset(1.0, 1.0),
                              blurRadius: 8.0,
                              color: Color.fromARGB(125, 0, 0, 0),
                            ),
                          ],
                        ),
                        SizedBox(width: 3),
                        Text(
                          recipe.ingredients.length.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            shadows: <Shadow>[
                              Shadow(
                                offset: Offset(1.0, 1.0),
                                blurRadius: 3.0,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                              Shadow(
                                offset: Offset(1.0, 1.0),
                                blurRadius: 8.0,
                                color: Color.fromARGB(125, 0, 0, 0),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(
                          FontAwesomeIcons.clock,
                          color: Colors.white,
                          size: 18,
                          shadows: <Shadow>[
                            Shadow(
                              offset: Offset(1.0, 1.0),
                              blurRadius: 3.0,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                            Shadow(
                              offset: Offset(1.0, 1.0),
                              blurRadius: 8.0,
                              color: Color.fromARGB(125, 0, 0, 0),
                            ),
                          ],
                        ),
                        SizedBox(width: 3),
                        Text(
                          recipe.minutes.toString() + " '",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            shadows: <Shadow>[
                              Shadow(
                                offset: Offset(1.0, 1.0),
                                blurRadius: 3.0,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                              Shadow(
                                offset: Offset(1.0, 1.0),
                                blurRadius: 8.0,
                                color: Color.fromARGB(125, 0, 0, 0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (recipe.tags.contains('vegan') || recipe.tags.contains('vegetarian'))
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Icon(
                        AppTheme.categoryIcons[recipe.tags.contains('vegan') ? 'vegan' : 'vegetarian'],
                        color: Colors.white,
                        size: 18,
                        shadows: <Shadow>[
                          Shadow(
                            offset: Offset(1.0, 1.0),
                            blurRadius: 3.0,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                          Shadow(
                            offset: Offset(1.0, 1.0),
                            blurRadius: 8.0,
                            color: Color.fromARGB(125, 0, 0, 0),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0,top: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(recipe.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), maxLines: 2,overflow: TextOverflow.ellipsis,),
                buildIngredientsList(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeScreen(recipe: recipe,offline_mode: offline_mode,),
          ),
        );
      },
      child: mode == 1 ? recipeCard1(context) : recipeCard0(context),
    );
  }
}