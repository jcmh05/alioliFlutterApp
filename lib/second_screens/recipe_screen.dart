import 'dart:typed_data';
import 'dart:ui';

import 'package:alioli/components/theme.dart';
import 'package:alioli/components/utils.dart';
import 'package:alioli/services/local_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:alioli/models/models.dart';
import 'package:alioli/components/components.dart';
import 'package:flutter_popup/flutter_popup.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

class RecipeScreen extends StatefulWidget {
  Recipe recipe;
  bool offline_mode;
  RecipeScreen({required this.recipe, required this.offline_mode});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> with TickerProviderStateMixin {
  final Log = logger(RecipeScreen);
  List<Ingredient> _pantryIngredients = <Ingredient>[];
  List<Ingredient> _basketIngredients = <Ingredient>[];

  // Receta
  int _numOfPeople = 1;
  bool _isLiked = false;
  bool _isSaved = false;
  List<String> _likesList = [];
  late Future<List<Ingredient>> _ingredientsFuture;

  // Diseño
  TabController? _tabController;
  final double infoHeight = 364.0;
  AnimationController? animationController;
  AnimationController? scaleSaveController;
  AnimationController? scaleLikeController;
  AnimationController? scaleUnitController;
  Animation<double>? animation;
  double opacity1 = 0.0;
  double opacity2 = 0.0;
  double opacity3 = 0.0;

  int numVideos = 2;

  @override
  void initState() {
    super.initState();
    initialList();
    numVideos = [isYoutubeUrl(widget.recipe.youtubeUrl), isTiktokUrl(widget.recipe.tiktokUrl), isInstagramUrl(widget.recipe.instagramUrl)].where((v) => v).length;
    _numOfPeople = widget.recipe.numPersons;
    _ingredientsFuture = IngredientDao().readAll('ingredients');
    animationController = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: animationController!,
        curve: Interval(0, 1.0, curve: Curves.fastOutSlowIn)));
    setData();
    scaleLikeController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    scaleSaveController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    scaleUnitController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _tabController = TabController(length: numVideos==0 ? 2 : 3, vsync: this);

    // Control para listas
    if ( LocalStorage().isRecipeInAnyList(widget.recipe.id) ){
      setState(() {
        _isSaved = true;
      });
    }

