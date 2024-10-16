import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:alioli/models/models.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'dart:io';
import 'package:http/http.dart' as http;
import '../components/logging.dart';



class LocalStorage{
  final Log = logger(LocalStorage);
  static final LocalStorage _instance = LocalStorage._internal();
  factory LocalStorage() => _instance;

  LocalStorage._internal();

  late Box _userBox;
  late Box _draftRecipesBox;
  late Box _publishedRecipesBox;
  late Box _preferencesBox;
  late Box _likesRecipesBox;
  late Box _recipeListBox;

  Future<void> init() async {
    // Inicializar Hive
    final appDocumentDirectory = await path_provider.getApplicationDocumentsDirectory();
    Hive.init(appDocumentDirectory.path);

    // Abrir la caja para almacenar las preferencias
    _preferencesBox = await Hive.openBox('preferences');

    // Abrir la caja para almacenar los datos de usuario
    _userBox = await Hive.openBox('user');

    // Abrir la caja para almacenar los borradores de las recetas
    _draftRecipesBox = await Hive.openBox('draftRecipes');

    // Abrir la caja para almacenar las recetas publicadas
    _publishedRecipesBox = await Hive.openBox('publishedRecipes');

    // Abrir la caja para almacenar las recetas a las que el usuario ha dado like
    _likesRecipesBox = await Hive.openBox('likesRecipes');

    // Abrir la caja para almacenar las listas de recetas
    _recipeListBox = await Hive.openBox('recipeLists');

    Log.i('LocalStorage inicializado');
  }

  /// /// /// /// /// /// /// /// /// //// /// /// /// /// /// /// /// /// ///
  /// /// /// /// /// /// / MÉTODOS PARA PREFERENCES / /// /// /// /// /// ///
  /// /// /// /// /// /// /// /// /// //// /// /// /// /// /// /// /// /// ///

  Future<void> setIsFirstTime(bool isFirstTime) async {
    await _preferencesBox.put('isFirstTime', isFirstTime);
    Log.i('isFirstTime guardado: $isFirstTime');
  }

  bool getIsFirstTime() {
    return _preferencesBox.get('isFirstTime', defaultValue: true) as bool;
  }


  Future<void> setInitialPage(int page) async {
    await _preferencesBox.put('initialPage', page);
    Log.i('Página inicial guardada: $page');
  }

  int getInitialPage() {
    return _preferencesBox.get('initialPage', defaultValue: 0) as int;
  }

  /// /// /// /// /// /// /// /// /// //// /// /// /// /// /// /// /// /// ///
  /// /// /// /// /// /// / MÉTODOS PARA USER_BOX  /// /// /// /// /// /// ///
  /// /// /// /// /// /// /// /// /// //// /// /// /// /// /// /// /// /// ///

  // Limpiar la caja de usuarios
  Future<void> clearUserBox() async {
    await _userBox.clear();
  }

  // Guardar los usuarios
  Future<void> saveUserData(String email, String password) async {
    await _userBox.put('email', email);
    await _userBox.put('password', password);
    Log.i('Datos de usuario guardados para ' + email);
  }

  // Obtener los usuarios
  Future<dynamic> getUserData(String email) async {
    // Obtener los datos de usuario de la caja
    final String password = _userBox.get('password', defaultValue: '');

    // Devolver datos
    return {
      'email': email,
      'password': password,
    };
  }

  // Guardar el valor de 'isLoggedIn' en la caja
  Future<void> setIsLoggedIn(bool isLoggedIn) async {
    await _userBox.put('isLoggedIn', isLoggedIn);
  }

  // Guarda el valor de 'username' en la caja
  String getUsername() {
    return _userBox.get('username', defaultValue: '') as String;
  }

  // Guarda el valor de 'email' en la caja
  String getEmail() {
    return _userBox.get('email', defaultValue: '') as String;
  }

