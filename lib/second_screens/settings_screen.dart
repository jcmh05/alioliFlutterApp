import 'package:alioli/alioli.dart';
import 'package:alioli/provider/provider.dart';
import 'package:alioli/second_screens/notifications_screen.dart';
import 'package:alioli/second_screens/profile_screen.dart';
import 'package:alioli/services/local_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypt/crypt.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:alioli/components/components.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Log = logger(SettingsScreen);

  Widget textOption(String title, String? description){
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Theme.of(context).dividerColor
            ),
          ),
          if ( description != null)
            Text(
              description,
              softWrap: true,
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

  Widget pageOption(String title, String? description){
    final _iconPages = <IconData>[
      Icons.home,
      Icons.map,
      Icons.search,
      Icons.menu_book_outlined,
      Icons.account_circle,
    ];

    int _selectedPage = LocalStorage().getInitialPage();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          textOption(title, description),
          SizedBox(width: 20.0),
          DropdownButton<int>(
            value: _selectedPage,
            icon: Icon(Icons.arrow_drop_down),
            underline: Container(
              height: 0,
            ),
            onChanged: (int? newValue) {
              setState(() {
                _selectedPage = newValue!;
                LocalStorage().setInitialPage(_selectedPage);
              });
            },
            items: List<DropdownMenuItem<int>>.generate(
              _iconPages.length,
                  (index) => DropdownMenuItem<int>(
                value: index,
                child: Icon(_iconPages[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget generalOption(String title, String? description,Function action){
    return InkWell(
      onTap: (){
        action();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            textOption(title, description),
            // Icono con una flecha
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }


  Widget optionURL(String title, String? description, String link){
    return InkWell(
      onTap: (){
        Uri url = Uri.parse(link);
        launchUrl(url);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            textOption(title, description),
            Icon(
              Icons.info_outline,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> deleteUserAccount() async {
    Log.i("Borrando cuenta de usuario...");
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final FirebaseStorage _storage = FirebaseStorage.instance;

    // Paso 1: Obtener la instancia actual del usuario
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      Log.e('No hay usuario actualmente logueado.');
      return;
    }

    // Paso 2: Acceder a la colección 'users' en Firestore y eliminar el documento asociado a la cuenta
    await _firestore.collection('users').doc(currentUser.uid).delete();

    // Paso 3: Comprobar si existe una foto de perfil asociada al usuario en Firebase Storage. Si existe, se elimina
    final String imageRef = 'users/${currentUser.email}/profile_pic.jpg';
    final Reference ref = _storage.ref(imageRef);

    try {
      await ref.getDownloadURL();
      // Si no se lanza una excepción, significa que la imagen existe. Entonces, la borramos.
      await ref.delete();
      Log.i('Imagen de perfil eliminada correctamente.');
    } catch (e) {
      // Si se lanza una excepción, significa que la imagen no existe. No hacemos nada.
      Log.i('No existe una imagen de perfil asociada a esta cuenta.');
    }

    // Paso 4: Eliminar las credenciales de autenticación de FirebaseAuth para esa cuenta
    await currentUser.delete();
    Log.i('Cuenta de usuario eliminada correctamente.');
  }

  Widget deleteButton(){
    final passwordController = TextEditingController();

    return InkWell(
      onTap: () async {
        // Crea un dialogButton para preguntar la confirmación de cerrar sesión
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Borrar cuenta'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('¿Estás seguro de que quieres borrar tu cuenta?\n\nEsta acción será irreversible\n\n', textAlign: TextAlign.center,),
                  CustomTextField(
                    controller: passwordController,
                    obscureText: true,
                    labelText: 'Contraseña',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    final LoginProvider loginProvider = LoginProvider();
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser != null && currentUser.email != null) {
                      final userData = await loginProvider.getUserData(currentUser.email!);
                      if (userData != null) {
                        String storedPasswordHash = userData['password'];
                        if (Crypt(storedPasswordHash).match(passwordController.text)) {
                          deleteUserAccount();
                          await LocalStorage().clearUserBox();
                          await LocalStorage().clearPublishedRecipesBox();
                          await LocalStorage().clearLikeRecipesBox();

                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => Alioli(isLogged: false)),
                                (Route<dynamic> route) => false,
                          );
                        } else {
                          mostrarMensaje("Contraseña incorrecta");
                          Navigator.pop(context);
                        }
                      }
                    } else {
                      // handle the case when there is no current user or the user has no email
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No hay usuario actualmente logueado.')),
                      );
                    }
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
              'Borrar cuenta',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajustes'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(15.0),
        child: Column(
          children: [
            pageOption('Pantalla inicial', 'Pantalla que se mostrará al abrir la aplicación'),
            Divider(thickness: 1.0),
            generalOption('Ajustes de Notificaciones', null, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsScreen()));
            }),
            generalOption('Ajustes de Usuario', null, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
            }),
            Divider(thickness: 1.0),
            optionURL('Política de privacidad', null, 'https://alioliapp.github.io/home/privacy'),
            optionURL('Términos y condiciones', null, 'https://alioliapp.github.io/home/terms'),
            Divider(thickness: 1.0),
            deleteButton(),
          ],
        ),
      ),
    );
  }
}