    // Control para los likes
    _likesList = widget.recipe.likes;
    String email = LocalStorage().getEmail();
    // Si el correo del usuario está en la lista de likes, actualizamos el valor
    if (_likesList.contains(email)) {
      setState(() {
        _isLiked = true;
      });
    }
    // Si el id de la receta está en likeRecipeBox.getLikeRecipes(), actualizamos el valor
    if (LocalStorage().getLikeRecipe(widget.recipe.id) != null) {
      setState(() {
        _isLiked = true;
      });
    }
  }

  void dispose() {
    animationController?.dispose();
    scaleLikeController?.dispose();
    scaleSaveController?.dispose();
    scaleUnitController?.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  void initialList() async {
    _pantryIngredients = await IngredientDao().readAll('pantry');
    _basketIngredients = await IngredientDao().readAll('basket');
  }

  Future<void> setData() async {
    animationController?.forward();
    await Future<dynamic>.delayed(const Duration(milliseconds: 200));
    setState(() {
      opacity1 = 1.0;
    });
    await Future<dynamic>.delayed(const Duration(milliseconds: 200));
    setState(() {
      opacity2 = 1.0;
    });
    await Future<dynamic>.delayed(const Duration(milliseconds: 200));
    setState(() {
      opacity3 = 1.0;
    });
  }

  int numLikes(){
    int num = _likesList.length;

    if ( _likesList.contains(LocalStorage().getEmail()) ){
      // Si el usuario ya había dado like
      if ( !_isLiked ){
        num--;
      }
    }else{
      // Si el usuario no había dado like
      if ( _isLiked ){
        num++;
      }
    }

    return num;
  }

  // Widget con el titulo y botón de me gusta
  Widget header(){
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 100),
              opacity: opacity2,
              child: Text(
                widget.recipe.name,
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: Theme.of(context).dividerColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          if ( !widget.offline_mode )
            Row(
              children: [
                ScaleTransition(
                  alignment: Alignment.center,
                  scale: CurvedAnimation(
                      parent: animationController!, curve: Curves.fastOutSlowIn),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: Tween(begin: 1.0, end: 1.6).animate(scaleSaveController!),
                        child: IconButton(
                          icon: Icon(
                            _isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: _isSaved ? Colors.yellow : Colors.grey,
                            size: 30,
                          ),
                          onPressed: () {
                            scaleSaveController!.forward().then((value) => scaleSaveController!.reverse());

                            showBarModalBottomSheet(
                              context: context,
                              expand: false,
                              backgroundColor: Theme.of(context).canvasColor,
                              builder: (context) {
                                List<RecipeList> recipeLists = LocalStorage().getRecipeLists();
                                List<String> selectedRecipeLists = []; // Lista para rastrear las recetas seleccionadas

                                if (_isSaved) {
                                  for (RecipeList recipeList in recipeLists) {
                                    for (Recipe recipe in recipeList.recipes) {
                                      if (recipe.id == widget.recipe.id) {
                                        selectedRecipeLists.add(recipeList.idList);
                                      }
                                    }
                                  }
                                }

                                bool _isLoading = false;

                                return StatefulBuilder(
                                  builder: (BuildContext context, StateSetter setState) {
                                    return Container(
                                      padding: EdgeInsets.all(16.0),
                                      child: Wrap(
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(height: 8.0),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Guardar receta en...',
                                                    style: TextStyle(
                                                      fontSize: 20.0,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (BuildContext context) {
                                                          return AddRecipeListDialog();
                                                        },
                                                      ).then((_) {
                                                        setState(() {});
                                                      });
                                                    },
                                                    child: const Text(
                                                      'Crear lista +',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                              SizedBox(height: 8.0),
                                              if (!LocalStorage().isRecipeListEmpty())
                                                Column(
                                                  children: [
                                                    Divider(),
                                                    Container(
                                                      constraints: BoxConstraints(
                                                        maxHeight: MediaQuery.of(context).size.height * 0.5, // Limita la altura del ListView
                                                      ),
                                                      child: ListView.builder(
                                                        shrinkWrap: true,
                                                        itemCount: recipeLists.length,
                                                        itemBuilder: (context, index) {
                                                          return InkWell(
                                                            onTap: () {
                                                              setState(() {
                                                                if (selectedRecipeLists.contains(recipeLists[index].idList)) {
                                                                  selectedRecipeLists.remove(recipeLists[index].idList);
                                                                } else {
                                                                  selectedRecipeLists.add(recipeLists[index].idList);
                                                                }
                                                              });
                                                            },
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              children: [
                                                                Expanded(
                                                                  child: Row(
                                                                    children: [
                                                                      Checkbox(
                                                                        value: selectedRecipeLists.contains(recipeLists[index].idList),
                                                                        onChanged: (bool? value) {
                                                                          setState(() {
                                                                            if (value == true) {
                                                                              selectedRecipeLists.add(recipeLists[index].idList);
                                                                            } else {
                                                                              selectedRecipeLists.remove(recipeLists[index].idList);
                                                                            }
                                                                          });
                                                                        },
                                                                      ),
                                                                      SizedBox(width: 8.0),
                                                                      Expanded(
                                                                        child: Text(
                                                                          recipeLists[index].name,
                                                                          overflow: TextOverflow.ellipsis,
                                                                          style: TextStyle(
                                                                            fontSize: 16.0,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                Icon(AppTheme.listIconsList[recipeLists[index].iconId]!),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    Divider(),
                                                    SizedBox(height: 16.0),
                                                    Center(
                                                      child: Rounded3dButton(
                                                        'Guardar',
                                                        AppTheme.pantry,
                                                        AppTheme.pantry_second,
                                                        width: 200.0,
                                                            () {
                                                          setState(() {
                                                            _isLoading = true;
                                                          });

                                                          final FirebaseFirestore _firestore = FirebaseFirestore.instance;

                                                          for (RecipeList recipeList in recipeLists) {
                                                            DocumentReference docRef = _firestore.collection('recipe_list').doc(recipeList.idList);

                                                            if (selectedRecipeLists.contains(recipeList.idList)) {
                                                              // Añadir receta a la lista en Firebase y localmente si no está ya
                                                              if (!recipeList.recipes.any((recipe) => recipe.id == widget.recipe.id)) {
                                                                docRef.update({
                                                                  'recipes': FieldValue.arrayUnion([widget.recipe.id])
                                                                }).then((_) {
                                                                  Log.i('Receta añadida a la lista de recetas con id: ${recipeList.idList}');
                                                                  LocalStorage().addRecipeToList(recipeList.idList, widget.recipe);
                                                                }).catchError((error) {
                                                                  Log.e("Error updating document: $error");
                                                                });
                                                              }
                                                            } else {
                                                              // Eliminar receta de la lista en Firebase y localmente si está
                                                              if (recipeList.recipes.any((recipe) => recipe.id == widget.recipe.id)) {
                                                                docRef.update({
                                                                  'recipes': FieldValue.arrayRemove([widget.recipe.id])
                                                                }).then((_) {
                                                                  Log.i('Receta eliminada de la lista de recetas con id: ${recipeList.idList}');
                                                                  LocalStorage().removeRecipeFromList(recipeList.idList, widget.recipe);
                                                                }).catchError((error) {
                                                                  Log.e("Error updating document: $error");
                                                                });
                                                              }
                                                            }
                                                          }

                                                          Navigator.pop(context, selectedRecipeLists.isNotEmpty);
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ).then((value) {
                              if (value == null) {
                                // No hacer nada
                              } else if (value == true) {
                                // Si la receta está guardada en alguna lista, activamos el icono de guardado
                                setState(() {
                                  _isSaved = true;
                                });
                              } else if (value == false) {
                                // Si la receta no está guardada en ninguna lista, desactivamos el icono de guardado
                                setState(() {
                                  _isSaved = false;
                                });
                              }
                            });

                          },
                        ),
                      ),
                      if( numLikes() > 0)
                        Text(
                          ''
                        ),
                    ],
                  ),
                ),
                ScaleTransition(
                  alignment: Alignment.center,
                  scale: CurvedAnimation(
                      parent: animationController!, curve: Curves.fastOutSlowIn),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: Tween(begin: 1.0, end: 1.6).animate(scaleLikeController!),
                        child: IconButton(
                          icon: Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border_outlined,
                            color: _isLiked ? Colors.red : Colors.grey,
                            size: 30,
                          ),
                          onPressed: () {
                            scaleLikeController!.forward().then((value) => scaleLikeController!.reverse());
                            setState(() {
                              _isLiked = !_isLiked;
                            });
                          },
                        ),
                      ),
                      if( numLikes() > 0)
                        Text(
                            numLikes().toString(),
                        ),
                    ],
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }

  // Descripción de la receta
  Widget textDescription(String text){
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: opacity2,
      child: Text(
        text,
        textAlign: TextAlign.justify,
        style: TextStyle(
          color: Theme.of(context).dividerColor,
          fontSize: 14,
        ),
      ),
    );
  }

  // Modificar la función buildRecipeTags
  Widget buildRecipeTags(Recipe recipe) {
    List<Widget> chips = [];

    // Agregar chip para tiempo
    int hours = recipe.minutes ~/ 60;
    int minutes = recipe.minutes % 60;

    String timeLabel = (hours > 0 ? '$hours hora${hours > 1 ? 's' : ''}' : '') +
        (minutes > 0 ? (hours > 0 ? ' y ' : '') + '$minutes minuto${minutes > 1 ? 's' : ''}' : '');

    chips.add(Chip(
      avatar: Icon(Icons.timer, color: Colors.black,size: 16.0),
      label: Text(timeLabel, style: TextStyle(color: Colors.black, fontSize: 12.0)),
      backgroundColor: Color(0xffadeaff),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.transparent, width: 0),
        borderRadius: BorderRadius.circular(20.0),
      ),
    ));

    // Agregar chip para region
    if (recipe.region != null && AppTheme.categoryIcons.containsKey(recipe.region)) {
      chips.add(buildChip(recipe.region!, hideAvatar: true));
    }

    // Agregar chips para tags
    for (String tag in recipe.tags) {
      if (AppTheme.categoryIcons.containsKey(tag)) {
        chips.add(buildChip(tag));
      }
    }

    // Agregar chips para mealtime
    for (String mealtime in recipe.mealtime) {
      if (AppTheme.categoryIcons.containsKey(mealtime)) {
        chips.add(buildChip(mealtime));
      }
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: opacity2,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.start,
          alignment: WrapAlignment.start,
          runAlignment: WrapAlignment.start,
          spacing: 8.0, // espacio entre chips
          runSpacing: 4.0, // espacio entre filas
          children: chips,
        ),
      ),
    );
  }

// Función para construir un chip
  Widget buildChip(String category, {bool hideAvatar = false}) {
    return Chip(
      avatar: hideAvatar ? null : Icon(AppTheme.categoryIcons[category], color: Colors.black,size: 16.0),
      label: Text(AppTheme.categoryNames[category]!, style: TextStyle(color: Colors.black, fontSize: 12.0)),
      backgroundColor: AppTheme.categoryColors[category],
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.transparent, width: 0),
        borderRadius: BorderRadius.circular(20.0),
      ),
    );
  }

  // Pestaña con ingredientes
  Widget buildIngredientsTab(List<String> ingredients, List<double> quantities, List<String> units) {
    return FutureBuilder<List<Ingredient>>(
      future: _ingredientsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          // Divide los ingredientes en dos listas
          List<Ingredient> pantryIngredients = [];
          List<Ingredient> otherIngredients = [];
          List<int> pantryIndexes = [];
          List<int> otherIndexes = [];

          for (int i = 0; i < ingredients.length; i++) {
            String ingredientId = ingredients[i];
            final ingredient = snapshot.data!.firstWhere(
                  (i) => i.id == ingredientId,
              orElse: () => Ingredient(
                id: '0', idIngredient: '', name: ingredientId, icon: 'ingredient', amount: 0, unit: '', date: DateTime(3000, 1, 1), barcode: '0', head: false,
              ),
            );

            if (_pantryIngredients.any((i) => i.id == ingredientId)) {
              pantryIngredients.add(ingredient);
              pantryIndexes.add(i);
            } else {
              otherIngredients.add(ingredient);
              otherIndexes.add(i);
            }
          }

          return Column(
            children: [
              SizedBox(height: 15.0),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor), // Borde blanco
                  borderRadius: BorderRadius.circular(30.0), // Bordes redondeados
                  color: Colors.transparent, // Fondo transparente
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () {
                        if (_numOfPeople > 1) {
                          setState(() {
                            _numOfPeople--;
                            scaleUnitController!.forward().then((value) => scaleUnitController!.reverse());
                          });
                        }
                      },
                    ),
                    Text('Raciones: $_numOfPeople'),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          _numOfPeople++;
                          scaleUnitController!.forward().then((value) => scaleUnitController!.reverse());
                        });
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15.0),
              Flexible(
                fit: FlexFit.loose,
                child: ListView(
                  children: [
                    // Mostrar otherIngredients
                    ...otherIngredients.asMap().entries.map((entry) {
                      final ingredient = entry.value;
                      final index = otherIndexes[entry.key];
                      double quantity = (quantities[index] / widget.recipe.numPersons) * _numOfPeople;
                      String quantityStr = quantity == 0 ? "Al gusto" : formatQuantity(quantity, units[index]);
                      return CustomPopup(
                        content: AddToBasketButton(
                          ingredient: ingredient,
                          basketIngredients: _basketIngredients,
                        ),
                        child: ListTile(
                          leading: SvgPicture.asset(
                            'assets/ingredients/${ingredient.icon}.svg',
                            height: 30.0,
                          ),
                          title: Text(ingredient.name),
                          trailing: ScaleTransition(
                            scale: Tween(begin: 1.0, end: 1.6).animate(scaleUnitController!),
                            child: Text(quantityStr),
                          ),
                        ),
                      );
                    }).toList(),
                    // Mostrar pantryIngredients si no está vacío
                    if (pantryIngredients.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                        child: Text(
                          'En despensa:',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ...pantryIngredients.asMap().entries.map((entry) {
                      final ingredient = entry.value;
                      final index = pantryIndexes[entry.key];
                      double quantity = (quantities[index] / widget.recipe.numPersons) * _numOfPeople;
                      String quantityStr = quantity == 0 ? "Al gusto" : formatQuantity(quantity, units[index]);
                      return ListTile(
                        leading: SvgPicture.asset(
                          'assets/ingredients/${ingredient.icon}.svg',
                          height: 30.0,
                        ),
                        title: Text(ingredient.name),
                        trailing: ScaleTransition(
                          scale: Tween(begin: 1.0, end: 1.6).animate(scaleUnitController!),
                          child: Text(quantityStr),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          );
        }
      },
    );
  }


  String formatQuantity(double quantity, String unit) {
    if (quantity == 0) {
      return unit;
    } else {

      Map<double, String> fractions = {
        1/2: '1/2',
        1/3: '1/3',
        1/4: '1/4',
        2/3: '2/3',
        3/4: '3/4'
      };


      for (double fraction in fractions.keys) {
        if ((quantity - fraction).abs() < 0.01) {
          return '${fractions[fraction]} $unit';
        }
      }

      // Remove trailing zeros
      String trimmed = quantity.toStringAsFixed(2).replaceAll(RegExp(r'(\.0*|(?<=\..*)0+)$'), '');
      return '$trimmed $unit';
    }
  }

  // Pestaña con Intrucciones
  Widget buildInstructionsTab(List<String> instructions) {
    return ListView.builder(
      itemCount: instructions.length,
      itemBuilder: (context, index) {
        String instruction = instructions[index];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Alinea los elementos de la fila al inicio
          children: [
            Align(
              alignment: Alignment.topCenter, // Alinea el CircleAvatar al inicio
              child: CircleAvatar(
                child: Text('${index + 1}'),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(instruction),
              ),
            ),
          ],
        );
      },
    );
  }

  // Comprueba si la url es de yotube
  bool isYoutubeUrl(String? url) {
    if (url == null) {
      return false;
    }

    final RegExp regex = RegExp(
      r'(http(s)?:\/\/)?((w){3}.)?youtu(be|.be)?(\.com)?\/.+',
      caseSensitive: false,
    );
    return regex.hasMatch(url);
  }

  // Comprueba si la url es de tiktok
  bool isTiktokUrl(String? url) {
    if (url == null) {
      return false;
    }

    final RegExp regex = RegExp(
      r'(http(s)?:\/\/)?((w){3}.)?tiktok\.com\/.+',
      caseSensitive: false,
    );
    return regex.hasMatch(url);
  }

  // Comprueba si la url es de instagram
  bool isInstagramUrl(String? url) {
    if (url == null) {
      return false;
    }

    final RegExp regex = RegExp(
      r'(http(s)?:\/\/)?((w){3}.)?instagram\.com\/.+',
      caseSensitive: false,
    );
    return regex.hasMatch(url);
  }

  // Construye la pestaña de videos y lanza la url seleccionada
  Widget buildVideoTab(Recipe recipe) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50.0),
      child: ListView(
        children: <Widget>[
          if (recipe.youtubeUrl != null && isYoutubeUrl(recipe.youtubeUrl!))
            OutlinedButton(
              onPressed: () {
                Uri youtubeUri = Uri.parse(recipe.youtubeUrl!);
                launchUrl(youtubeUri);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FontAwesomeIcons.youtube, color: Theme.of(context).dividerColor),
                  SizedBox(width: 10),
                  Text('Ver video en YouTube', style: TextStyle(color: Theme.of(context).dividerColor)),
                ],
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
                backgroundColor: Colors.transparent,
              ),
            ),
          if (recipe.tiktokUrl != null && isTiktokUrl(recipe.tiktokUrl!))
            OutlinedButton(
              onPressed: () {
                Uri tiktokUri = Uri.parse(recipe.tiktokUrl!);
                launchUrl(tiktokUri);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FontAwesomeIcons.tiktok, color: Theme.of(context).dividerColor),
                  SizedBox(width: 10),
                  Text('Ver video en TikTok', style: TextStyle(color: Theme.of(context).dividerColor)),
                ],
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
                backgroundColor: Colors.transparent,
              ),
            ),
          if (recipe.instagramUrl != null && isInstagramUrl(recipe.instagramUrl!))
            OutlinedButton(
              onPressed: () {
                Uri instagramUri = Uri.parse(recipe.instagramUrl!);
                launchUrl(instagramUri);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FontAwesomeIcons.instagram, color: Theme.of(context).dividerColor),
                  SizedBox(width: 10),
                  Text('Ver video en Instagram', style: TextStyle(color: Theme.of(context).dividerColor)),
                ],
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
                backgroundColor: Colors.transparent,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> updateLikes() async {
    // Comprueba si el id de la receta está en LocalStorage().getLikeRecipes()
    bool isLikedInLocalStorage = LocalStorage().getLikeRecipe(widget.recipe.id) != null;

    if (!(isLikedInLocalStorage && !_isLiked) && !(!isLikedInLocalStorage && _isLiked)) {
      Log.i('No changes to perform on likes.');
      return;
    }

    String email = LocalStorage().getEmail();
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final recipeDocumentRef = FirebaseFirestore.instance.collection('recipes').doc(widget.recipe.id);
        final userDocumentRef = FirebaseFirestore.instance.collection('users').doc(userId);

        final recipeSnapshot = await transaction.get(recipeDocumentRef);
        final userSnapshot = await transaction.get(userDocumentRef);

        List<dynamic> currentLikes = recipeSnapshot.data()?['likes'] ?? [];
        List<dynamic> currentLikesRecipes = userSnapshot.data()?['likesRecipes'] ?? [];
        int currentLikesCount = recipeSnapshot.data()?['likesCount'] ?? 0;

        // Verifica si necesitamos remover el email del usuario de los likes
        if (isLikedInLocalStorage && !_isLiked) {
          Log.i('Removing like...');
          transaction.update(recipeDocumentRef, {
            'likes': FieldValue.arrayRemove([email]),
            'likesCount': currentLikesCount > 0 ? currentLikesCount - 1 : 0
          });
          transaction.update(userDocumentRef, {
            'likesRecipes': FieldValue.arrayRemove([widget.recipe.id])
          });
          await LocalStorage().deleteLikeRecipe(widget.recipe.id); // Elimina la receta de _likesRecipesBox
          Log.i('Like removed successfully.');
        }
        // Verifica si necesitamos añadir el email del usuario a los likes
        else if (!isLikedInLocalStorage && _isLiked) {
          Log.i('Adding like...');
          transaction.update(recipeDocumentRef, {
            'likes': FieldValue.arrayUnion([email]),
            'likesCount': currentLikesCount + 1
          });
          transaction.update(userDocumentRef, {
            'likesRecipes': FieldValue.arrayUnion([widget.recipe.id])
          });
          await LocalStorage().addLikeRecipe(widget.recipe); // Añade la receta a _likesRecipesBox
          Log.i('Like added successfully.');
        }
      });
    } catch (e) {
      Log.e('Error updating likes: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    final double tempHeight = MediaQuery.of(context).size.height - (MediaQuery.of(context).size.width / 1.2) +  24.0;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: () async {
        updateLikes();
        return true;
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
                bottom: screenHeight - infoHeight,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Image.memory(
                    widget.recipe.image,
                    fit: BoxFit.cover,
                  ),
                )
            ),
            NestedScrollView(
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    expandedHeight: screenWidth / 1.3,
                    floating: true,
                    snap: false,
                    pinned: true,
                    actions: <Widget>[
                      if (LocalStorage().getUserRole() == 'ADMIN' || LocalStorage().getUserRole() == 'SUPERADMIN')
                        PopupMenuButton<String>(
                          onSelected: (String result) {
                            switch (result) {
                              case 'opcion1':
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(
                                        widget.recipe.name,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      content: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.access_time),
                                              SizedBox(width: 8.0),
                                              Flexible( // Añade Flexible aquí
                                                child: RichText(
                                                  text: TextSpan(
                                                    text: 'Creada en: ',
                                                    style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.bold),
                                                    children: <TextSpan>[
                                                      TextSpan(text: widget.recipe.createdAt, style: TextStyle(fontWeight: FontWeight.normal)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8.0),
                                          Row(
                                            children: [
                                              Icon(Icons.person),
                                              SizedBox(width: 8.0),
                                              Flexible( // Añade Flexible aquí
                                                child: RichText(
                                                  text: TextSpan(
                                                    text: 'Autor: ',
                                                    style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.bold),
                                                    children: <TextSpan>[
                                                      TextSpan(text: widget.recipe.emailUser, style: TextStyle(fontWeight: FontWeight.normal)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8.0),
                                          Row(
                                            children: [
                                              Icon(Icons.vpn_key),
                                              SizedBox(width: 8.0),
                                              Flexible( // Añade Flexible aquí
                                                child: RichText(
                                                  text: TextSpan(
                                                    text: 'ID: ',
                                                    style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.bold),
                                                    children: <TextSpan>[
                                                      TextSpan(text: widget.recipe.id, style: TextStyle(fontWeight: FontWeight.normal)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8.0),
                                          Row(
                                            children: [
                                              Icon(Icons.favorite),
                                              SizedBox(width: 8.0),
                                              Flexible( // Añade Flexible aquí
                                                child: RichText(
                                                  text: TextSpan(
                                                    text: 'Likes: ',
                                                    style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.bold),
                                                    children: <TextSpan>[
                                                      TextSpan(text: '${widget.recipe.likes.length}', style: TextStyle(fontWeight: FontWeight.normal)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8.0),
                                          Row(
                                            children: [
                                              Icon(Icons.label),
                                              SizedBox(width: 8.0),
                                              Flexible(
                                                child: RichText(
                                                  text: TextSpan(
                                                    text: 'Etiquetas: ',
                                                    style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.bold),
                                                    children: <TextSpan>[
                                                      TextSpan(text: '${widget.recipe.tags.join(', ')}', style: TextStyle(fontWeight: FontWeight.normal)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8.0),
                                          Row(
                                            children: [
                                              Icon(Icons.restaurant_menu),
                                              SizedBox(width: 8.0),
                                              Flexible(
                                                child: RichText(
                                                  text: TextSpan(
                                                    text: 'Ingredientes: ',
                                                    style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.bold),
                                                    children: <TextSpan>[
                                                      TextSpan(text: '${widget.recipe.ingredients.join(', ')}', style: TextStyle(fontWeight: FontWeight.normal)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8.0),
                                          Text('Visible: ${widget.recipe.visible ? 'True' : 'False'}'),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('Cerrar'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                break;
                              case 'opcion2':
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Lista de Likes'),
                                      content: Container(
                                        width: double.maxFinite,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: widget.recipe.likes.length,
                                          itemBuilder: (BuildContext context, int index) {
                                            return ListTile(
                                              title: Text(widget.recipe.likes[index]),
                                            );
                                          },
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('Cerrar'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                break;
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'opcion1',
                              child: Text('Información (ADMIN)'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'opcion2',
                              child: Text('Lista de Likes (ADMIN)'),
                            ),
                          ],
                        ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PhotoViewPage(
                                imageUint8List: widget.recipe.image,
                                title: widget.recipe.name,
                              ),
                            ),
                          );
                        },
                        child: ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.transparent, Colors.black],
                              stops: [0.0, 0.2],  // Estos valores determinan dónde empieza y termina el efecto difuminado
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.dstIn,  // El modo de fusión sigue siendo adecuado para este efecto
                          child: Image.memory(
                            widget.recipe.image,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),

                ];
              },
              body: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30.0),
                      topRight: Radius.circular(30.0)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        offset: const Offset(1.1, 1.1),
                        blurRadius: 10.0),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      header(),
                      textDescription(widget.recipe.description),
                      SizedBox(height: 8.0),
                      buildRecipeTags(widget.recipe),

                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 600),
                        opacity: opacity2,
                        child: TabBar(
                          controller: _tabController,
                          tabs: [
                            Tab(text: 'Ingredientes'),
                            Tab(text: 'Instrucciones'),
                            if ( numVideos > 0)
                              Tab(text: numVideos > 1 ? 'Vídeos' : 'Vídeo'),
                          ],
                        ),
                      ),

                      Expanded(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 800),
                          opacity: opacity2,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              buildIngredientsTab(widget.recipe.ingredients, widget.recipe.quantities, widget.recipe.units),
                              buildInstructionsTab(widget.recipe.instructions),
                              if (numVideos > 0) buildVideoTab(widget.recipe),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