  // Obtiene el valor de 'userId' de la caja
  String getUserId() {
    return _userBox.get('userId', defaultValue: '') as String;
  }

  // Get the 'userRole' value from the box
  String getUserRole() {
    return _userBox.get('userRole', defaultValue: '') as String;
  }

  // Guarda el valor de 'password' en la caja
  String getPassword() {
    return _userBox.get('password', defaultValue: '') as String;
  }


  // Guarda el valor de 'username' en la caja
  Future<void> setUsername(String username) async {
    await _userBox.put('username', username);
    Log.i('Username guardado: ' + username);
  }

  // Guarda el valor de 'email' en la caja
  Future<void> setEmail(String email) async {
    await _userBox.put('email', email);
    Log.i('Email guardado: ' + email);
  }

  // Guarda el valor de 'userId' en la caja
  Future<void> saveUserId(String userId) async {
    await _userBox.put('userId', userId);
    Log.i('UserId guardado: ' + userId);
  }

  // Save the 'userRole' value in the box
  Future<void> saveUserRole(String userRole) async {
    await _userBox.put('userRole', userRole);
    Log.i('UserRole saved: ' + userRole);
  }


  // Función para guardar imagen desde una URL
  Future<void> saveImageFromUrl(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      Log.e('URL de la imagen no proporcionada');
      return;
    }

