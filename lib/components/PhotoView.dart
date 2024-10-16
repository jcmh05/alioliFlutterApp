import 'dart:typed_data';

import 'package:flutter/material.dart';

class PhotoViewPage extends StatelessWidget {
  final Uint8List imageUint8List;
  final String title;

  PhotoViewPage({required this.imageUint8List, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: InteractiveViewer(
          scaleEnabled: true,
          child: Image.memory(imageUint8List),
          minScale: 0.1,
          maxScale: 2.0,
        ),
      ),
    );
  }
}