import 'package:alioli/second_screens/second_screens.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:alioli/components/components.dart';
import 'package:alioli/models/models.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:time_picker_spinner_pop_up/time_picker_spinner_pop_up.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddIngredientScreen extends StatefulWidget {
  final Function(Ingredient) crearProducto;
  final Function(Ingredient) editarProducto;
  final Ingredient? productoOriginal;
  final bool actualizando;
  final bool pantry;

  const AddIngredientScreen({
    Key? key,
    required this.pantry,
    required this.crearProducto,
    required this.editarProducto,
    this.productoOriginal,
  }) : actualizando = (productoOriginal != null), super(key: key);

  @override
  _AddIngredientScreenState createState() => _AddIngredientScreenState();
}

class _AddIngredientScreenState extends State<AddIngredientScreen> {
  // Parámetros del ingrediente
  String _idIngredient = '';
  String _id = '0';
  String _name = '';
  String _icon = 'ingredient';
  int _amount = 0;
  String _unit = 'und';
  DateTime _date = DateTime(3000, 1, 1);
  bool _dateActive = false;
  String _barcode = '0';

  // Controladores para los campos de nombre, cantidad
  final _controladorNombre = TextEditingController();
  final _controladorAmount = TextEditingController();

  // Lista de ingredientes de la base de datos
  late Future<List<Ingredient>> futureIngredients;
  bool viewList = false;