    Uri? uri;
    try {
      uri = Uri.parse(imageUrl);
    } catch (e) {
      Log.e('URL de la imagen no válida: $imageUrl');
      return;
    }

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      await _userBox.put('image', response.bodyBytes);
      Log.i('Imagen guardada desde la URL: $imageUrl');
    } else {
      Log.e('Error al descargar la imagen de la URL: $imageUrl');
    }
  }

  // Guarda el valor de 'version' en la caja
  Future<void> setVersion(double version) async {
    await _userBox.put('version', version);
    Log.i('Versión guardada: ' + version.toString());
  }

  // Obtiene el valor de 'version' de la caja
  double getVersion() {
    return _userBox.get('version', defaultValue: 0.0) as double;
  }

  // Función para guardar imagen de perfil desde un archivo
  Future<void> saveImageFromFile(File imageFile) async {
    final Uint8List imageBytes = await imageFile.readAsBytes();
    await _userBox.put('image', imageBytes);
    Log.i('Imagen guardada desde el archivo: $imageFile');
  }

  // Función para extraer la imagen de perfil
  Image? getImage() {
    final Uint8List? imageBytes = _userBox.get('image');
    if (imageBytes != null) {
      return Image.memory(imageBytes);
    } else {
      return null;
    }
  }

  // Obtiene el valor de 'isLoggedIn' de la caja
  bool getIsLoggedIn() {
    return _userBox.get('isLoggedIn', defaultValue: false) as bool;
  }

  // Elimina el valor de 'isLoggedIn' de la caja
  Future<void> deleteIsLoggedIn() async {
    await _userBox.delete('isLoggedIn');
  }


  /// /// /// /// /// /// /// /// /// //// /// /// /// /// /// /// /// /// ///
  /// /// /// /// ///  MÉTODOS PARA DRAFT_RECIPES_BOX  /// /// /// /// /// ///
  /// /// /// /// /// /// /// /// /// //// /// /// /// /// /// /// /// /// ///


  // Método para agregar una receta a la lista de borradores
  Future<void> addDraftRecipe(Recipe recipe) async {
    await _draftRecipesBox.put(recipe.id, jsonEncode(recipe.toMap()));
    Log.i('Receta añadida a los borradores: ${recipe.id}');
  }

  // Método para obtener toda la lista de recetas en borradores
  List<Recipe> getDraftRecipes() {
    return _draftRecipesBox.values.map((recipe) => Recipe.fromMap(jsonDecode(recipe))).toList();
  }

  // Método para obtener una receta específica de la lista de borradores
  Recipe? getDraftRecipe(String id) {
    final recipeJson = _draftRecipesBox.get(id);
    if (recipeJson != null) {
      return Recipe.fromMap(jsonDecode(recipeJson));
    } else {
      return null;
    }
  }

  // Método para eliminar una receta específica de la lista de borradores
  Future<void> deleteDraftRecipe(String id) async {
    await _draftRecipesBox.delete(id);
    Log.i('Receta eliminada de los borradores: $id');
  }

  // Método para editar una receta específica en la lista de borradores
  Future<void> editDraftRecipe(Recipe recipe) async {
    if (_draftRecipesBox.containsKey(recipe.id)) {
      await _draftRecipesBox.put(recipe.id, jsonEncode(recipe.toMap()));
      Log.i('Receta editada en los borradores: ${recipe.id}');
    } else {
      Log.e('No se pudo editar la receta, no se encontró en los borradores: ${recipe.id}');
    }
  }

  // Limpiar la caja de borradores
  Future<void> clearRecipesDraftBox() async {
    await _draftRecipesBox.clear();
  }

  /// /// /// /// /// /// /// /// /// //// /// /// /// /// /// /// /// /// ///
  /// /// /// /// ///  MÉTODOS PARA PUBLISH_RECIPES_BOX // /// /// /// /// ///
  /// /// /// /// /// /// /// /// /// //// /// /// /// /// /// /// /// /// ///

  // Método para agregar una receta a la lista de publicadas
  Future<void> addPublishedRecipe(Recipe recipe) async {
    await _publishedRecipesBox.put(recipe.id, jsonEncode(recipe.toMap()));
    Log.i('Receta añadida a las publicadas: ${recipe.id}');
  }

  // Método para obtener toda la lista de recetas publicadas
  List<Recipe> getPublishedRecipes() {
    return _publishedRecipesBox.values.map((recipe) => Recipe.fromMap(jsonDecode(recipe))).toList();
  }

  // Método para obtener una receta específica de la lista de publicadas
  Recipe? getPublishedRecipe(String id) {
    final recipeJson = _publishedRecipesBox.get(id);
    if (recipeJson != null) {
      return Recipe.fromMap(jsonDecode(recipeJson));
    } else {
      return null;
    }
  }

  // Método para eliminar una receta específica de la lista de publicadas
  Future<void> deletePublishedRecipe(String id) async {
    await _publishedRecipesBox.delete(id);
    Log.i('Receta eliminada de las publicadas: $id');
  }

  // Método para editar una receta específica en la lista de publicadas
  Future<void> editPublishedRecipe(Recipe recipe) async {
    if (_publishedRecipesBox.containsKey(recipe.id)) {
      await _publishedRecipesBox.put(recipe.id, jsonEncode(recipe.toMap()));
      Log.i('Receta editada en las publicadas: ${recipe.id}');
    } else {
      Log.e('No se pudo editar la receta, no se encontró en las publicadas: ${recipe.id}');
    }
  }

  // Limpiar la caja de publicadas
  Future<void> clearPublishedRecipesBox() async {
    await _publishedRecipesBox.clear();
  }

  /// /// /// /// /// /// /// /// /// //// /// /// /// /// /// /// /// /// ///
  /// /// /// /// /// // MÉTODOS PARA LIKES_RECIPES_BOX // /// /// /// /// ///
  /// /// /// /// /// /// /// /// /// //// /// /// /// /// /// /// /// /// ///

  // Método para agregar una receta a la lista de likes
  Future<void> addLikeRecipe(Recipe recipe) async {
    await _likesRecipesBox.put(recipe.id, jsonEncode(recipe.toMap()));
    Log.i('Receta añadida a los likes: ${recipe.id}');
  }

  // Método que devuelve un booleano si la lista está vacía o no
  bool isLikeRecipesBoxEmpty() {
    return _likesRecipesBox.isEmpty;
  }

  // Método para obtener la imagen de la última receta de la lista
  Uint8List getLikeRecipeImage() {
    final recipeJson = _likesRecipesBox.values.last;
    final recipe = Recipe.fromMap(jsonDecode(recipeJson));
    return recipe.image;
  }

  // Método para obtener toda la lista de recetas a las que se ha dado like
  List<Recipe> getLikeRecipes() {
    return _likesRecipesBox.values.map((recipe) => Recipe.fromMap(jsonDecode(recipe))).toList();
  }

  // Método para obtener una receta específica de la lista de likes
  Recipe? getLikeRecipe(String id) {
    final recipeJson = _likesRecipesBox.get(id);
    if (recipeJson != null) {
      return Recipe.fromMap(jsonDecode(recipeJson));
    }
    return null;
  }

  // Método para eliminar una receta específica de la lista de likes
  Future<void> deleteLikeRecipe(String id) async {
    await _likesRecipesBox.delete(id);
    Log.i('Receta eliminada de los likes: $id');
  }

  // Limpiar la caja de likes
  Future<void> clearLikeRecipesBox() async {
    await _likesRecipesBox.clear();
  }

  /// /// /// /// /// /// /// /// /// //// /// /// /// /// /// /// /// /// ///
  /// /// /// /// /// /// MÉTODOS PARA RECIPES_LIST_BOX // /// /// /// /// ///
  /// /// /// /// /// /// /// /// /// //// /// /// /// /// /// /// /// /// ///

  bool isRecipeListEmpty() {
    return _recipeListBox.isEmpty;
  }

  Future<void> addRecipeList(RecipeList recipeList) async {
    await _recipeListBox.put(recipeList.idList, jsonEncode(recipeList.toMap()));
    Log.i('RecipeList added: ${recipeList.idList}');
  }

  // Method to get all recipe lists
  List<RecipeList> getRecipeLists() {
    var values = _recipeListBox.values;
    if (values != null) {
      return values.map((list) => RecipeList.fromMap(jsonDecode(list))).toList();
    } else {
      return [];
    }
  }

  // Method to get a specific recipe list
  RecipeList? getRecipeList(String id) {
    final listJson = _recipeListBox.get(id);
    if (listJson != null) {
      return RecipeList.fromMap(jsonDecode(listJson));
    } else {
      return null;
    }
  }

  // Method to add a recipe to a specific list
  Future<void> addRecipeToList(String listId, Recipe recipe) async {
    RecipeList? recipeList = getRecipeList(listId);
    if (recipeList != null) {
      recipeList.recipes.add(recipe);
      await _recipeListBox.put(listId, jsonEncode(recipeList.toMap()));
      Log.i('Recipe added to list: ${recipe.id}');
    } else {
      Log.e('Could not find the list: $listId');
    }
  }

  // Método para eliminar una receta de una lista específica
  Future<void> removeRecipeFromList(String listId, Recipe recipe) async {
    RecipeList? recipeList = getRecipeList(listId);
    if (recipeList != null) {
      recipeList.recipes.removeWhere((item) => item.id == recipe.id);
      await _recipeListBox.put(listId, jsonEncode(recipeList.toMap()));
      Log.i('Recipe removed from list: ${recipe.id}');
    } else {
      Log.e('Could not find the list: $listId');
    }
  }

  // Comprueba si la receta está en alguna lista
  bool isRecipeInAnyList(String recipeId) {
    List<RecipeList> recipeLists = getRecipeLists();
    for (RecipeList recipeList in recipeLists) {
      for (Recipe recipe in recipeList.recipes) {
        if (recipe.id == recipeId) {
          return true;
        }
      }
    }
    return false;
  }

  // Method to delete a specific recipe list
  Future<void> deleteRecipeList(String id) async {
    await _recipeListBox.delete(id);
    Log.i('RecipeList deleted: $id');
  }

  // Method to clear all recipe lists
  Future<void> clearRecipeLists() async {
    await _recipeListBox.clear();
    Log.i('All RecipeLists deleted');
  }
}