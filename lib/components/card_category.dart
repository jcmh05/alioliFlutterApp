import 'package:flutter/material.dart';

class CardCategory extends StatelessWidget {
  final String image;
  final String text;

  CardCategory({required this.image, required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Color(0xFF494949)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // IMAGEN
          Image.asset(
            image,
            fit: BoxFit.cover,
          ),

          // TRANSPARENCIA NEGRA
          Container(
            color: Colors.black.withOpacity(0.2),
          ),

          // TEXTO SOBRE LA IMAGEN
          Container(
            alignment: Alignment.center,
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold, // Texto en negrita
                fontSize: 25,
                color: Colors.white,
                shadows: <Shadow>[
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 15.0,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 3, // Máximo de 3 líneas
              overflow: TextOverflow.ellipsis, // Añade puntos suspensivos si el texto excede las 3 líneas
            ),
          ),
        ],
      ),
    );
  }
}