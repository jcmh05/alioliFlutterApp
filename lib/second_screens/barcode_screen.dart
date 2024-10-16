import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:alioli/components/components.dart';
import 'package:alioli/models/models.dart';
import 'package:flutter/material.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class BarcodeScreen extends StatefulWidget {
  final Function(Ingredient) crearProducto;
  final bool dynamicMode;
  const BarcodeScreen({super.key, required this.dynamicMode,required this.crearProducto});

  @override
  State<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<BarcodeScreen> {
  final Log = logger(BarcodeScreen);
  String barcode = '0';
  String productName = '';
  bool isModalOpen = false;


  @override
  Widget build(BuildContext context) {


    void showModal(String value) {
      showBarModalBottomSheet(
        isDismissible: false,
        barrierColor: Colors.transparent,
        context: context,
        builder: (context) => Container(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: ProductModal(barcode: barcode, crearProducto: widget.crearProducto),
          ),
        ),
      );
    }

    return AiBarcodeScanner(
      cutOutWidth: 300,  // Ancho del recorte
      cutOutHeight: 200,
      cutOutSize: 0.0,
      bottomBarText: 'Código de Barras',
      hapticFeedback: true,
      canPop: false,
      onScan: (String value) {
        barcode = value;

        if ( !widget.dynamicMode){
          Navigator.pop(context,barcode);
          return ;
        }
        Log.i('Código leido: $value');

        if ( isModalOpen) {
          isModalOpen = false;
          Navigator.pop(context);
        }
        isModalOpen = true;
        showModal(value);

      },
      controller: MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: [BarcodeFormat.code128, BarcodeFormat.code39, BarcodeFormat.code93, BarcodeFormat.codabar, BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.itf, BarcodeFormat.upcA, BarcodeFormat.upcE],
      ),
    );
  }
}

class ProductModal extends StatefulWidget {
  final Function(Ingredient) crearProducto;
  final String barcode;

  const ProductModal({super.key, required this.barcode, required this.crearProducto});

  @override
  State<ProductModal> createState() => _ProductModalState(barcode);
}

class _ProductModalState extends State<ProductModal> {
  String _idIngredient =  const Uuid().v1();
  String _id = '0';
  String _productName = '';
  String _icon = 'ingredient';
  int _amount = 0;
  String _unit = 'und';
  DateTime _date = DateTime(3000, 1, 1);
  String _barcode = '0';
  String _imageUrl = "";
  String nutriscore_grade = '';

  _ProductModalState(this._barcode);

  /**
   * Devuelve el ID del producto más probable dado su nombre mediante una
   * búsqueda con Fuzzy en la base de datos local
   */
  Future<String> findMostProbableIngredientId(String name) async {
    // Accediendo directamente a futureIngredients para obtener la lista de ingredientes
    List<Ingredient> ingredients = globalIngredients;

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


  Future<void> fetchProductName(String barcode) async {
    final response = await http.get(Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json'));

    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(response.body);
      if (decodedResponse['status'] == 1) {
        final product = decodedResponse['product'];
        setState(() {
          _barcode = barcode;
          _productName = product['product_name_es'] ?? 'N/E';
          nutriscore_grade = product['nutriscore_grade'] ?? '';
          _imageUrl = product['image_url'] ?? '';

          if( _productName == 'N/E' || _productName == '' || _productName == ' '){
            _productName = product['product_name'] ?? 'N/E';
          }
        });
        if( _productName != 'N/E' ){
          // Si hemos obtenido un nombre de la api lo buscamos en nuestro Dataset
          findMostProbableIngredientId(_productName);
        }
      } else {
        setState(() {
          mostrarMensaje('Producto no encontrado');
        });
      }
    } else {
      setState(() {
        _productName = 'Error al escanear';
      });
    }
  }



  @override
  void initState() {
    super.initState();
    fetchProductName(_barcode);
  }

  @override
  Widget build(BuildContext context) {
    double appWidth = MediaQuery.of(context).size.width;
    Color circleColor;
    String gradeText;

    if (_productName == '') {
      // Si el nombre del producto aún no se ha cargado, muestra el indicador de carga
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: appWidth/3,
                child: LoadingIndicator(
                  indicatorType: Indicator.ballClipRotateMultiple,
                  colors: const [Colors.black],
                ),
              ),
            ],
          ),
          Text('Consultando datos del producto...', style: TextStyle(color: Colors.grey[700])),
        ],
      );
    } else {
      // Si el nombre del producto ya se ha cargado, muestra los datos del producto
      switch (nutriscore_grade) {
        case 'a':
          circleColor = Colors.green[800]!;
          gradeText = 'Excelente';
          break;
        case 'b':
          circleColor = Colors.green[400]!;
          gradeText = 'Bueno';
          break;
        case 'c':
          circleColor = Colors.yellow;
          gradeText = 'Medio';
          break;
        case 'd':
          circleColor = Colors.orange;
          gradeText = 'Malo';
          break;
        case 'e':
          circleColor = Colors.red;
          gradeText = 'Muy malo';
          break;
        default:
          circleColor = Colors.grey;
          gradeText = 'N/E';
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre producto
                  Text(
                    _productName,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Grado nutricional
                  Row(
                    children: [
                      Container(
                        width: 20.0,
                        height: 20.0,
                        decoration: BoxDecoration(
                          color: circleColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 5),
                      Text(
                        gradeText,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                height: 100,
                width: appWidth / 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10), // Bordes redondeados
                  image: DecorationImage(
                    image: NetworkImage(_imageUrl), // Imagen de fondo
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.0),
              ),
            ),
            child: const Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Guardar',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              final producto = Ingredient(
                  id: _id,
                  idIngredient: _idIngredient,
                  name: _productName,
                  icon: _icon,
                  amount: _amount,
                  unit: _unit,
                  barcode: _barcode,
                  date: _date
              );
              widget.crearProducto(producto);
            },
          ),
        ],
      );
    }
  }
}
