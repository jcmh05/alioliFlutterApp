import 'dart:io';
import 'dart:typed_data';
import 'package:alioli/components/components.dart';
import 'package:alioli/services/push_notification.dart';
import 'package:crypt/crypt.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'package:alioli/models/models.dart';
import '../components/logging.dart';

enum AuthStatus {
  NOT_DETERMINED,
  NOT_LOGGED_IN,
  LOGGED_IN,
}

class LoginProvider with ChangeNotifier {
  final Log = logger(LoginProvider);
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthStatus authStatus = AuthStatus.NOT_DETERMINED;

  Future<void> signInWithGoogle({
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    try {
      Log.i('Iniciando sesión con Google...');
      UserCredential userCredential;

      if (kIsWeb) {
        // Para aplicaciones web
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // Para aplicaciones móviles
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          // El usuario canceló el inicio de sesión
          Log.i('Inicio de sesión con Google cancelado por el usuario');
          onError('Inicio de sesión con Google cancelado');
          return;
        }


        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      User? user = userCredential.user;
      if (user == null) {
        Log.e('Error al obtener información del usuario de Google');
        return;
      }

      // Verificar si el usuario ya existe en Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Si el usuario no existe, crear un nuevo documento en Firestore
        Log.i('El usuario no existe en Firestore, creando nuevo usuario...');
        String username = user.displayName ?? 'Usuario';
        String email = user.email!;
        String? photoUrl = user.photoURL;

        // Descargar la foto de perfil y subirla a Firebase Storage
        String imageUrl = '';
        if (photoUrl != null && photoUrl.isNotEmpty) {
          imageUrl = await _uploadImageFromUrl(photoUrl, 'users/$email/profile_pic.jpg');
        }

        final userData = {
          'username': username,
          'username_lowercase': username.toLowerCase(),
          'password': null,
          'email': email,
          'rol': 'USER',
          'token': PushNotificationService.token,
          'image': imageUrl,
          'createdAt': DateTime.now().toString(),
        };

        await _firestore.collection('users').doc(user.uid).set(userData);
        Log.i('Usuario creado en Firestore');
      } else {
        Log.i('El usuario ya existe en Firestore, iniciando sesión...');
      }

      // Llama a onSuccess para continuar con los procesos adicionales
      onSuccess();
    } on FirebaseAuthException catch (e) {
      Log.e('Error de FirebaseAuth al iniciar sesión con Google: $e');
      onError('Error al iniciar sesión con Google: ${e.message}');
    } catch (e) {
      Log.e('Error al iniciar sesión con Google: $e');
      onError('Error al iniciar sesión con Google');
    }
  }

