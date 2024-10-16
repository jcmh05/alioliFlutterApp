import 'package:alioli/second_screens/search_result.dart';
import 'package:flutter/material.dart';
import 'package:alioli/components/components.dart';
import 'package:alioli/components/theme.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> meatId = [
      '49', '132', '133', '134', '143', '144', '145', '203', '251', '252', '341',
      '342', '414', '415', '416', '417', '422', '494', '594', '595', '596',
      '628', '781', '782', '783', '787', '788', '789', '790'
    ];
    final List<String> fishsId = [
      '1', '58', '74', '75', '83', '84', '85', '86', '100', '103', '107', '111',
      '119', '190', '261', '262', '280', '371', '372', '448', '450', '453',
      '604', '633', '707', '708', '744', '751', '784', '829'
    ];
    final List<String> riceId = [
      '61', '62', '63', '64', '65', '66', '67', '68', '69', '70', '71'
    ];
    final List<String> legumesId = [
      '52', '53', '54', '55', '264', '265', '278', '279', '281', '401', '402', '403'
    ];
    final List<String> pastasId = [
      '238', '239', '257', '420', '571', '685', '696', '786', '807', '808', '893', '930'
    ];

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              SizedBox(height: 16.0),
              Text(
                'Categorías',
                style: TextStyle(fontSize: 30),
              ),
              Divider(thickness: 1.0),
            ],
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 10.0),
              categoryCards(
                [
                  {
                    'image': 'assets/img/carnes.jpg',
                    'text': 'Carnes',
                    'onTap': () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SearchResults(
                            title: "Recetas con carne",
                            ingredientsId: meatId,
                          ),
                        ),
                      );
                    },
                  },
                  {
                    'image': 'assets/img/pescados.jpg',
                    'text': 'Pescados y mariscos',
                    'onTap': () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SearchResults(
                            title: "Recetas con pescado",
                            ingredientsId: fishsId,
                          ),
                        ),
                      );
                    },
                  },
                  {
                    'image': 'assets/img/arroces.jpg',
                    'text': 'Arroces',
                    'onTap': () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SearchResults(
                            title: "Arroces",
                            ingredientsId: riceId,
                          ),
                        ),
                      );
                    },
                  },
                  {
                    'image': 'assets/img/legumbres.jpg',
                    'text': 'Legumbres',
                    'onTap': () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SearchResults(
                            title: "Legumbres",
                            ingredientsId: legumesId,
                          ),
                        ),
                      );
                    },
                  },
                  {
                    'image': 'assets/img/pastas.jpg',
                    'text': 'Pasta',
                    'onTap': () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SearchResults(
                            title: "Pastas",
                            ingredientsId: pastasId,
                          ),
                        ),
                      );
                    },
                  },
                  {
                    'image': 'assets/img/postres.jpg',
                    'text': 'Postres',
                    'onTap': () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SearchResults(
                            title: 'Postres',
                            mealtime: 'dessert',
                          ),
                        ),
                      );
                    },
                  },
                ],
                context,
              ),
              SizedBox(height: 20.0),

              AdBanner(
                borderRadius: BorderRadius.circular(15.0),
                margin: EdgeInsets.symmetric(vertical: 20.0),
              ),


              proporcionalText('Regiones'),
              SizedBox(height: 10.0),
              gridRegions(
                [
                  {
                    'image': 'assets/img/americana.png',
                    'text': AppTheme.categoryNames['american']!,
                    'regionInEnglish': 'american'
                  },
                  {
                    'image': 'assets/img/mexicana.png',
                    'text': AppTheme.categoryNames['mexican']!,
                    'regionInEnglish': 'mexican'
                  },
                  {
                    'image': 'assets/img/china.png',
                    'text': AppTheme.categoryNames['chinese']!,
                    'regionInEnglish': 'chinese'
                  },
                  {
                    'image': 'assets/img/espanola.png',
                    'text': AppTheme.categoryNames['spanish']!,
                    'regionInEnglish': 'spanish'
                  },
                  {
                    'image': 'assets/img/tailandesa.png',
                    'text': AppTheme.categoryNames['thai']!,
                    'regionInEnglish': 'thai'
                  },
                  {
                    'image': 'assets/img/india.png',
                    'text': AppTheme.categoryNames['indian']!,
                    'regionInEnglish': 'indian'
                  },
                  {
                    'image': 'assets/img/japon.png',
                    'text': AppTheme.categoryNames['japanese']!,
                    'regionInEnglish': 'japanese'
                  },
                  {
                    'image': 'assets/img/italiana.png',
                    'text': AppTheme.categoryNames['italian']!,
                    'regionInEnglish': 'italian'
                  },
                  {
                    'image': 'assets/img/francesa.png',
                    'text': AppTheme.categoryNames['french']!,
                    'regionInEnglish': 'french'
                  },
                  {
                    'image': 'assets/img/turca.png',
                    'text': AppTheme.categoryNames['turkish']!,
                    'regionInEnglish': 'turkish'
                  },
                  {
                    'image': 'assets/img/argentina.jpg',
                    'text': AppTheme.categoryNames['argentine']!,
                    'regionInEnglish': 'argentine'
                  },
                  {
                    'image': 'assets/img/griega.jpg',
                    'text': AppTheme.categoryNames['greek']!,
                    'regionInEnglish': 'greek'
                  },
                ],
                context,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget categoryCards(List<Map<String, dynamic>> items, BuildContext context) {
    return GridView.builder(
      itemCount: items.length,
      padding: EdgeInsets.all(5.0),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 5.0,
        crossAxisSpacing: 5.0,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (BuildContext context, int index) {
        return InkWell(
          onTap: items[index]['onTap'],
          child: CardCategory(
            image: items[index]['image'],
            text: items[index]['text'],
          ),
        );
      },
    );
  }

  // GridView que contendrá las distintas tarjetas para cada región
  Widget gridRegions(List<Map<String, String>> items, BuildContext context) {
    return GridView.builder(
      itemCount: items.length,
      padding: EdgeInsets.all(5.0), // Espacio ALREDEDOR del gridview
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(), // Se desactiva el scroll ya que el grid está dentro de un SingleChildScrollView
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Número de columnas
        mainAxisSpacing: 5.0, // Espacio vertical entre elementos
        crossAxisSpacing: 5.0, // Espacio horizontal entre elementos
        childAspectRatio: 1.3,
      ),
      itemBuilder: (BuildContext context, int index) {
        return InkWell(
          onTap: () {
            // Se navega hasta SearchResult
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SearchResults(
                  title: AppTheme.categoryNames[items[index]['regionInEnglish']]!,
                  region: items[index]['regionInEnglish'],
                ),
              ),
            );
          },
          child: CustomSquare(
            image: items[index]['image']!,
            text: items[index]['text']!,
          ),
        );
      },
    );
  }

  // Devuelve texto escalado al ancho de pantalla
  Widget proporcionalText(String text) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double fontSize = constraints.maxWidth * 0.07;
        return Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: fontSize,
          ),
        );
      },
    );
  }
}
