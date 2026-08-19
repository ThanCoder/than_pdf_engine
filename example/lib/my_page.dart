import 'package:flutter/material.dart';
import 'package:than_pdf_engine_example/reader/pdf_reader.dart';

class MyPage extends StatelessWidget {
  const MyPage({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PDF: ${path.split('/').last}')),
      body: PdfReader(path: path),
      // floatingActionButton: Icon(Icons.home),
    );
  }
}
