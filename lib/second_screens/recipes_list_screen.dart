import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:alioli/components/components.dart';
import 'package:alioli/models/models.dart';

import '../services/local_storage.dart';

class RecipeListScreen extends StatefulWidget {
  final List<Recipe> recipes;
  final String title;
  final String idList;

  RecipeListScreen({Key? key, required this.recipes, required this.title, required this.idList}) : super(key: key);

  @override
  _RecipeListScreenState createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  List<Recipe> filteredRecipes = [];
  TextEditingController searchController = TextEditingController();
  String filter = 'Ordenar por';
  bool isVegan = false;
  bool isVegetarian = false;

  @override
  void initState() {
    super.initState();
    filteredRecipes = widget.recipes;
    searchController.addListener(applyFilters);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void applyFilters() {
    List<Recipe> tempRecipes = widget.recipes;

    // Filter by name
    String searchText = searchController.text;
    if (searchText.isNotEmpty) {
      tempRecipes = tempRecipes.where((recipe) => recipe.name.toLowerCase().contains(searchText.toLowerCase())).toList();
    }

    // Filter by tags
    if (isVegan) {
      tempRecipes = tempRecipes.where((recipe) => recipe.tags.contains('vegan')).toList();
    }
    if (isVegetarian) {
      tempRecipes = tempRecipes.where((recipe) => recipe.tags.contains('vegetarian')).toList();
    }

    // Sort by selected filter
    switch (filter) {
      case 'Menor tiempo':
        tempRecipes.sort((a, b) => a.minutes.compareTo(b.minutes));
        break;
      case 'Orden de adición':
      // No action needed, as the original order is the order of addition
        break;
    }

    setState(() {
      filteredRecipes = tempRecipes;
    });
  }

  void searchRecipes() {
    String searchText = searchController.text;
    if (searchText.isEmpty) {
      setState(() {
        filteredRecipes = widget.recipes;
      });
    } else {
      List<Recipe> tempRecipes = [];
      for (var recipe in widget.recipes) {
        if (recipe.name.toLowerCase().contains(searchText.toLowerCase())) {
          tempRecipes.add(recipe);
        }
      }
      setState(() {
        filteredRecipes = tempRecipes;
      });
    }
    applyFilter();
  }

  void applyFilter() {
    List<Recipe> tempRecipes = widget.recipes;
    if (isVegan) {
      tempRecipes = tempRecipes.where((recipe) => recipe.tags.contains('vegan')).toList();
    }
    if (isVegetarian) {
      tempRecipes = tempRecipes.where((recipe) => recipe.tags.contains('vegetarian')).toList();
    }
    switch (filter) {
      case 'Menor tiempo':
        tempRecipes.sort((a, b) => a.minutes.compareTo(b.minutes));
        break;
      case 'Orden de adición':
      // No action needed, as the original order is the order of addition
        break;
    }
    setState(() {
      filteredRecipes = tempRecipes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.0),
                border: Border.all(color: Colors.grey.withOpacity(0.5)),
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  icon: Icon(Icons.search),
                  hintText: 'Buscar por nombre...',
                  border: InputBorder.none,
                ),
              ),
            ),
            SizedBox(height: 15),
            Container(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  PopupMenuButton<String>(
                    onSelected: (String value) {
                      setState(() {
                        filter = value;
                        applyFilter();
                      });
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'Orden de adición',
                        child: Text('Por orden'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Menor tiempo',
                        child: Text('Por tiempo'),
                      ),
                    ],
                    child: Chip(
                      label: Text(filter), // Use the filter variable for the button text
                      avatar: Icon(Icons.sort),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('Vegano'),
                    avatar: Icon(AppTheme.categoryIcons['vegan']),
                    selected: isVegan,
                    onSelected: (bool selected) {
                      setState(() {
                        isVegan = selected;
                        if (selected) {
                          isVegetarian = false;
                        }
                        applyFilter();
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('Vegetariano'),
                    avatar: Icon(AppTheme.categoryIcons['vegetarian']),
                    selected: isVegetarian,
                    onSelected: (bool selected) {
                      setState(() {
                        isVegetarian = selected;
                        if (selected) {
                          isVegan = false;
                        }
                        applyFilter();
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15),
            if (filteredRecipes.isEmpty)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 20.0,),
                    placeholderIconText(
                        context,
                        MediaQuery.of(context).platformBrightness==Brightness.dark ? 'assets/noresult2.svg' :  'assets/noresults.svg',
                        'No se han encontrado recetas',
                        'Prueba a cambiar los filtros o buscar otras recetas',
                        0.8
                    ),
                  ],
                ),
              ),
            if (filteredRecipes.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: filteredRecipes.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: GestureDetector(
                          onLongPress: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Eliminar receta'),
                                  content: Text('¿Desea eliminar la receta ${filteredRecipes[index].name} de la lista ${widget.title}?'),
                                  actions: <Widget>[
                                    TextButton(
                                      child: Text('Cancelar'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    TextButton(
                                      child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                                      onPressed: () async {
                                        if (widget.idList == "likelist") {
                                          // Obtén las referencias a los documentos
                                          final recipeDocumentRef = FirebaseFirestore.instance.collection('recipes').doc(filteredRecipes[index].id);
                                          final userDocumentRef = FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid);

                                          // Ejecuta la transacción
                                          await FirebaseFirestore.instance.runTransaction((transaction) async {
                                            final recipeSnapshot = await transaction.get(recipeDocumentRef);
                                            final userSnapshot = await transaction.get(userDocumentRef);

                                            List<dynamic> currentLikes = recipeSnapshot.data()?['likes'] ?? [];
                                            List<dynamic> currentLikesRecipes = userSnapshot.data()?['likesRecipes'] ?? [];
                                            int currentLikesCount = recipeSnapshot.data()?['likesCount'] ?? 0;

                                            // Actualiza Firestore
                                            transaction.update(recipeDocumentRef, {
                                              'likes': FieldValue.arrayRemove([LocalStorage().getEmail()]),
                                              'likesCount': currentLikesCount > 0 ? currentLikesCount - 1 : 0
                                            });
                                            transaction.update(userDocumentRef, {
                                              'likesRecipes': FieldValue.arrayRemove([filteredRecipes[index].id])
                                            });

                                            // Actualiza LocalStorage
                                            await LocalStorage().deleteLikeRecipe(filteredRecipes[index].id);
                                          });
                                        }else{
                                          // Obtén la referencia al documento
                                          final docRef = FirebaseFirestore.instance.collection('recipe_list').doc(widget.idList);

                                          // Ejecuta la transacción
                                          await FirebaseFirestore.instance.runTransaction((transaction) async {
                                            final docSnapshot = await transaction.get(docRef);

                                            List<dynamic> currentRecipes = docSnapshot.data()?['recipes'] ?? [];

                                            // Actualiza Firestore
                                            transaction.update(docRef, {
                                              'recipes': FieldValue.arrayRemove([filteredRecipes[index].id])
                                            });

                                            // Actualiza LocalStorage
                                            await LocalStorage().removeRecipeFromList(widget.idList, filteredRecipes[index]);
                                          }); 
                                        }
                                        Navigator.of(context).pop();
                                        setState(() {
                                          filteredRecipes.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: RecipeCard(recipe: filteredRecipes[index], mode: 1, offline_mode: true,)
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}