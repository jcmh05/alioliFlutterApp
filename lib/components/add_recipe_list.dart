import 'package:alioli/components/components.dart';
import 'package:alioli/models/models.dart';
import 'package:alioli/services/local_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddRecipeListDialog extends StatefulWidget {
  @override
  _AddRecipeListDialogState createState() => _AddRecipeListDialogState();
}

class _AddRecipeListDialogState extends State<AddRecipeListDialog> {
  final Log = logger(AddRecipeListDialog);

  final TextEditingController _listNameController = TextEditingController();
  String _selectedIcon = 'null';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Crear lista de recetas',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Nombre',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            TextField(
              controller: _listNameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            SizedBox(height: 20.0),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Icono',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 10.0),
            // Ajustamos el GridView para que sea deslizable y se ajuste a su contenido
            Container(
              height: 170,
              child: GridView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.vertical,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                ),
                itemCount: AppTheme.listIconsList.keys.length,
                itemBuilder: (context, index) {
                  String key = AppTheme.listIconsList.keys.elementAt(index);
                  return IconButton(
                    icon: Icon(
                      AppTheme.listIconsList[key],
                      color: _selectedIcon == key ? AppTheme.pantry : null,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedIcon = key;
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        if ( !_isLoading )
          TextButton(
            child: Text('Cancelar'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        if ( !_isLoading )
          TextButton(
            child: Text('Guardar'),
            onPressed: () async {
              if ( _selectedIcon.contains('null') ) {
                mostrarMensaje("Selecciona un icono");
                return;
              }

              setState(() {
                _isLoading = true;
              });

              // Crear una nueva lista de recetas
              RecipeList newList = RecipeList(
                idList: _listNameController.text,
                name: _listNameController.text,
                emailUser: LocalStorage().getEmail(),
                descripcion: '',
                likes: [],
                iconId: _selectedIcon,
                recipes: [],
                visible: false,
              );

              // Guardar la lista de recetas en Firestore
              try {

                DocumentReference docRef = _firestore.collection('recipe_list').doc();
                await docRef.set({
                  'idList': docRef.id,
                  'name': newList.name,
                  'emailUser': newList.emailUser,
                  'descripcion': newList.descripcion,
                  'likes': newList.likes,
                  'iconId': newList.iconId,
                  'recipes': newList.recipes,
                  'visible': newList.visible,
                });
                Log.i('RecipeList guardada en Firestore con id: ${docRef.id}');

                // Actualizar el documento del usuario para agregar el ID de la lista de recetas a recipeList
                String uid = FirebaseAuth.instance.currentUser!.uid;
                await _firestore.collection('users').doc(uid).update({
                  'recipeList': FieldValue.arrayUnion([docRef.id])
                });
                Log.i('ID de la lista de recetas añadido al usuario en Firestore');

                // Guardar la lista de recetas en el localStorage con el ID de Firestore
                newList = newList.copyWith(idList: docRef.id); // Asegúrate de que RecipeList tenga un método copyWith
                LocalStorage().addRecipeList(newList);
              } catch (e) {
                mostrarMensaje("Error, inténtalo de nuevo más tarde");
                Log.e('Error al guardar RecipeList en Firestore: $e');
              }

              setState(() {
                _isLoading = false;
              });
              Navigator.pop(context);
            },
          ),
      ],
    );
  }
}
