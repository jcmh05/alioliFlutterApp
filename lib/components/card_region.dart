import 'package:flutter/material.dart';

class CustomSquare extends StatelessWidget {
  final String image;
  final String text;

  CustomSquare({required this.image, required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Color(0xFF494949)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // IMAGEN
          AspectRatio(
            aspectRatio: 1.9,
            child: Image.asset(
              image,
              fit: BoxFit.cover,
            ),
          ),

          Spacer(),

          // TEXTO DE ABAJO
          Container(
            width: double.infinity,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                double fontSize = constraints.maxWidth * 0.1; //Porcentaje del ancho al que se ajusta el texto
                return Center(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: fontSize
                    ),
                  ),
                );
              },
            ),
          ),

          Spacer(),
        ],
      ),
    );
  }

}