import 'dart:io';

import 'package:crypt/crypt.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../components/logging.dart';

enum UserRole {
  ADMIN,
  USER,
  SUPERADMIN
}

class RegisterProvider extends ChangeNotifier {
  final Log = logger(RegisterProvider);
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String encryptPassword(String password) {
    return Crypt.sha256(password).toString();
  }

  Future<void> registerUser({
    required String username,
    required String email,
    required String password,
    required UserRole rol,
    required String token,
    required String createdAt,
    required File? image,
    // required Function onSuccess,
    required Function(String) onError,
  }) async {
    try {
      Log.i('Comenzando registro...');
      // Convertir el username a minúsculas
      final String usernameLowerCase = username.toLowerCase();

      // Verificar si el username ya existe en la base de datos
      final bool userExists = await checkUserExists(usernameLowerCase);

      if (userExists) {
        Log.e('El usuario ya existe');
        onError('El usuario ya existe');
        return;
      }

      // Verificar las credenciales del usuario
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User user = userCredential.user!;
      final String? userId = user.uid;

      // Subir la imagen a Firebase Storage
      String imageUrl = '';
      if (image != null) {
        String direction = 'users/$email/profile_pic.jpg';
        imageUrl = await uploadImage(direction, image);
      }

      // Guardar los datos del usuario en la base de datos
      final userDatos = {
        'username': username,
        'username_lowercase': usernameLowerCase,
        'password': encryptPassword(password),
        'email': email,
        'rol': rol.toString().split('.').last,
        'token': token,
        'image': imageUrl,
        'createdAt': createdAt,
      };
      Log.i('Registrando usuario con datos: ' + userDatos.toString());
      await _firestore.collection('users').doc(userId).set(userDatos);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        Log.e('La contraseña es muy débil');
        onError('La contraseña es muy débil');
      } else if (e.code == 'email-already-in-use') {
        Log.e('El email ya está en uso');
        onError('El email ya está en uso');
      }else {
        onError(e.toString());
      }
    } catch (e) {
      Log.e('Error al registrar el usuario: $e');
      onError("Error al registrar el usuario");
    }
  }

  // Añadir esta función en tu clase RegisterProvider
  Future<void> updateProfile({
    required String newUsername,
    required File? newImageFile,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      String email = currentUser!.email!;
      if (currentUser == null) {
        onError('No se ha iniciado sesión.');
        return;
      }

      String oldUsername = await getUsername(email);

      // Solo actualiza el nombre de usuario si es diferente al actual
      if (newUsername.toLowerCase() != oldUsername.toLowerCase()) {

        // Verificar si el nuevo nombre de usuario ya existe
        bool userExists = await checkUserExists(newUsername.toLowerCase());
        if (userExists) {
          onError('El nombre de usuario ya está en uso');
          return;
        }

        // Actualizar Firestore
        await _firestore.collection('users').doc(currentUser.uid).update({
          'username': newUsername,
          'username_lowercase': newUsername.toLowerCase(),
        });

      }

      // Si se proporciona una nueva imagen, subirla y actualizar la URL
      if (newImageFile != null) {

        // Subir nueva imagen
        String newImageUrl = await uploadImage('users/$email/profile_pic.jpg', newImageFile);
        // Actualizar URL de la imagen en Firestore
        await _firestore.collection('users').doc(currentUser.uid).update({
          'image': newImageUrl,
        });
      }

      onSuccess();
    } on FirebaseAuthException catch (e) {
      Log.e('Error al actualizar el perfil: ${e.code}');
      onError('Error al actualizar el perfil: ${e.message}');
    } catch (e) {
      Log.e('Error al actualizar el perfil: $e');
      onError('Error inesperado al actualizar el perfil.');
    }
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

  // Verificar si el usuario ya existe en la base de datos
  Future<bool> checkUserExists(String username) async {
    final QuerySnapshot result = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    Log.i('checkUserExists: ${result.docs.isNotEmpty}');
    return result.docs.isNotEmpty;
  }

  // Verificar si el email ya existe en la base de datos
  Future<bool> checkEmailExists(String email) async {
    final QuerySnapshot result = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    Log.i('checkEmailExists: ${result.docs.isNotEmpty}');
    return result.docs.isNotEmpty;
  }

  // Guardar la imagen en Firebase Storage y obtener la URL
  Future<String> uploadImage(String ref, File file) async {
    final UploadTask uploadTask = _storage.ref().child(ref).putFile(file);
    final TaskSnapshot taskSnapshot = await uploadTask;
    final String url = await taskSnapshot.ref.getDownloadURL();
    Log.i('Imagen subida correctamente en ' + url);
    return url;
  }
}