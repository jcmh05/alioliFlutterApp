import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:alioli/components/components.dart';
import 'package:alioli/models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import 'button3d.dart';

/**
 * Muestra un mensaje en un toast
 */
void mostrarMensaje(String mensaje) {
  Fluttertoast.showToast(
    msg: mensaje,
    toastLength: Toast.LENGTH_LONG,
  );
}

/**
 * Comparte un texto con otras aplicaciones
 */
void shareText( String text ) {
  Share.share(text);
}

/**
 * Función para seleccionar una imagen de la galería y comprimirla
 */
Future<File?> pickImageCompress(int quality) async {
  final picker = ImagePicker();
  // Selecciona la imagen y aplica compresión directamente con el quality proporcionado.
  final pickedFile = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: quality,
  );

  if (pickedFile != null) {
    return File(pickedFile.path);
  }
  return null;
}

/**
 * Placeholder para mostrar cuando una lista esté vacía
 */
Widget placeholderIconText(BuildContext context, String image,String text1, String text2, double scale){
  return Column(
    mainAxisSize: MainAxisSize.max,
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SvgPicture.asset(
        image,
        height: MediaQuery.of(context).size.height * 0.2 * scale,
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
            text1,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: MediaQuery.of(context).size.height * 0.03 * scale,
                fontWeight: FontWeight.bold
            )
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
            text2,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.height * 0.02 * scale,
            )
        ),
      ),
    ],
  );
}

/**
 * 3dButton genérico
 */
Widget Rounded3dButton(String text1, Color topColor, Color backColor, Function onPressed, {IconData? icon, double? height, double? width}) {
  return Button3d(
    height: height ?? 50,
    width: width ?? 300,
    style: Button3dStyle(
        topColor: topColor,
        backColor: backColor,
        borderRadius: BorderRadius.circular(50)
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) Icon(icon, color: Colors.white, size: 25),
        if (icon != null) SizedBox(width: 5), // Separación entre el icono y el texto
        Text(
          text1,
          style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold
          ),
        ),
      ],
    ),
    onPressed:() {
      onPressed();
    },
  );
}

/**
 * Dado un objeto DocumentSnapshot que corresponde a una receta, devuelve su objeto recipe
 */
Future<Recipe> convertDocToRecipe(DocumentSnapshot recipeDoc) async {
  if (recipeDoc.exists) {
    Map<String, dynamic> recipeData = recipeDoc.data() as Map<String, dynamic>;

    // Descargar la imagen y convertirla en Uint8List
    Uri imageUrl = Uri.parse(recipeData['image']);
    http.Response response = await http.get(imageUrl);
    recipeData['image'] = Uint8List.fromList(response.bodyBytes);

    return Recipe.fromMap(recipeData);
  } else {
    throw Exception('El documento no existe');
  }
}

/**
 * Dado un texto de entrada, devuelve si contiene contenido ofensivo
 */
Future<bool> containsOffensiveContent(String text) async {
  var apiKey = 'x';
  var url = Uri.parse('https://commentanalyzer.googleapis.com/v1alpha1/comments:analyze?key=$apiKey');

  var body = jsonEncode({
    "comment": { "text": text },
    "requestedAttributes": { "TOXICITY": {}, "SEVERE_TOXICITY": {} },
    "languages": ["es", "en"],
  });

  var response = await http.post(url, body: body, headers: {'Content-Type': 'application/json'});

  if (response.statusCode == 200) {
    var responseJson = json.decode(response.body);
    double toxicity = responseJson['attributeScores']['TOXICITY']['summaryScore']['value'];
    double severeToxicity = responseJson['attributeScores']['SEVERE_TOXICITY']['summaryScore']['value'];
    return toxicity > 0.1 || severeToxicity > 0.4;
  } else {
    print('API error: ${response.statusCode}');
    return false;  // Devuelve false en caso de error de la API
  }
}

List<String> extractKeywords(String input) {
  // Convertir a minúsculas
  input = input.toLowerCase();

  // Mapa de caracteres diacríticos a caracteres base
  var diacriticsMap = {
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
    'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U', 'Ü': 'U', 'Ñ': 'N'
  };

  // Eliminar tildes
  input = input.splitMapJoin(
    '',
    onNonMatch: (char) => diacriticsMap[char] ?? char,
  );

  // Eliminar emojis y signos de puntuación
  input = input.replaceAll(RegExp(r'[^\p{L}\p{N}\s]+', unicode: true), '');

  // Dividir el string en palabras
  List<String> words = input.split(' ').where((word) => word.isNotEmpty).toList();

  // Lista de palabras vacías en español
  List<String> stopwords = ['a', 'ante', 'bajo', 'cabe', 'con', 'contra', 'de', 'desde', 'en', 'entre', 'hacia', 'hasta', 'para', 'por', 'sin', 'so', 'sobre', 'tras', 'durante', 'mediante', 'y', 'al', 'la', 'el', 'del'];

  // Filtrar las palabras para excluir las palabras vacías
  words = words.where((word) => !stopwords.contains(word)).toList();

  return words;
}



Widget recipeListCard(String text,Uint8List? image, int elements, IconData icon){
  return Row(
    children: [
      Container(
        width: 150,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey, width: 1),
          image: image != null ? DecorationImage(
            image: MemoryImage(image),
            fit: BoxFit.cover,
          ) : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              if (image != null)
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                  child: Container(
                    // ...
                  ),
                ),
              Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 50,
                  shadows: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 10,
                    ),],
                ),
              ),
            ],
          ),
        ),
      ),
      SizedBox(width: 10),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            Text(
              '${elements} elementos',
              style: TextStyle(fontSize: 16), // adjust as needed
            ),
          ],
        ),
      ),
    ],
  );
}
