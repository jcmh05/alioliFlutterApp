import 'dart:typed_data';
import 'dart:ui';

import 'package:alioli/models/models.dart';
import 'package:alioli/second_screens/drafts_sceen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:alioli/components/components.dart';
import 'package:alioli/services/local_storage.dart';
import 'package:alioli/second_screens/second_screens.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class AccountScreen extends StatefulWidget {
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {


  @override
  Widget build(BuildContext context) {
    double appWidth = MediaQuery.of(context).size.width;
    double appHeight = MediaQuery.of(context).size.height;


    /**
     * Botones de opciones principales
     */
    Widget buttonMenu(IconData icon, String title, Widget pantalla){
      return Padding(
        padding: const EdgeInsets.all(4),
        child: Button3d(
          height: appHeight*0.12 < 150 ? appHeight*0.12 : 150,
          width: appWidth*0.45 < 300 ? appWidth*0.45 : 300,
          style: Button3dStyle(
              topColor: MediaQuery.of(context).platformBrightness==Brightness.light ? AppTheme.grey1 : AppTheme.black1,
              backColor: MediaQuery.of(context).platformBrightness==Brightness.light ? AppTheme.grey2 : AppTheme.black2,
              borderRadius: BorderRadius.all(Radius.circular(10))
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(icon, size: appHeight*0.045),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(title, style: TextStyle(fontSize: appHeight*0.020)),
              ),
            ],
          ),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => pantalla));
          },
        ),
      );
    }

    /**
     * Widget con el chip "Crear lista de recetas"
     */
    Widget chipButton() {
      final TextEditingController _listNameController = TextEditingController();
      String _selectedIcon = '0'; // Default icon

      return OutlinedButton(
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                color: AppTheme.pantry,
              ),
              SizedBox(width: 10.0,),
              Text('Crear lista de recetas', style: TextStyle(color: Theme.of(context).dividerColor)),
            ],
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey, width: 1),
          backgroundColor: Colors.transparent,
        ),
      );
    }

    Widget adminPanel(){
      return Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AdminScreen()));
              },
              child: Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: Colors.yellowAccent,
                  ),  // Icono de +
                  Text('Panel Administrador', style: TextStyle(color: Theme.of(context).dividerColor)),
                ],
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey, width: 1),
                backgroundColor: Colors.transparent,
              ),
            ),
          ],
        ),
      );
    }

    Widget likeList() {
      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RecipeListScreen(recipes: LocalStorage().getLikeRecipes(),title: "Me gusta",idList: "likelist",)),
          );
        },
        child: recipeListCard( 'Me gusta',LocalStorage().getLikeRecipeImage(), LocalStorage().getLikeRecipes().length, AppTheme.listIconsList['0']! ),
      );
    }

    Widget buildRecipeLists() {
      List<Widget> recipeListWidgets = [];
      if (!LocalStorage().isRecipeListEmpty()) {
        for (var recipeList in LocalStorage().getRecipeLists()) {
          recipeListWidgets.add(
            Column(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RecipeListScreen(recipes: recipeList.recipes, title: recipeList.name,idList: recipeList.idList,)),
                    );
                  },
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Eliminar lista'),
                          content: Text('¿Estás seguro de que quieres eliminar esta lista de recetas?'),
                          actions: <Widget>[
                            TextButton(
                              child: Text('Eliminar', style: TextStyle(color: Colors.red),),
                              onPressed: () async {
                                try {
                                  DocumentReference docRef = FirebaseFirestore.instance.collection('recipe_list').doc(recipeList.idList);

                                  await docRef.delete();

                                  // Actualiza el documento del usuario para eliminar el ID de la lista de recetas
                                  String uid = FirebaseAuth.instance.currentUser!.uid;
                                  await FirebaseFirestore.instance.collection('users').doc(uid).update({
                                    'recipeList': FieldValue.arrayRemove([recipeList.idList])
                                  });

                                  // Elimina la lista de recetas del LocalStorage
                                  LocalStorage().deleteRecipeList(recipeList.idList);

                                  Navigator.of(context).pop();
                                  setState(() {});
                                } catch (e) {
                                  // Muestra un mensaje de error
                                  mostrarMensaje('Error, intentelo en otro momento');
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                            TextButton(
                              child: Text('Cancelar', style: TextStyle(color: AppTheme.pantry),),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: recipeListCard(
                    recipeList.name,
                    recipeList.recipes.isNotEmpty ? recipeList.recipes.first.image : null,
                    recipeList.recipes.length,
                    AppTheme.listIconsList[recipeList.iconId]!,
                  ),
                ),
                SizedBox(height: 20.0),
              ],
            ),
          );
        }
      }
      return Column(children: recipeListWidgets);
    }

    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => ProfileScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            var begin = Offset(0.8, -0.8);
                            var end = Offset.zero;
                            var curve = Curves.fastLinearToSlowEaseIn;

                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                            var offsetAnimation = animation.drive(tween);

                            return SlideTransition(
                              position: offsetAnimation,
                              child: child,
                            );
                          },
                        ),
                      ).then((value) {
                        setState(() {});
                      });
                    },
                    child: Container( // Añadido un contenedor para limitar el ancho disponible
                      width: MediaQuery.of(context).size.width * 0.5, // Ajusta el ancho según tus necesidades
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LocalStorage().getUsername(),
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            maxLines: 2,
                            style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w500
                            ),
                          ),
                          Text(
                            LocalStorage().getEmail(),
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            maxLines: 1,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w300
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: LocalStorage().getImage() == null
                        ? Icon(Icons.account_circle_rounded)
                        : Container(
                      width: appWidth * 0.25 < 150 ? appWidth * 0.25 : 150,
                      height: appWidth * 0.25 < 150 ? appWidth * 0.25 : 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey, // Color del borde
                          width: 2.0, // Ancho del borde
                        ),
                      ),
                      child: ClipOval(
                        child: FittedBox(
                          child: LocalStorage().getImage()!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    iconSize: appWidth * 0.25 < 150 ? appWidth * 0.25 : 150,
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => ProfileScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            var begin = Offset(0.8, -0.8);
                            var end = Offset.zero;
                            var curve = Curves.fastLinearToSlowEaseIn;

                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                            var offsetAnimation = animation.drive(tween);

                            return SlideTransition(
                              position: offsetAnimation,
                              child: child,
                            );
                          },
                        ),
                      ).then((value) {
                        setState(() {});
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 30.0,),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buttonMenu(Icons.settings, 'Ajustes', SettingsScreen()),
                  buttonMenu(Icons.notifications, 'Notificaciones', NotificationsScreen()),
                ],
              ),
              if (LocalStorage().getUserRole() == 'ADMIN' || LocalStorage().getUserRole() == 'SUPERADMIN')
                adminPanel(),
              SizedBox(height: 15.0,),
              Divider(thickness: 1.0),
              Row(
                children: [
                  Text('Listas', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.start,),
                ],
              ),
              SizedBox(height: 20.0),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if ( !LocalStorage().isLikeRecipesBoxEmpty() )
                        Column(
                          children: [
                            likeList(),
                            SizedBox(height: 20.0),
                          ],
                        ),
                      buildRecipeLists(),
                      if ( LocalStorage().isLikeRecipesBoxEmpty() && LocalStorage().isRecipeListEmpty() )
                        Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: 20.0,),
                            placeholderIconText(
                                context,
                                MediaQuery.of(context).platformBrightness == Brightness.dark ? 'assets/empty_list1.svg' : 'assets/empty_list0.svg',
                                'No tienes listas de recetas',
                                'Crea una lista o dale me gusta a alguna receta para tener tu primera lista',
                                0.8
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: chipButton(),
              ),
              SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );

  }
}

