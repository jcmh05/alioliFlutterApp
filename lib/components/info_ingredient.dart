import 'package:alioli/components/components.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:alioli/models/models.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';


class InfoIngredient extends StatefulWidget {
  final Ingredient ingredient;
  const InfoIngredient({Key? key, required this.ingredient}) : super(key: key);

  @override
  State<InfoIngredient> createState() => _InfoIngredientState();
}

class _InfoIngredientState extends State<InfoIngredient> {
  bool _isLoading = true;
  String _name = "";
  String _brand = "";
  String _imageUrl = "";
  String _nutriscore_grade = '';
  String _kcal_100g = "";
  String _saturated_fat_100g = "";
  String _carbohydrates_100g = "";
  String _sugars_100g = "";
  String _proteins_100g = "";
  String _salt_100g = "";
  List<String> _additives = [];
  bool _isLiquid = false;
  bool _isAlcohol = false;
  bool _isEnergyDrink = false;

  Future<void> webInfo() async {
    String barcode = widget.ingredient.barcode;
    final Uri uri = Uri(
      scheme: "https",
      host: "es.openfoodfacts.org",
      path: "/producto/${barcode}",
    );

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      throw "Can not launch url";
    }
  }

  /**
   * Obtiene información de OpenFoodFact dado un barcode con un get http
   */
  Future<void> fetchProductInfo(String barcode) async {
    final response = await http.get(Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json'));

    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(response.body);
      if (decodedResponse['status'] == 1) {
        final product = decodedResponse['product'];
        var nutriments = product['nutriments'] ?? [];
        _imageUrl = product['image_url'] ?? '';

        // Buscamos en las categorías o palabras clave si se trata de un líquido
        List<String> liquidKeywords = [
          'beverages','en:beverages','drinks','en:drinks'
          'sodas','en:sodas','bebidas','es:bebidas','refrescos','es:refrescos',
          'boissons', 'fr:boissons','cocoa-and-chocolate-powders', 'en:cocoa-and-chocolate-powder',
          'polvo','es:polvo','instant-beverages','en:instant-beverages' ,'chocolate-powders' ,
          'en:chocolate-powders'
        ];
        List<String> energyDrinkKeywords = [
          'energy-drinks','en:energy-drinks','energy-drink-with-sugar','en:energy-drink-with-sugar',
          'bebidas-energeticas','en:bebidas-energeticas','es:bebidas-energeticas','redbull', 'monster'
        ];
        List<String> alcoholDrinkKeywords = [
          'ron','rum','en:rums''licor','liquor',
          'en:alcoholic-beverages','hard-liquors','en:hard-liquors',
        ];
        var categories = product['categories_tags']?.cast<String>() ?? [];
        var keywords = product['_keywords']?.join(",").toLowerCase() ?? '';
        for (var category in categories) {
          var lowercaseCategory = category.toLowerCase();
          if (liquidKeywords.any((keyword) => lowercaseCategory.contains(keyword)) ){
            _isLiquid = true;
          }
          if (energyDrinkKeywords.any((keyword) => lowercaseCategory.contains(keyword)) ){
            _isEnergyDrink = true;
          }
          if ( alcoholDrinkKeywords.any((keyword) => lowercaseCategory.contains(keyword)) ){
            _isAlcohol = true;
          }
        }
        if (!_isLiquid) {
          _isLiquid = liquidKeywords.any((keyword) => keywords.contains(keyword));
        }
        if(!_isEnergyDrink){
          _isEnergyDrink = energyDrinkKeywords.any((keyword) => keywords.contains(keyword));
        }
        if(!_isAlcohol){
          _isAlcohol = alcoholDrinkKeywords.any((keyword) => keywords.contains(keyword));
        }

        setState(() {
          _name = product['product_name'] ?? 'Nombre no disponible';
          _nutriscore_grade = product['nutriscore_grade'] ?? '';
          _brand = product['brands'] ?? 'Marca no disponible';
          _kcal_100g = nutriments['energy-kcal_100g']?.toString() ?? '-1';
          _saturated_fat_100g = nutriments['saturated-fat_100g']?.toString() ?? '-1';
          _carbohydrates_100g = nutriments['carbohydrates_100g']?.toString() ?? '-1';
          _sugars_100g = nutriments['sugars_100g']?.toString() ?? '-1';
          _proteins_100g = nutriments['proteins_100g']?.toString() ?? '-1';
          _salt_100g = nutriments['salt_100g']?.toString() ?? '-1';
          _additives = product['additives_tags']?.cast<String>() ?? [];
          _isLoading = false;

          if( _name == 'Nombre no disponible' || _name == '' || _name == ' '){
            _name = product['product_name_es'] ?? 'Nombre no disponible';
          }
        });
      } else {
        setState(() {
          _name = 'Producto no encontrado';
        });
      }
    } else {
      setState(() {
        _name = 'Error al obtener la información del producto';
      });
    }
  }

  @override
  void initState() {
    fetchProductInfo(widget.ingredient.barcode);
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    double appHeight = MediaQuery.of(context).size.height;
    double appWidth = MediaQuery.of(context).size.width;

    Widget titleDialog(){
      return Row(
        children: [
          Flexible(
            child: Text(
              widget.ingredient.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SvgPicture.asset(
            'assets/ingredients/' + widget.ingredient.icon + '.svg',
            height: appWidth * 0.08,
          ),
        ],
      );
    }

    /**
     * Construye campo para cada nutriente
     */
    Widget buildNutrientText(String label, String value, Color colorScore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(color: MediaQuery.of(context).platformBrightness==Brightness.dark ? Colors.white : Colors.black),
                children: <TextSpan>[
                  TextSpan(text: '-$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: '$value'),
                ],
              ),
            ),
            Icon(Icons.circle, color: colorScore, size: 20.0,),
          ],
        ),
      );
    }

    /**
     * Muestra todo el contenido extraido de OpenFoodFact
     */
    Widget content_info() {

      // Se asigna un color a cada nutriente en función de proporción
      List<Color> nutrientColors = [];
      nutrientColors.add(evaluateNutrient('kcal', double.parse(_kcal_100g),_isLiquid));
      nutrientColors.add(evaluateNutrient('saturated_fat', double.parse(_saturated_fat_100g),_isLiquid));
      nutrientColors.add(evaluateNutrient('carbohydrates', double.parse(_carbohydrates_100g),_isLiquid));
      nutrientColors.add(evaluateNutrient('sugars', double.parse(_sugars_100g),_isLiquid));
      nutrientColors.add(evaluateNutrient('proteins', double.parse(_proteins_100g),_isLiquid));
      nutrientColors.add(evaluateNutrient('salt', double.parse(_salt_100g),_isLiquid));
      int risk = evaluateAdditives(_additives);
      Color additiveColor = risk == 0 ? Colors.green[800]! : risk <= 2 ? Colors.green : risk <= 4 ? Colors.yellow : Colors.red;

      return Column(
        mainAxisSize: MainAxisSize.min, // Asegura que la columna se ajuste al contenido
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 15.0,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 120,
                width: appWidth / 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10), // Bordes redondeados
                  image: DecorationImage(
                    image: NetworkImage(_imageUrl), // Imagen de fondo
                    fit: BoxFit.cover, // Ajuste de la imagen para cubrir el contenedor
                  ),
                ),
              ),
              SizedBox(width: 15.0,),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold, // Nombre en negrita
                      ),
                      overflow: TextOverflow.ellipsis, // Evita que se salga de la pantalla
                      maxLines: 2, // Máximo de líneas para el nombre
                    ),
                    Text(
                      _brand, // Variable para la marca
                      style: TextStyle(
                        fontStyle: FontStyle.italic, // Marca en cursiva
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                            Icons.circle,
                            color:
                              _nutriscore_grade=='a' ? Colors.green[800]! :
                              _nutriscore_grade=='b'  ? Colors.green[400]! :
                              _nutriscore_grade=='c'  ? Colors.yellow :
                              _nutriscore_grade=='d'  ? Colors.orange :
                              _nutriscore_grade=='e'  ? Colors.red : Colors.grey
                        ),
                        SizedBox(width: 4),
                        Text(
                            _nutriscore_grade=='a' ? 'Excelente' :
                            _nutriscore_grade=='b'  ? 'Bueno' :
                            _nutriscore_grade=='c'  ? 'Medio' :
                            _nutriscore_grade=='d'  ? 'Malo' :
                            _nutriscore_grade=='e'  ? 'Muy malo' : 'N/E'
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.0,),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(_isLiquid ? 'Por 100ml:' : 'Por 100g:',style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
          buildNutrientText('Calorías', _kcal_100g != '-1' ? _kcal_100g + 'kcal' : '?',nutrientColors[0]),
          buildNutrientText('Grasas Saturadas', _saturated_fat_100g != '-1' ? _saturated_fat_100g + 'g' : '?',nutrientColors[1]),
          buildNutrientText('Carbohidratos', _carbohydrates_100g != '-1' ? _carbohydrates_100g + 'g' : '?',nutrientColors[2]),
          buildNutrientText('Azúcar', _sugars_100g != '-1' ? _sugars_100g + 'g' : '?',nutrientColors[3]),
          buildNutrientText('Proteínas', _proteins_100g != '-1' ? _proteins_100g + 'g' : '?',nutrientColors[4]),
          buildNutrientText('Sal', _salt_100g != '-1' ? _salt_100g + 'g' : '?',nutrientColors[5]),
          _additives.isEmpty
            ? buildNutrientText('Aditivos', ' Sin información', Colors.grey)
            : buildNutrientText('Aditivos', evaluateAdditivesRiskNum(_additives).toString() + ' de riesgo', additiveColor),
          if(_isEnergyDrink)
            Text('\nSe aconseja un consumo moderado de bebidas energéticas',style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
          if(_isAlcohol)
            Text('\nSe recomienda precaución y moderación al consumir bebidas alcohólicas',style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
        ],
      );
    }


    Widget loadIndicator(){
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            width: appWidth/2,
            child: LoadingIndicator(
                indicatorType: Indicator.ballClipRotateMultiple,
                colors: MediaQuery.of(context).platformBrightness==Brightness.dark ? const [Colors.white] : const [Colors.black],
            ),
          ),
        ],
      );
    }

    return AlertDialog(
      title: titleDialog(),
      content: SingleChildScrollView(
        child: Wrap(
          children: [
            widget.ingredient.barcode=='0'
              ? Text('\n\nPara poder mostrar información del producto es necesario añadir un código de barras\n', textAlign: TextAlign.center,)
              : _isLoading
                ? loadIndicator()
                : content_info()
          ],
        ),
      ),
      actions: <Widget>[
        if(widget.ingredient.barcode!='0')
          TextButton(
            child: Text('Más Información'),
            onPressed: () {
              webInfo();
            },
          ),
        TextButton(
          child: Text('Cerrar'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );

  }

  /**
   * Asigna un color para cada nutriente que se le pase. Tendrá en cunenta si el
   * alimento es un líquido o no para determinar si un valor es elevado
   */
  Color evaluateNutrient(String nutrient, double value, bool liquid) {
    if(value<0)
      return Colors.grey;
    switch (nutrient) {
      case 'kcal':
        if ( liquid ){
          if (value <= 1) {
            return Colors.green[800]!; // Perfecto
          } else if (value <= 14) {
            return Colors.green[400]!; // Bueno
          } else if (value <= 35) {
            return Colors.orange; // Algo alto
          } else {
            return Colors.red; // Muy alto
          }
        }else{
          if (value <= 160) {
            return Colors.green[800]!; // Perfecto
          } else if (value <= 360) {
            return Colors.green[400]!; // Bueno
          } else if (value <= 560) {
            return Colors.orange; // Algo alto
          } else {
            return Colors.red; // Muy alto
          }
        }
      case 'saturated_fat':
        if( liquid ){
          if (value <= 1) {
            return Colors.green[800]!; // Perfecto
          } else if (value <= 3) {
            return Colors.green[400]!; // Bueno
          } else if (value <= 6) {
            return Colors.orange; // Moderado
          } else {
            return Colors.red; // Muy malo
          }
        }else{
          if (value <= 2) {
            return Colors.green[800]!; // Perfecto
          } else if (value <= 4) {
            return Colors.green[400]!; // Bueno
          } else if (value <= 7) {
            return Colors.orange; // Moderado
          } else {
            return Colors.red; // Muy malo
          }
        }
      case 'carbohydrates':
        if (value <= 40) {
          return Colors.green[400]!; // Bueno
        } else if (value <= 60) {
          return Colors.orange; // Moderado
        } else {
          return Colors.red; // Alto
        }
      case 'sugars':
        if( liquid ){
          if (value < 1.5) {
            return Colors.green[800]!; // Perfecto
          } else if (value <= 3) {
            return Colors.green; // Bueno
          } else if (value <= 7) {
            return Colors.orange; // Moderado
          } else {
            return Colors.red; // Alto
          }
        }else{
          if (value < 9) {
            return Colors.green[800]!; // Perfecto
          } else if (value <= 18) {
            return Colors.green[400]!; // Bueno
          } else if (value <= 31) {
            return Colors.orange; // Moderado
          } else {
            return Colors.red; // Alto
          }
        }
      case 'proteins':
        if (value >= 8) {
          return Colors.green[800]!; // Perfecto
        } else {
          return Colors.green[400]!; // Bueno
        }
      case 'salt':
        if( liquid ){
          if (value <= 0.23) {
            return Colors.green[800]!; // Perfecto
          } else if (value <= 0.7) {
            return Colors.green[400]!; // Bueno
          } else if (value <= 1.4) {
            return Colors.orange; // Moderado
          } else {
            return Colors.red; // Muy alto
          }
        }else{
          if (value <= 0.46) {
            return Colors.green[800]!; // Perfecto
          } else if (value <= 0.92) {
            return Colors.green[400]!; // Bueno
          } else if (value <= 1.62) {
            return Colors.orange; // Moderado
          } else {
            return Colors.red; // Muy alto
          }
        }
      default:
        return Colors.grey; // Nutriente no reconocido
    }
  }

  /**
   * Evalua la lista de aditivos para devolver un color como puntuación
   */
  int evaluateAdditives(List<String> additives) {
    if( additives.isEmpty)
      return 0;

    // Aditivos y su correspondiente "peso" de riesgo.
    Map<String, int> riskWeight = risk();

    // Calcula el puntaje total basado en los aditivos presentes y sus pesos.
    int riskScore = additives.fold(0, (total, current) {
      return total + (riskWeight[current.toLowerCase()] ?? 0);
    });

    return riskScore;
  }

  /**
   * Devuelve el nº de aditivos de riesgo
   */
  int evaluateAdditivesRiskNum(List<String> additives) {
    // Aditivos y su correspondiente "peso" de riesgo.
    Map<String, int> riskWeight = risk();

    int num = 0;

    for( var additive in additives){
      if ( riskWeight.containsKey(additive) ){
        if(riskWeight[additive]! >= 1){
          num++;
        }
      }
    }

    return num;
  }

  /**
   * Devuelve una lista con los principales aditivos utilizados y una puntuación
   * asociada a su riesgo
   */
  Map<String, int> risk() {
    return {
      'en:e100': 0, // Curcumina
      'en:e101': 0, //
      'en:e101a': 0, //
      'en:e101i': 0, //
      'en:e120': 3, // Cochinilla
      'en:e1400': 0, // Almidón Oxidado
      'en:e1404': 0, // Almidón Acetilado
      'en:e150a': 0, // Caramelo de color normal
      'en:e150c': 5, // Caramelo amónico
      'en:e150d': 5, // Caramelo Amónico de Sulfito
      'en:e160a': 0, // Carotenos
      'en:e160b': 2, // Annatto
      'en:e160c': 0, // Extracto de Pimentón
      'en:e170': 2, // Carbonatos Cálcicos
      'en:e200': 3, // Ácido Sórbico
      'en:e202': 3, //
      'en:e210': 4, // Ácido Benzoico
      'en:e221': 3, // Sulfito de Sodio
      'en:e250': 5, // Nitrito de Sodio
      'en:e270': 0, // Ácido Láctico
      'en:e281': 2, // Propiano de Sodio
      'en:e282': 2, // Propionato de Calcio
      'en:e296': 0, //
      'en:e300': 0, //
      'en:e301': 0, // Ascorbato de Sodio
      'en:e304': 0, //
      'en:e304i': 0, // Palpitato Ascorbilo
      'en:e306': 0, // Extractos naturales
      'en:e322': 0, // Lecitinas
      'en:e322i': 0,
      'en:e330': 0, // Ácido Cítrico
      'en:e331': 0, // Citratos Sódicos
      'en:e338': 5, // Ácido Fosfórico
      'en:e339': 5, // Fosfatos Sódicos
      'en:e339ii': 5, // Fosfato Disódico
      'en:e375': 0, // Nicotinato de Riboflavina
      'en:e385': 3, // EDTA de Disodio y Calcio
      'en:e407': 3, // Carragenina
      'en:e410': 0, // Goma Garrofín
      'en:e412': 0, // Goma Guar
      'en:e415': 0, //
      'en:e422': 2, // Glicerol
      'en:e440': 0, //
      'en:e450': 5, // Agente de textura
      'en:e451': 5, //
      'en:e451i': 5, // Tri-fosfatos
      'en:e452': 5, // Polifósfatos
      'en:e452i': 5, //Polisfosfato Sódico
      'en:e460': 2, // Celulosa microcristalina
      'en:e466': 3, // Carboximetilcelulosa
      'en:e471': 3, // Mono y Diglicéridos de Ácidos Grasos
      'en:e472e': 3, //
      'en:e481': 3, // Lactilatos Sódicos
      'en:e492': 5, // Trietearato de Sorbitano
      'en:e500': 0, //
      'en:e500ii': 0, // Bicarbonato de sodio
      'en:e501': 0, // Carbonatos Potásicos
      'en:503': 0, // Carbonatos amónicos
      'en:e503': 0, // Carbonatos Potósicos
      'en:e504i': 0, //
      'en:e524': 2, // Hidróxido de Sodio
      'en:e621': 5, // Glutamato Monosódico
      'en:e635': 2, //
      'en:e650': 0, // Acetato de Zinc
      'en:e948': 0, // Oxígeno
      'en:e950': 5, // Acesulfamo k
      'en:e952': 3, // Ácido Ciclámico
      'en:e954': 5, // Sacarina
      'en:e955': 5, // Sucralosa
      'en:e1404': 0, // Dextrina
      'en:e1404': 0,
    };
  }

}