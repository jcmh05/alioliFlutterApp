import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:alioli/second_screens/second_screens.dart';
import 'package:alioli/services/local_storage.dart';
import 'package:alioli/components/components.dart';
import 'package:alioli/provider/provider.dart';
import 'package:alioli/models/models.dart';


class UploadScreen extends StatefulWidget {
  final Recipe? recipe;

  const UploadScreen({Key? key, this.recipe}) : super(key: key);

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _formKey = GlobalKey<FormState>();

  // Diseño
  double space1 = 10.0;
  double space2 = 40.0;
  bool _viewList = false;
  bool _isLoading = false;

  // Lista de unidades
  List<String> units = [
    "und", "gr", "kg", "lt", "ml", "cucharada","cucharadas", "diente","dientes",
    "pizca","pizcas", "al gusto","rebanada","rebanadas","paquete","paquetes", "copa","copas",
    "rodaja","rodajas","trozo","trozos","tira","tiras","filete","filetes","racimo","racimos",
    "puñado","puñados","porción","porciones","paquete","paquetes","bolsa","bolsas", "cabeza",
    "cabezas","hoja","hojas","unidad","unidades","vaso","vasos", "libra", "libras", "onza", "onzas",
    "taza","tazas", "cuarto", "cuartos", "medio", "medios", "tercio", "tercios", "octavo", "octavos",
    "cuña", "cuñas",'loncha','lonchas','tallo','tallos',"cdta", "cda", "puño","gota", "gotas"
  ];

  // Id de receta y texto
  String _idRecipe = const Uuid().v1();
  String _emailUser = LocalStorage().getEmail();

  // Controladores de los campos de texto
  final _controllerName = TextEditingController();
  final _controllerDescription = TextEditingController();
  List<TextEditingController> _instructionControllers = [];

  // Controlador para el campo de búsqueda de ingredientes
  final _ingredientSearchController = TextEditingController();

  // Listas para almacenar los ingredientes seleccionados, sus cantidades y unidades
  List<String> _selectedIngredientIds = [];
  List<double> _selectedQuantities = [];
  List<String> _selectedUnits = [];
  int _numOfPeople = 1;

  // Región, ocasión y etiquetas
  String selectedRegion = "";
  List<String> selectedOccasions = [];
  List<String> selectedTags = [];

  int timeInMinutes = 15;
  final _controllerYoutubeUrl = TextEditingController();
  final _controllerTiktokUrl = TextEditingController();
  final _controllerInstagramUrl = TextEditingController();
  Uint8List? image;