  // Método auxiliar para descargar y subir la imagen de perfil
  Future<String> _uploadImageFromUrl(String imageUrl, String storagePath) async {
    try {
      final http.Response response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        Uint8List data = response.bodyBytes;
        final UploadTask uploadTask = _storage.ref().child(storagePath).putData(data);
        final TaskSnapshot taskSnapshot = await uploadTask;
        final String url = await taskSnapshot.ref.getDownloadURL();
        Log.i('Imagen de perfil subida correctamente en $url');
        return url;
      } else {
        Log.e('Error al descargar la imagen de perfil de Google');
        return '';
      }
    } catch (e) {
      Log.e('Error al subir la imagen de perfil: $e');
      return '';
    }
  }

  Future<void> loginUser({
    required String email,
    required String password,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    try {
      Log.i('Iniciando sesión...');

      // Obtener los datos del usuario desde Firestore
      final userData = await getUserData(email);
      if (userData == null) {
        onError('No se encontraron datos del usuario');
        return;
      }

      // Verificar si la contraseña ingresada coincide con el hash almacenado
      String storedPasswordHash = userData['password'];

      if (Crypt(storedPasswordHash).match(password)) {

        Log.i("Hash verificado respecto a la base de datos");
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        Log.i('Sesión iniciada correctamente');
        onSuccess();

      } else {
        // La contraseña no coincide
        throw FirebaseAuthException(
          code: "wrong-password",
          message: "Contraseña incorrecta",
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == "wrong-password") {
        Log.e('Usuario o contraseña incorrectos');
        onError('Usuario o contraseña incorrectos');
      } else {
        Log.e('Error al iniciar sesión: ${e.message}');
        onError(e.message ?? e.toString());
      }
    } catch (e) {
      Log.e('Error al iniciar sesión: $e');
      onError(e.toString());
    }
  }


  // Verificar el estado del usuario
  void checkAuthState() {
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        authStatus = AuthStatus.NOT_LOGGED_IN;
      } else {
        authStatus = AuthStatus.LOGGED_IN;
      }
      notifyListeners();
    });
  }

  // Obtener datos del usuario
  Future<dynamic> getUserData(String email) async {
    final QuerySnapshot <Map<String, dynamic>> result = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (result.docs.isNotEmpty) {
      final userData = result.docs[0].data();
      Log.i('getUserData: ' + userData.toString());
      return userData;
    }else{
      Log.i('getUserData: No se encontraron datos del usuario');
    }

    return null;
  }

  // Obtener el nombre de usuario de _firestore
  Future<String> getUsername(String email) async {
    final QuerySnapshot <Map<String, dynamic>> result = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (result.docs.isNotEmpty) {
      final userData = result.docs[0].data();
      Log.i('getUsername: ' + userData['username']);
      return userData['username'];
    }else{
      Log.i('getUsername: No se encontró el nombre de usuario');
    }

    return '';
  }

  // Obtener el rol del usuario de firestore
  Future<String> getUserRole(String email) async {
    final QuerySnapshot <Map<String, dynamic>> result = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (result.docs.isNotEmpty) {
      final userData = result.docs[0].data();
      Log.i('getUserRole: ' + userData['rol']);
      return userData['rol'];
    }else{
      Log.i('getUserRole: No se encontró el rol del usuario');
    }

    return '';
  }

  // Obtener url del usuario
  Future<String> getImageUrl(String email) async {
    final QuerySnapshot <Map<String, dynamic>> result = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (result.docs.isNotEmpty) {
      final userData = result.docs[0].data();
      Log.i('getImageUrl: ' + userData['image']);
      return userData['image'];
    }else{
      Log.i('getImageUrl: No se encontró la imagen');
    }

    return '';
  }

  // Obtener el ID del usuario
  String? getUserId() {
    User? currentUser = _auth.currentUser;
    return currentUser?.uid;
  }

  // Obtiene la lista de recetas asociadas al usuario
  Future<List<Recipe>> getRecipes() async {
    try {
      Log.i('Obteniendo recetas del usuario...');

      // Verificar si el usuario está registrado y verificado
      User? currentUser = _auth.currentUser;
      if (currentUser == null || !currentUser.emailVerified) {
        Log.e('El usuario que trata de obtener las recetas no está registrado o verificado');
        return [];
      }

      // Obtener el documento del usuario
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();

      // Verificar si el usuario tiene recetas
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      if (!userDoc.exists || !(userData?.containsKey('recipes') ?? false)) {
        Log.i('El usuario no tiene recetas');
        return [];
      }

      // Obtener los IDs de las recetas del usuario
      List<String> recipeIds = List<String>.from(userData?['recipes'] ?? []);


      // Obtener las recetas correspondientes a los IDs
      List<Recipe> recipes = [];
      for (String id in recipeIds) {
        DocumentSnapshot recipeDoc = await _firestore.collection('recipes').doc(id).get();
        Recipe recipeData = await convertDocToRecipe(recipeDoc);
        recipes.add(recipeData);
      }

      Log.i('Recetas obtenidas correctamente: ' + recipes.toString());
      return recipes;
    } catch (e) {
      Log.e('Error al intentar obtener las recetas: $e');
      return [];
    }
  }

  // Obtiene la lista de recetas que le gustan al usuario
  Future<List<Recipe>> getLikedRecipes() async {
    try {
      Log.i('Obteniendo recetas que le gustan al usuario...');

      // Verificar si el usuario está registrado y verificado
      User? currentUser = _auth.currentUser;
      if (currentUser == null || !currentUser.emailVerified) {
        Log.e('El usuario que trata de obtener las recetas no está registrado o verificado');
        return [];
      }

      // Obtener el documento del usuario
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();

      // Verificar si el usuario tiene recetas que le gustan
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      if (!userDoc.exists || !(userData?.containsKey('likesRecipes') ?? false)) {
        Log.i('El usuario no tiene recetas que le gustan');
        return [];
      }

      // Obtener los IDs de las recetas que le gustan al usuario
      List<String> recipeIds = List<String>.from(userData?['likesRecipes'] ?? []);

      // Obtener las recetas correspondientes a los IDs
      List<Recipe> recipes = [];
      for (String id in recipeIds) {
        DocumentSnapshot recipeDoc = await _firestore.collection('recipes').doc(id).get();
        Recipe recipeData = await convertDocToRecipe(recipeDoc);
        recipes.add(recipeData);
      }

      Log.i('Recetas que le gustan al usuario obtenidas correctamente: ' + recipes.toString());
      return recipes;
    } catch (e) {
      Log.e('Error al intentar obtener las recetas que le gustan al usuario: $e');
      return [];
    }
  }

  // Obtiene la lista de RecipeList asociadas al usuario
  Future<List<RecipeList>> getUserRecipeLists() async {
    try {
      Log.i('Obteniendo RecipeList del usuario...');

      // Verificar si el usuario está registrado y verificado
      User? currentUser = _auth.currentUser;
      if (currentUser == null || !currentUser.emailVerified) {
        Log.e('El usuario que trata de obtener las RecipeList no está registrado o verificado');
        return [];
      }

      // Obtener el documento del usuario
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();

      // Verificar si el usuario tiene RecipeList
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      if (!userDoc.exists || !(userData?.containsKey('recipeList') ?? false)) {
        Log.i('El usuario no tiene RecipeList');
        return [];
      }

      // Obtener los IDs de las RecipeList del usuario
      List<String> recipeListIds = List<String>.from(userData?['recipeList'] ?? []);

      // Obtener las RecipeList correspondientes a los IDs
      List<RecipeList> recipeLists = [];
      for (String id in recipeListIds) {
        DocumentSnapshot recipeListDoc = await _firestore.collection('recipe_list').doc(id).get();
        Map<String, dynamic> recipeListData = recipeListDoc.data() as Map<String, dynamic>;
        List<String> recipeIds = List<String>.from(recipeListData['recipes'] ?? []);

        recipeListData['recipes'] = [];
        RecipeList recipeList = RecipeList.fromMap(recipeListData);

        // Obtener las recetas correspondientes a los IDs
        Log.i('Obteniendo recetas de la lista ' + id);

        for (String recipeId in recipeIds) {
          try {
            DocumentSnapshot recipeDoc = await _firestore.collection('recipes').doc(recipeId).get();
            Recipe recipeData = await convertDocToRecipe(recipeDoc);
            recipeList.addRecipe(recipeData);
            Log.i('Receta obtenida correctamente: ' + recipeData.toString());
          } catch (e) {
            Log.e('Error al obtener la receta con ID $recipeId: $e');
          }
        }

        recipeLists.add(recipeList);
      }

      Log.i('RecipeList obtenidas correctamente: ' + recipeLists.toString());
      return recipeLists;
    } catch (e) {
      Log.e('Error al intentar obtener las RecipeList: $e');
      return [];
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    Log.i('Sesión cerrada');
  }

}