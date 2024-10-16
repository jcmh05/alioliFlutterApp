import 'package:alioli/second_screens/second_screens.dart';
import 'package:flutter/material.dart';
import 'package:alioli/components/components.dart';
import 'package:alioli/services/local_storage.dart';
import 'package:alioli/models/recipe.dart';

class DraftsScreen extends StatefulWidget {
  const DraftsScreen({Key? key}) : super(key: key);

  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  final localStorage = LocalStorage();

  @override
  Widget build(BuildContext context) {
    List<Recipe> draftRecipes = localStorage.getDraftRecipes();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Borradores'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep),
            onPressed: () async {
              bool? shouldClear = await showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Eliminar todos los borradores'),
                    content: Text('¿Estás seguro de que quieres eliminar todos los borradores?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        child: Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        child: Text('Eliminar'),
                      ),
                    ],
                  );
                },
              );
              if (shouldClear == true) {
                await localStorage.clearRecipesDraftBox();
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (draftRecipes.isEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No tienes borradores'),
                ],
              )
            else
              ListView.separated(
                separatorBuilder: (context, index) => Divider(),
                shrinkWrap: true,
                itemCount: draftRecipes.length,
                itemBuilder: (context, index) {
                  Recipe recipe = draftRecipes[index];
                  return ListTile(
                    leading: recipe.image != null
                        ? Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        image: DecorationImage(
                          image: MemoryImage(recipe.image),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                        : null,
                    title: Text(recipe.name),
                    subtitle: Text(
                      recipe.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UploadScreen(recipe: recipe),
                        ),
                      ).then((value) {
                        setState(() {});
                      });
                    },
                    trailing: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () async {
                        // Muestra un dialog para confirmar y eliminar borrador o cancelar
                        await showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text('Eliminar ' + recipe.name),
                              content: Text('¿Estás seguro de que quieres eliminar este borrador?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, false);
                                  },
                                  child: Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    localStorage.deleteDraftRecipe(recipe.id);
                                    Navigator.pop(context, true);
                                    setState(() {});
                                  },
                                  child: Text('Eliminar'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}