  Future<void> scanBarcode() async {
    // Navega hasta la pantalla de escaneo
    String? barcodeScanRes = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScreen(
          dynamicMode: false,
          crearProducto: (ingredient) {},
        ),
      ),
    );

    if (barcodeScanRes == null) {
      mostrarMensaje("Error al leer el código de barras");
    }else{
      fetchProductInfo(barcodeScanRes);
      setState(() {
        _barcode = barcodeScanRes;
      });
    }
  }

  Future<void> fetchProductInfo(String barcode) async {
    final response = await http.get(Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json'));

    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(response.body);
      if (decodedResponse['status'] == 1) {
        final product = decodedResponse['product'];
        setState(() {
          _barcode = barcode;
          _controladorNombre.text = product['product_name_es'] ?? 'N/E';

            if( _controladorNombre.text == 'N/E' || _controladorNombre.text == '' || _controladorNombre.text == ' '){
              _controladorNombre.text = product['product_name'] ?? 'N/E';
            }
        });
        if( _controladorNombre.text != 'N/E' ){
          // Si hemos obtenido un nombre de la api lo buscamos en nuestro Dataset
          findMostProbableIngredientId(_controladorNombre.text);
        }
      } else {
        setState(() {
          mostrarMensaje('Producto no encontrado');
        });
      }
    } else {
      setState(() {
        _controladorNombre.text = 'Error al obtener la información del producto';
      });
    }
  }

  /**
   * Devuelve el ID del producto más probable dado su nombre mediante una
   * búsqueda con Fuzzy en la base de datos local
   */
  Future<String> findMostProbableIngredientId(String name) async {
    // Accediendo directamente a futureIngredients para obtener la lista de ingredientes
    List<Ingredient> ingredients = await futureIngredients;

    // Configuramos Fuzzy con los nombres de los ingredientes
    var fuse = Fuzzy(
      ingredients.map((ingredient) => ingredient.name).toList(),
      options: FuzzyOptions(isCaseSensitive: false, shouldSort: true),
    );

    // Realizamos la búsqueda con el nombre proporcionado
    var results = fuse.search(name);

    // Si hay resultados, obtenemos el ingrediente más probable
    if (results.isNotEmpty) {
      var mostProbableIngredient = ingredients.firstWhere(
            (ingredient) => ingredient.name == results.first.item,
      );
      setState(() {
        _id = mostProbableIngredient.id;
        _unit = mostProbableIngredient.unit;
        _icon = mostProbableIngredient.icon;
      });
      return mostProbableIngredient.id; // Devolvemos el id del ingrediente más probable
    } else {
      return '0';
    }
  }

  @override
  void initState() {
    super.initState();
    futureIngredients = IngredientDao().readAll('ingredients'); // Lee todos los ingredientes de la base de datos
    final productoOriginal = widget.productoOriginal;
    if (productoOriginal != null) {
      _idIngredient = productoOriginal.idIngredient;
      _id = productoOriginal.id;
      _controladorNombre.text = productoOriginal.name;
      _amount = productoOriginal.amount;
      _name = productoOriginal.name;
      _icon = productoOriginal.icon;
      _unit = productoOriginal.unit;
      _barcode = productoOriginal.barcode;
      _date = productoOriginal.date;
      _controladorAmount.text = _amount.toString();
    }else{
      _idIngredient =  const Uuid().v1();
    }

    if( _date.year != 3000){
      _dateActive = true;
    }

    _controladorNombre.addListener(() {
      setState(() { _name = _controladorNombre.text; });
    });

    _controladorAmount.addListener(() {
      setState(() { _amount = int.parse(_controladorAmount.text); });
    });
  }

  @override
  void dispose() {
    _controladorNombre.dispose();
    super.dispose();
  }

  Widget nameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Nombre del producto',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: 10.0,),
        TextField(
          controller: _controladorNombre,
          textCapitalization: TextCapitalization.words,
          maxLength: 32,
          decoration: InputDecoration(
            hintText: 'P.e.: Pan, aceite, etc.',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 5.0),
              child: SvgPicture.asset(
                'assets/ingredients/' + _icon + '.svg',
                height: 30.0,
              ),
            ),
          ),
          // Desactivamos la lista de ingredientes cuando se deje de editar

          onTapOutside: (event) {
            viewList = false;
          },
          onEditingComplete: () {
            viewList = false;
          },
          onChanged: (value) {
            if (value == ''){
              viewList=false;
            }else{
              viewList = true;
            }
          },
        ),
      ],
    );
  }

  Widget amountDateInput() {
    int number = 0;
    bool _value = false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cantidad',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if(widget.pantry)
              Row(
                children: [
                  Text(
                    'Caducidad',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _dateActive,
                      activeColor: Colors.white,
                      activeTrackColor: Colors.green,
                      inactiveTrackColor: Colors.transparent,
                      onChanged: (value) {
                        setState(() {
                          _dateActive = value;
                          if( _dateActive == false){
                            _date = DateTime(3000, 1, 1);
                          }else{
                            _date = DateTime.now();
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
        SizedBox(height: 10.0,),
        Row(
          children: [

            // Input para cantidad
            Expanded(
              child: TextField(
                controller: _controladorAmount,
                keyboardType: TextInputType.numberWithOptions(decimal: false, signed: false),
                decoration: InputDecoration(
                  hintText: 'N/E',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.0,),

            // Selector de unidades
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: Colors.grey,
                  style: BorderStyle.solid,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _unit,
                  items: [
                    DropdownMenuItem<String>(
                      value: 'und',
                      child: Text('und'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'gr',
                      child: Text('gr'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'kg',
                      child: Text('kg'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'lt',
                      child: Text('lt'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'ml',
                      child: Text('ml'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _unit = value!;
                    });
                  },
                ),
              ),
            ),
            Spacer(),
            // Date picker
            if( widget.pantry && _dateActive)
              // Container con los bordes redondeados donde se muestra la fecha dateTime
              TextButton(
                style: TextButton.styleFrom(
                  side: BorderSide(color: Colors.grey, width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  backgroundColor: Colors.transparent,
                ),
                onPressed: () {
                  showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2200, 1, 1),
                    confirmText: 'Aceptar',
                    builder: (BuildContext context, Widget? child) {
                      return Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: AppTheme.pantry,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  ).then((date) {
                    if (date != null) {
                      setState(() {
                        _date = date;
                      });
                    }
                  });
                },
                child: Row(
                  children: <Widget>[
                    Icon(Icons.calendar_today, color: Theme.of(context).dividerColor,),
                    SizedBox(width: 8.0), // Espacio entre el icono y el texto
                    Text(
                      DateFormat('dd/MM/yyyy').format(_date), // Formatea la fecha en el formato español
                      style: TextStyle(color: Theme.of(context).dividerColor),
                    ),
                  ],
                ),
              ),
              // TimePickerSpinnerPopUp(
              //   mode: CupertinoDatePickerMode.date,
              //   initTime: _date,
              //   cancelText: 'Cancelar',
              //   timeFormat: 'dd/MM/yyyy',
              //   onChange: (dateTime) {
              //     _date = dateTime;
              //   },
              // ),

          ],
        ),
      ],
    );

  }

  Widget barcodeButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Color de fondo del contenedor
        shape: BoxShape.circle, // Hace que el contenedor sea circular.
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5), // Color de la sombra
            offset: Offset(0, 3), // La distancia horizontal y vertical de la sombra.
          ),
        ],
      ),
      child: IconButton(
        color: Colors.black,
          onPressed: () => scanBarcode(),
        icon: FaIcon(FontAwesomeIcons.barcode)
      ),
    );
  }

  Widget construyeCampoBoton(){
    return ElevatedButton(
      onPressed: () {
        final producto = Ingredient(
            id: _id,
            idIngredient: _idIngredient,
            name: _controladorNombre.text,
            icon: _icon,
            amount: _amount,
            unit: _unit,
            barcode: _barcode,
            date: _date
        );
        if (widget.actualizando) {
          widget.editarProducto(producto);
        } else {
          widget.crearProducto(producto);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Text(
          'Guardar',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }

  Widget ingredientList(){
    return FutureBuilder<List<Ingredient>>(
      future: futureIngredients,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var fuse = Fuzzy(snapshot.data!.map((ingredient) => ingredient.name).toList(), options: FuzzyOptions(isCaseSensitive: false, shouldSort: true));
          var results = fuse.search(_name);
          var filteredIngredients = results.map((result) => snapshot.data!.firstWhere((ingredient) => ingredient.name == result.item)).toList();
          return Container(
            height: 150.0, // Altura fija del cuadro invisible
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
                    _id = ingredient.id;
                    _controladorNombre.text = ingredient.name;
                    _name = ingredient.name;
                    _unit = ingredient.unit;
                    _icon = ingredient.icon;
                    viewList = false;
                  },
                );
              }).toList(),
            ),
          );
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }
        return CircularProgressIndicator();
      },
    );
  }

  /**
   * Construye un objeto ingrediente con la información actual y se lo pasa
   * a InfoIngredient para que muestre un dialog con esa información
   */
  Widget ingredientInfoButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return InfoIngredient(ingredient: Ingredient(
                      id: _id,
                      idIngredient: _idIngredient,
                      name: _controladorNombre.text,
                      icon: _icon,
                      amount: _amount,
                      unit: _unit,
                      barcode: _barcode,
                      date: _date
                  ));
                },
              );
            },
            child: Text(
              'Información sobre el producto',
              style: TextStyle(
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Selecciona fondo en función de si es despensa/cesta y modo claro/oscuro
      backgroundColor: widget.pantry ?
      (MediaQuery.of(context).platformBrightness==Brightness.dark ? AppTheme.pantry_second : AppTheme.pantry_third)
          :
      (MediaQuery.of(context).platformBrightness==Brightness.dark ? AppTheme.basket_second : AppTheme.basket_third),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Column(
              children: <Widget>[
                Text(
                  'Ingrediente',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Oxygen',
                      fontWeight: FontWeight.w800,
                      fontSize: 35
                  ),
                ),
                SizedBox(height: 50.0),
                nameInput(),
                if (viewList)
                  ingredientList(),
                if ( !viewList && _barcode!='0')
                  ingredientInfoButton(context),
                SizedBox(height: 35.0),
                amountDateInput(),
                Spacer(),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(width: 48.0,), // Tamaño equivalente al barcodeButton
                construyeCampoBoton(),
                barcodeButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}