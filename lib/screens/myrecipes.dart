import 'package:alioli/second_screens/drafts_sceen.dart';
import 'package:alioli/second_screens/second_screens.dart';
import 'package:alioli/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:alioli/components/components.dart';
import 'package:alioli/models/recipe.dart';

class MyRecipesScreen extends StatefulWidget {
  const MyRecipesScreen({Key? key}) : super(key: key);

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  int numDrafts = LocalStorage().getDraftRecipes().length;
  List<Recipe> publishedRecipes = LocalStorage().getPublishedRecipes(); // Lista de recetas publicadas
  int numPublishedRecipes = LocalStorage().getPublishedRecipes().length;

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
          height: appHeight*0.09 < 150 ? appHeight*0.09 : 150,
          width: appWidth*0.70 < 300 ? appWidth*0.70 : 300,
          style: Button3dStyle(
              topColor: MediaQuery.of(context).platformBrightness==Brightness.light ? AppTheme.grey1 : AppTheme.black1,
              backColor: MediaQuery.of(context).platformBrightness==Brightness.light ? AppTheme.grey2 : AppTheme.black2,
              borderRadius: BorderRadius.all(Radius.circular(10))
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
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
            Navigator.push(context, MaterialPageRoute(builder: (context) => pantalla)).then((value) {
              setState(() {
                numDrafts = LocalStorage().getDraftRecipes().length;
              });
            });
          },
        ),
      );
    }

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              SizedBox(height: 16.0,),
              Text(
                'Mis recetas',
                style: TextStyle(
                    fontSize: 30
                ),
              ),
              Divider( thickness: 1.0),
            ],
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              numPublishedRecipes > 0
                  ?
                    Expanded(
                      child: ListView.builder(
                        itemCount: publishedRecipes.length,
                        itemBuilder: (context, index) {
                          return Column(
                            children: [
                              RecipeCard(recipe: publishedRecipes[index], mode: 0, offline_mode: true,),
                              SizedBox(height: 20.0,),
                            ],
                          );
                        },
                      ),
                    )
                  :
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 20.0,),
                    placeholderIconText(
                        context,
                        'assets/recipebook.svg',
                        'No has publicado ninguna receta',
                        'Pulsa el botón + para crear una nueva receta.',
                        0.8
                    ),
                  ],
                ),
              ),
              //
              Divider( thickness: 1.0),
              SizedBox(height: 15.0,),
              if( numDrafts > 0 )
                buttonMenu(Icons.folder_off_rounded, 'Lista de borradores ($numDrafts)', DraftsScreen()),
              buttonMenu(Icons.add, 'Crear una nueva receta', UploadScreen()),
              SizedBox(height: 30.0,),
            ],
          ),
        ),
      ),
    );
  }
}
