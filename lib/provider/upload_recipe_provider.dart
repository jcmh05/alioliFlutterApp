import 'dart:io';
import 'dart:typed_data';

import 'package:alioli/components/components.dart';
import 'package:alioli/models/models.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../components/logging.dart';

class UploadRecipesService {
  final Log = logger(UploadRecipesService);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;



  Future<String> uploadRecipe(Recipe recipe) async {
    try {
      Log.i('Comenzando la subida de la receta...');

      // Verificar si el usuario está registrado y verificado
      await _auth.currentUser!.reload();
      User? currentUser = _auth.currentUser;

      if (currentUser == null || !currentUser.emailVerified) {
        Log.e('El usuario que trata de subir la receta no está registrado o verificado');
        return '';
      }

      String newRecipeId = _firestore.collection('recipes').doc().id;

      String imageUrl = '';
      if (recipe.image != null) {
        String direction = 'recipes/${newRecipeId}.jpg';
        imageUrl = await uploadImage(direction, recipe.image!);
      }

      // Inicializar los campos adicionales
      int likesCount = 0;
      bool isVegan = recipe.tags.contains('vegan');
      bool isVegetarian = recipe.tags.contains('vegetarian');

      final recipeData = recipe.toMap();

      // Agregar los campos adicionales al mapa
      recipeData['id'] = newRecipeId;
      recipeData['emailUser'] = currentUser.email;
      recipeData['image'] = imageUrl;
      recipeData['likesCount'] = likesCount;
      recipeData['isVegan'] = isVegan;
      recipeData['isVegetarian'] = isVegetarian;
      recipeData['keywords'] = extractKeywords(recipe.name);

      Log.i('Subiendo receta con datos: ' + recipeData.toString());

      await _firestore.collection('recipes').doc(newRecipeId).set(recipeData);

      await _firestore.collection('users').doc(currentUser.uid).update({
        'recipes': FieldValue.arrayUnion([newRecipeId])
      });

      Log.i('Receta subida correctamente');

      return newRecipeId;
    } catch (e) {
      Log.e('Error al intentar subir la receta: $e');
      return '';
    }
  }

  // Función para subir la imagen a Firebase Storage y obtener la URL
  Future<String> uploadImage(String ref, Uint8List image) async {
    final UploadTask uploadTask = _storage.ref().child(ref).putData(image);
    final TaskSnapshot taskSnapshot = await uploadTask;
    final String url = await taskSnapshot.ref.getDownloadURL();
    Log.i('Imagen subida correctamente en ' + url);
    return url;
  }

}