import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GifMakerScreen extends StatelessWidget {
  const GifMakerScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GIF Maker')),
      body: const Center(child: Text('GIF Maker Screen')),
    );
  }
}