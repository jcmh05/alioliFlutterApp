import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:provider/provider.dart';

import 'package:alioli/alioli.dart';
import 'package:alioli/provider/provider.dart';
import 'package:alioli/components/components.dart';
import 'package:alioli/services/local_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Log = logger(ProfileScreen);

  final TextEditingController _usernameController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  bool _errorUsername = false;
  Image? _image;
  File? _newImage;
  String? _email;
  String? _username;

  // Widget para cerrar sesión
  Widget logoutButton(){
    return InkWell(
      onTap: () async {
        // Crea un dialogButton para preguntar la confirmación de cerrar sesión
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Cerrar Sesión'),
              content: Text('¿Estás seguro de cerrar sesión?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    await LocalStorage().clearUserBox();
                    await LocalStorage().clearPublishedRecipesBox();
                    await LocalStorage().clearLikeRecipesBox();
                    await LocalStorage().clearRecipeLists();
                    LoginProvider().logout();

                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => Alioli(isLogged: false)),
                          (Route<dynamic> route) => false,
                    );
                  },
                  child: Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cerrar Sesión',
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Colors.red
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editableRow(String label, TextEditingController controller, bool isEditable) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 18,
          )
        ),
        if (isEditable)
          Flexible(
            child: IntrinsicWidth(
              child: TextField(
                controller: controller,
                textAlign: TextAlign.end,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: label,
                ),
                onChanged: (value) {
                  setState(() {
                    _errorUsername = false;
                    _isEditing = true;
                  });
                },
              ),
            ),
          )
        else
          GestureDetector(
            onTap: () => mostrarMensaje('No se puede modificar el email'),
            child: Text(
              controller.text,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }


  Future<void> _updateUserProfile() async {
    final registerProvider = Provider.of<RegisterProvider>(context, listen: false);

    if ( _usernameController.text.isEmpty ) {
      setState(() {
        _errorUsername = true;
      });
      mostrarMensaje('El nombre de usuario no puede quedar vacío');
      return null;
    }
    if(await containsOffensiveContent(_usernameController.text)){
      mostrarMensaje('El nombre de usuario contiene palabras ofensivas');
      return null;
    }
    if (_usernameController.text.contains(' ')) {
      setState(() {
        _errorUsername = true;
      });
      mostrarMensaje('El nombre de usuario no pueden contener espacios');
      return null;
    }
    if (_usernameController.text.length < 4) {
      setState(() {
        _errorUsername = true;
      });
      mostrarMensaje('El nombre de usuario debe tener al menos 4 caracteres');
      return null;
    }
    if (_usernameController.text.length > 20) {
      setState(() {
        _errorUsername = true;
      });
      mostrarMensaje('El nombre de usuario no puede tener más de 20 caracteres');
      return null;
    }
    if (!RegExp(r'^[a-zA-Z0-9_-]*$').hasMatch(_usernameController.text)) {
      setState(() {
        _errorUsername = true;
      });
     mostrarMensaje('El nombre de usuario solo puede contener letras, números, guiones bajos y guiones medios');
     return null;
    }

    setState(() {
      _isLoading = true;
    });

    // Actualizar el nombre de usuario en Firestore
    try {
      await registerProvider.updateProfile(
        newUsername: _usernameController.text,
        newImageFile: _newImage,
        onSuccess: () {
          setState(() {
            _isLoading = false;
            _isEditing = false;
            _username = _usernameController.text;
            LocalStorage().setUsername(_usernameController.text);
          });

          // Actualizar nombre y foto en LocalStorage
          LocalStorage().setUsername(_usernameController.text);
          if( _newImage != null){
            LocalStorage().saveImageFromFile(_newImage!);
          }

          Log.i('Información de usuario actualizada');
          mostrarMensaje('Cambios realizados');
          Navigator.pop(context);
        },
        onError: (String error) {
          setState(() {
            _isLoading = false;
          });
          Log.e('Error al actualizar el perfil: $error');
          mostrarMensaje(error);
        },
      );

    } on FirebaseAuthException catch (e) {
      Log.e('Error al actualizar el perfil: ${e.code}');
      mostrarMensaje(e.message!);
    } catch (e) {
      Log.e('Error al actualizar el perfil: $e');
      mostrarMensaje(e.toString()!);
    }

  }

  @override
  void initState() {
    super.initState();
    final localStorage = LocalStorage();
    _username = localStorage.getUsername();
    _usernameController.text = _username!;
    _email = localStorage.getEmail();
    _image  = localStorage.getImage();
  }


  @override
  Widget build(BuildContext context) {
    double appWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () async {
                  File? newImage = await pickImageCompress(20);
                  if (newImage != null) {
                    setState(() {
                      _newImage = newImage;
                      _image = Image.file(newImage);
                      _isEditing = true;
                    });
                  }
                },
                child: _image == null
                    ? Stack(
                        children: <Widget>[
                          Container(
                            width: appWidth*0.4 < 150 ? appWidth*0.4 : 150,
                            height: appWidth*0.4 < 150 ? appWidth*0.4 : 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey, // Color del borde
                                width: 2.0, // Ancho del borde
                              ),
                            ),
                            child: ClipOval(
                              child: FittedBox(
                                child: Icon(
                                  Icons.account_circle,
                                  color: Colors.grey,
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: appWidth*0.1 < 40 ? appWidth*0.1 : 40,
                              height: appWidth*0.1 < 40 ? appWidth*0.1 : 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      )
                    :  Stack(
                        children: <Widget>[
                          Container(
                            width: appWidth*0.4 < 150 ? appWidth*0.4 : 150,
                            height: appWidth*0.4 < 150 ? appWidth*0.4 : 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey, // Color del borde
                                width: 2.0, // Ancho del borde
                              ),
                            ),
                            child: ClipOval(
                              child: FittedBox(
                                child: _image!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: appWidth*0.1 < 40 ? appWidth*0.1 : 40,
                              height: appWidth*0.1 < 40 ? appWidth*0.1 : 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.grey
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              SizedBox(height: 20),
              _errorUsername ? _editableRow("Nombre de Usuario❌", _usernameController, true) : _editableRow("Nombre de Usuario", _usernameController, true),
              SizedBox(height: 20),
              _editableRow("Email", TextEditingController(text: _email), false),
              SizedBox(height: 30),
              _editableRow("Recetas publicadas:", TextEditingController(text: LocalStorage().getPublishedRecipes().length.toString()), false),
              SizedBox(height: 20),
              if ( _isLoading )
                Container(
                  width: appWidth/4,
                  child: LoadingIndicator(
                    indicatorType: Indicator.ballClipRotateMultiple,
                    colors: MediaQuery.of(context).platformBrightness==Brightness.dark ? const [Colors.white] : const [Colors.black],
                  ),
                )
              else
                Column(
                  children: [
                    if ( _isEditing )
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30.0),
                        child: Button3d(
                          height: 40,
                          width: 250,
                          style: Button3dStyle(
                              topColor: AppTheme.pantry,
                              backColor: AppTheme.pantry_second,
                              borderRadius: BorderRadius.circular(50)
                          ),
                          onPressed: () async {
                            await _updateUserProfile();
                          },
                          child: const Text(
                            'Guardar cambios',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      ),
                    Divider(thickness: 1.0),
                    logoutButton(),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }
}