  /**
   * Campo de introducción de texto
   */
  Widget title(String title, bool optional) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if(optional)
          Text(
            ' (opcional)',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15.0,
            ),
          ),
      ],
    );
  }

  /**
   * Input para seleccionar la foto
   */
  Widget photoOption() {
    return InkWell(
      onTap: () {
        selectedImage();
      },
      child: image == null
          ? Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          Icons.camera_alt_outlined,
          color: Colors.white,
          size: 30,
        ),
      )
          : Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          image: DecorationImage(
            image: MemoryImage(image!),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  /**
   * Seleccionar imagen
   */
  void selectedImage() async {
    File? compressedImageFile = await pickImageCompress(20);
    if (compressedImageFile != null) {
      image = await compressedImageFile.readAsBytes();
    }
    setState(() {});
  }

  /**
   * Añadir campo de instrucciones
   */
  void addInstructionField() {
    setState(() {
      _instructionControllers.add(TextEditingController());
    });
  }

  /**
   * Input de instrucciones
   */
  Widget instructionsInput(){
    return Column(
      children: [
        for(int i = 0; i < _instructionControllers.length; i++)
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.max,
                children: [
                  CircleAvatar(
                    radius: 15.0,
                    backgroundColor: AppTheme.pantry,
                    child: Text(
                      '${i+1}',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: (){
                      setState(() {
                        _instructionControllers.removeAt(i);
                      });
                    },
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: TextField(
                    controller: _instructionControllers[i],
                    minLines: 2, // New code
                    maxLines: null, // New code
                    decoration: InputDecoration(
                      hintText: 'Introduce la instrucción',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15.0)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        SizedBox(height: space1,),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () {
                addInstructionField();
              },
              child: Row(
                children: [
                  Icon(
                    Icons.add,
                    color: AppTheme.pantry,
                  ),  // Icono de +
                  Text(' Añadir paso', style: TextStyle(color: Theme.of(context).dividerColor)),
                ],
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey, width: 1),
                backgroundColor: Colors.transparent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /**
   * Input para la región
   */
  Widget regionInput() {
    List<String> regions = [
      'american', 'chinese', 'spanish', 'french', 'indian', 'italian',
      'japanese', 'mexican', 'thai', 'turkish', 'argentine', 'greek'
    ];

    return DropdownButton<String>(
      value: selectedRegion.isNotEmpty ? selectedRegion : null,
      hint: Text('Selecciona una región'),
      items: List<DropdownMenuItem<String>>.generate(regions.length, (int index) {
        return DropdownMenuItem<String>(
          value: regions[index],
          child: Text(AppTheme.categoryNames[regions[index]]!),
        );
      }),
      onChanged: (String? newValue) {
        setState(() {
          if (newValue == 'Ninguna') {
            selectedRegion = '';
          } else {
            selectedRegion = newValue!;
          }
        });
      },
    );
  }

  /**
   * Input para el tiempo
   */
  Widget timeInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        OutlinedButton(
          onPressed: () {
            setState(() {
              if (timeInMinutes > 5) { // Ensure time doesn't go below 5 minutes
                timeInMinutes -= 5;
              }
            });
          },
          onLongPress: () {
            setState(() {
              timeInMinutes -= 60;
              if (timeInMinutes < 5) timeInMinutes = 5;
            });
          },
          child: Icon(Icons.remove, color: AppTheme.pantry),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            side: BorderSide(color: Colors.grey),
          ),
        ),
        SizedBox(width: 10.0),
        if ( timeInMinutes < 60 )
          Container(
            child: Center(
              child: Text(
                '$timeInMinutes minutos',
                style: TextStyle(fontSize: 16),
              ),
            ),
          )
        else
          Container(
            child: Center(
              child: Column(
                children: [
                  Text(
                    // Hora si es una 1 hora u horas si es más de 1 hora
                    '${timeInMinutes ~/ 60} hora${timeInMinutes ~/ 60 == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    '${timeInMinutes % 60} minutos',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        SizedBox(width: 10.0),
        OutlinedButton(
          onPressed: () {
            setState(() {
              timeInMinutes += 5;
            });
          },
          onLongPress: () {
            setState(() {
              timeInMinutes += 60;
            });
          },
          child: Icon(Icons.add, color: AppTheme.pantry),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            side: BorderSide(color: Colors.grey),
          ),
        ),
      ],
    );
  }


  /**
   * Métodos para el input de ingredientes
   */
  // Widget de entrada de la unidad con sugerencias
  Widget unitInput(TextEditingController unitController) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<String>.empty();
        }
        return units.where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        unitController.text = selection;
      },
      fieldViewBuilder: (
          BuildContext context,
          TextEditingController fieldTextEditingController,
          FocusNode fieldFocusNode,
          VoidCallback onFieldSubmitted,
          ) {
        return TextField(
          controller: fieldTextEditingController,  // This controller is managed by Autocomplete
          focusNode: fieldFocusNode,
          decoration: InputDecoration(
            hintText: 'und, kg, etc',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          onChanged: (String value) {
            // Update the main controller whenever the text changes.
            unitController.text = value;
          },
        );
      },
    );
  }



  // Método para mostrar el diálogo de selección de cantidad y unidad
  Future<void> showQuantityUnitDialog(Ingredient ingredient, {int? editIndex, bool isEditing = false}) async {
    double quantity = 0.0;
    String unit = 'und';
    TextEditingController quantityController = TextEditingController();
    TextEditingController unitController = TextEditingController();

    // Si estamos editando, establecemos los valores iniciales de los controladores
    if (isEditing && editIndex != null) {
      quantityController.text = _selectedQuantities[editIndex].toString();
      unitController.text = _selectedUnits[editIndex];
    }

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${ingredient.name}',
                  style: TextStyle(fontSize: 20.0),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SvgPicture.asset(
                'assets/ingredients/${ingredient.icon}.svg',
                height: 30.0,
              ),
            ],
          ),
          content: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cantidad'),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')) // Permite números decimales
                      ],
                      decoration: InputDecoration(
                        hintText: '0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(width: 10.0), // Add some space between the inputs
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Unidad'),
                    unitInput(unitController),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Guardar'),
              onPressed: () {
                setState(() {
                  quantity = quantityController.text.isEmpty ? 0.0 : double.parse(quantityController.text);
                  unit = unitController.text.isEmpty ? 'und' : unitController.text;
                  if (isEditing && editIndex != null) {
                    // Actualizamos el ingrediente existente
                    _selectedIngredientIds[editIndex] = ingredient.id;
                    _selectedQuantities[editIndex] = quantity;
                    _selectedUnits[editIndex] = unit;
                  } else {
                    // Añadimos un nuevo ingrediente
                    _selectedIngredientIds.add(ingredient.id);
                    _selectedQuantities.add(quantity);
                    _selectedUnits.add(unit);
                  }
                  Navigator.of(context).pop();
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildIngredientSuggestions() {
    var fuse = Fuzzy(globalIngredients.map((ingredient) => ingredient.name).toList(), options: FuzzyOptions(isCaseSensitive: false, shouldSort: true));
    var results = fuse.search(_ingredientSearchController.text);
    var filteredIngredients = results.map((result) => globalIngredients.firstWhere((ingredient) => ingredient.name == result.item)).toList();
    return Container(
      height: 150.0,
      child: ListView(
        children: filteredIngredients.map((ingredient) {
          return ListTile(
            leading: SvgPicture.asset(
              'assets/ingredients/${ingredient.icon}.svg',
              height: 30.0,
            ),
            title: Text(
              ingredient.head ? ingredient.name + ' (Cualquiera)' : ingredient.name,
            ),
            onTap: () {
              setState(() {
                _viewList = false;
                _ingredientSearchController.clear();
                showQuantityUnitDialog(ingredient);
              });
            },
          );
        }).toList(),
      ),
    );
  }

  // Método para construir el campo de entrada de ingredientes
  Widget buildIngredientInput() {
    return Column(
      children: [
        TextField(
          controller: _ingredientSearchController,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search, color: AppTheme.pantry),
            hintText: 'Buscar ingredientes',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(15.0)),
            ),
          ),

          onTapOutside: (event) {
            _viewList = false;
          },
          onEditingComplete: () {
            _viewList = false;
          },
          onSubmitted: (value) {
            _viewList = false;
            Ingredient ingredientDefault = new Ingredient(id: _ingredientSearchController.text, idIngredient: '0', name: _ingredientSearchController.text, icon: 'ingredient', amount: 0, unit: 'und', date: DateTime(3000, 1, 1), barcode: '0');
            _ingredientSearchController.clear();
            showQuantityUnitDialog(ingredientDefault);
          },
          onChanged: (value) {
            if (value == ''){
              _viewList=false;
            }else{
              _viewList = true;
            }
            setState(() {

            });
          },
        ),
        if (_viewList)
          buildIngredientSuggestions(),
      ],
    );
  }

  // Método para construir la vista de los distintos ingredientes seleccionados
  Widget buildSelectedIngredients() {
    List<Widget> chips = [];

    for (int i = 0; i < _selectedIngredientIds.length; i++) {
      Ingredient ingredient = globalIngredients.firstWhere(
            (ingredient) => ingredient.id == _selectedIngredientIds[i],
        orElse: () => Ingredient(
          id: '0',
          idIngredient: '0',
          name: _selectedIngredientIds[i],
          icon: 'ingredient',
          amount: 0,
          unit: 'und',
          date: DateTime(3000, 1, 1),
          barcode: '0',
        ),
      );

      String quantityString = _selectedQuantities[i] == 0.0
          ? "Al gusto"
          : (_selectedQuantities[i] % 1 == 0
          ? _selectedQuantities[i].toInt().toString()
          : (4 * _selectedQuantities[i]).round() / 4.0).toString() + " " + _selectedUnits[i];


      chips.add(
        Chip(
          avatar: SvgPicture.asset(
            'assets/ingredients/${ingredient.icon}.svg',
            height: 30.0,
          ),
          label: GestureDetector(
            onTap: () {
              showQuantityUnitDialog(ingredient, editIndex: i, isEditing: true);
            },
            child: Text(
              '${ingredient.name}: $quantityString',
            ),
          ),
          onDeleted: () {
            setState(() {
              _selectedIngredientIds.removeAt(i);
              _selectedQuantities.removeAt(i);
              _selectedUnits.removeAt(i);
            });
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
      );
    }

    return Column(
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.start,
          alignment: WrapAlignment.start,
          runAlignment: WrapAlignment.start,
          spacing: 8.0, // espacio entre chips
          runSpacing: 4.0, // espacio entre filas
          children: chips,
        ),
        SizedBox(height: space1),
        if (_selectedIngredientIds.isNotEmpty)
          Column(
            children: [
              SizedBox(height: space1),
              Text('¿Para cuántas personas son los ingredientes?'),
              Container(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () {
                        setState(() {
                          if(_numOfPeople > 1) _numOfPeople--;
                        });
                      },
                    ),
                    Text('Raciones: $_numOfPeople'),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          _numOfPeople++;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Recipe buildRecipe(){
    return Recipe(
      id: _idRecipe,
      emailUser: _emailUser,
      name: _controllerName.text,
      description: _controllerDescription.text,
      createdAt: DateTime.now().toString(),
      instructions: _instructionControllers.map((controller) => controller.text).toList(),
      quantities: _selectedQuantities.map((quantity) => quantity ).toList(),
      ingredients: _selectedIngredientIds,
      units: _selectedUnits,
      numPersons: _numOfPeople,
      image: image ?? Uint8List.fromList(base64Decode('iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAAEnQAABJ0Ad5mH3gAAAASdEVYdFNvZnR3YXJlAEdyZWVuc2hvdF5VCAUAAACGSURBVGhD3cixDQAhEMAwbv+heQpKD0A+kpus0/4JziLOIs4iziLOIs4iziLOIs4iziLOIs4iziLOIs4iziLOIs4iziLOIs4iziLOIs4izifNDP/FWcRZxFnEWcRZxFnEWcRZxFnEWcRZxFnEWcRZxFnEWcRZxFnEWcRZxFnEWcRZxFnEWcRZxBmz9geMYLrHnAj+ZQAAAABJRU5ErkJggg==')),
      likes: List.empty(),
      minutes: timeInMinutes,
      mealtime: selectedOccasions,
      tags: selectedTags,
      visible: false,
      region: selectedRegion,
      youtubeUrl: _controllerYoutubeUrl.text,
      tiktokUrl: _controllerTiktokUrl.text,
      instagramUrl: _controllerInstagramUrl.text,
      otherUrl: null,
    );
  }

  @override
  void initState() {
    super.initState();

    if (widget.recipe != null) {
      setState(() {
        Recipe recipe = widget.recipe!;
        _controllerName.text = recipe.name;
        _idRecipe = recipe.id;
        _emailUser = recipe.emailUser;
        _controllerDescription.text = recipe.description;
        _instructionControllers = recipe.instructions.map((instruction) => TextEditingController(text: instruction)).toList();
        _selectedIngredientIds = List.from(recipe.ingredients);
        _selectedQuantities = List.from(recipe.quantities);
        _selectedUnits = List.from(recipe.units);
        _numOfPeople = recipe.numPersons;
        image = recipe.image;
        selectedRegion = recipe.region ?? '';
        selectedOccasions = List.from(recipe.mealtime);
        selectedTags = List.from(recipe.tags);
        timeInMinutes = recipe.minutes;
        _controllerYoutubeUrl.text = recipe.youtubeUrl ?? '';
        _controllerTiktokUrl.text = recipe.tiktokUrl ?? '';
        _controllerInstagramUrl.text = recipe.instagramUrl ?? '';

      });
    }
  }

  // Método uploadRecipe
  void uploadRecipe() async {
    setState(() {
      _isLoading = true;
    });

    Recipe recipe = buildRecipe();

    // En el método donde se sube la receta a Firebase
    try {
      // Obtener la instancia del provider
      UploadRecipesService uploadRecipeProvider = new UploadRecipesService();

      // Subir la receta a Firebase y obtener su nuevo id
      String newRecipeId = await uploadRecipeProvider.uploadRecipe(recipe);

      if ( newRecipeId != ''){
        // Si la receta se sube correctamente, mostrar un mensaje y volver a la pantalla anterior
        setState(() {
          _isLoading = false;
        });

        // Si la receta se sube correctamente
        mostrarMensaje("Receta subida correctamente");

        // En caso de existir la receta en borradores la borramos de ahí
        Recipe? existingRecipe = LocalStorage().getDraftRecipe(recipe.id);
        if (existingRecipe != null) {
          await LocalStorage().deleteDraftRecipe(recipe.id);
        }

        _idRecipe = newRecipeId;

        LocalStorage().addPublishedRecipe(buildRecipe());

        Navigator.pop(context);
      }else{
        setState(() {
          _isLoading = false;
        });
        mostrarMensaje("Error al intentar subir la receta");
      }

    } catch (e) {

      print("Error al subir la receta: $e");
      setState(() {
        _isLoading = false;
      });
      mostrarMensaje("Error al subir la receta: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double appWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('Subir receta'),
        backgroundColor: Colors.transparent,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.remove_red_eye),
            onPressed: () {
              Recipe recipe = buildRecipe();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipeScreen(recipe: recipe,offline_mode: true,),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
                children: [
                  title('Título',false),
                  SizedBox(height: space1,),
                  TextFormField(
                    controller: _controllerName,
                    maxLength: 50,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Introduce el título de la receta',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15.0)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor introduce un título';
                      } else if (value.length <= 3) {
                        return 'El título debe tener más de 2 caracteres';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: space2/2,),
                  title('Foto',false),
                  SizedBox(height: space1,),
                  photoOption(),
                  SizedBox(height: space2/2,),
                  title('Ingredientes',false),
                  SizedBox(height: space1,),
                  buildIngredientInput(),
                  SizedBox(height: space2/2,),
                  buildSelectedIngredients(),
                  SizedBox(height: space2,),
                  title('Descripción',true),
                  SizedBox(height: space1,),
                  TextField(
                    controller: _controllerDescription,
                    maxLines: 3,
                    maxLength: 280,
                    decoration: InputDecoration(
                      hintText: 'Introduce la descripción de la receta',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15.0)),
                      ),
                    ),
                  ),
                  SizedBox(height: space2,),
                  title('Instrucciones',false),
                  SizedBox(height: space1,),
                  instructionsInput(),
                  SizedBox(height: space2,),
                  title('Región',true),
                  SizedBox(height: space1,),
                  regionInput(),
                  SizedBox(height: space2,),
                  title('Ocasión',false),
                  SizedBox(height: space1,),
                  ChoiceChipWidget(
                    reportList: ['breakfast', 'lunch', 'dinner', 'snack', 'appetizer', 'dessert'],
                    onSelectionChanged: (selected, isSelected) => setState(() {
                      isSelected ? selectedOccasions.add(selected) : selectedOccasions.remove(selected);
                    }),
                    selectedChoices: selectedOccasions,
                  ),
                  SizedBox(height: space2,),
                  title('Tiempo',false),
                  SizedBox(height: space1,),
                  timeInput(),
                  SizedBox(height: space2,),
                  title('Etiquetas',true),
                  SizedBox(height: space1,),
                  ChoiceChipWidget(
                    reportList: ['vegan', 'vegetarian', 'halal', 'healthy', 'high-protein', 'low-fat', 'low-carb', 'low-calories', 'high-fiber'],
                    onSelectionChanged: (selected, isSelected) => setState(() {
                      isSelected ? selectedTags.add(selected) : selectedTags.remove(selected);
                    }),
                    selectedChoices: selectedTags,
                  ),
                  SizedBox(height: space2,),
                  title('Enlaces a vídeos',true),
                  SizedBox(height: space1,),
                  TextField(
                    controller: _controllerYoutubeUrl,
                    decoration: InputDecoration(
                      labelText: "Youtube",
                      hintText: "https://www.youtube.com/watch...",
                      prefixIcon: Icon(Icons.link, color: AppTheme.pantry),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15.0)),
                      ),
                    ),
                  ),
                  SizedBox(height: space1,),
                  TextField(
                    controller: _controllerTiktokUrl,
                    decoration: InputDecoration(
                      labelText: "Tiktok",
                      hintText: "https://www.tiktok.com/@user/video/...",
                      prefixIcon: Icon(Icons.link, color: AppTheme.pantry),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15.0)),
                      ),
                    ),
                  ),
                  SizedBox(height: space1,),
                  TextField(
                    controller: _controllerInstagramUrl,
                    decoration: InputDecoration(
                      labelText: "Instagram",
                      hintText: "https://www.instagram.com/p/...",
                      prefixIcon: Icon(Icons.link, color: AppTheme.pantry),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15.0)),
                      ),
                    ),
                  ),
                  SizedBox(height: space2,),
                  if ( _isLoading )
                    Container(
                      width: (appWidth)/4,
                      child: LoadingIndicator(
                        indicatorType: Indicator.ballClipRotateMultiple,
                        colors: MediaQuery.of(context).platformBrightness==Brightness.dark ? const [Colors.white] : const [Colors.black],
                      ),
                    )
                  else
                    Column(
                      children: [
                        Rounded3dButton(
                          'Publicar receta',
                          AppTheme.pantry,
                          AppTheme.pantry_second,
                          (){
                            if( !_formKey.currentState!.validate() ) {
                              mostrarMensaje("Introduce un título válido");
                            } else if ( _selectedIngredientIds.length < 1 ){
                              mostrarMensaje("Introduce al menos un ingrediente");
                            } else if ( image == null ){
                              mostrarMensaje("Introduce una imagen");
                            } else if ( _instructionControllers.isEmpty ){
                              mostrarMensaje("Introduce al menos un paso en instrucciones");
                            } else {

                              // Comprobar que ninguna de las instrucciones esté en blanco
                              for (TextEditingController controller in _instructionControllers) {
                                if (controller.text.trim() == '') {
                                  mostrarMensaje('El paso nº ${_instructionControllers.indexOf(controller) + 1} está en blanco');
                                  return;
                                }
                              }

                              // Subir receta a Firebase
                              uploadRecipe();

                            }

                          },
                          icon: Icons.upload,
                        ),
                        SizedBox(height: space1*2,),
                        Rounded3dButton(
                          // Comprueba si existe la receta en borradores y la edita, o la añade si no existe
                          'Guardar en borradores',
                          Color(0xFF858585),
                          Color(0xFF686869),
                              () async {
                                Recipe recipe = buildRecipe();
                                Recipe? existingRecipe = LocalStorage().getDraftRecipe(recipe.id);
                                if (existingRecipe != null) {
                                  await LocalStorage().editDraftRecipe(recipe);
                                } else {
                                  await LocalStorage().addDraftRecipe(recipe);
                                }
                                Navigator.pop(context);
                          },
                          icon: Icons.save,
                        ),
                      ],
                    ),
                  SizedBox(height: space2,),
                ]
            ),
          ),
        ),
      ),
    );
  }
}

class ChoiceChipWidget extends StatefulWidget {
  final List<String> reportList;
  final Function(String, bool) onSelectionChanged;
  final List<String> selectedChoices;

  ChoiceChipWidget({required this.reportList, required this.onSelectionChanged, required this.selectedChoices});

  @override
  _ChoiceChipWidgetState createState() => _ChoiceChipWidgetState();
}

class _ChoiceChipWidgetState extends State<ChoiceChipWidget> {
  List<String> selectedChoices = [];

  @override
  void initState() {
    super.initState();
    selectedChoices = widget.selectedChoices;
  }

  _buildChoiceList() {
    List<Widget> choices = [];
    widget.reportList.forEach((item) {
      choices.add(Container(
        padding: const EdgeInsets.all(2.0),
        child: ChoiceChip(
          label: Text(
            AppTheme.categoryNames[item]!,
            style: TextStyle(
              color: selectedChoices.contains(item) ? Colors.black : Theme.of(context).dividerColor,
            ),
          ),
          avatar: Icon(
            selectedChoices.contains(item) ? null :
            AppTheme.categoryIcons.containsKey(item)  ? AppTheme.categoryIcons[item] : Icons.category,
            color: selectedChoices.contains(item) ? Colors.black : Theme.of(context).dividerColor,
          ),
          selected: selectedChoices.contains(item),
          selectedColor: AppTheme.categoryColors[item],
          backgroundColor: Colors.transparent,
          onSelected: (selected) {
            setState(() {
              widget.onSelectionChanged(item, selected);
              if (selected && !selectedChoices.contains(item)) {
                selectedChoices.add(item);
              } else if (!selected && selectedChoices.contains(item)) {
                selectedChoices.remove(item);
              }
            });
          },
        ),
      ));
    });
    return choices;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: _buildChoiceList(),
    );
  }
}