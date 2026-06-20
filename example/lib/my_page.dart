import 'package:flutter/material.dart';
import 'package:than_pdf_engine_example/reader_v4/pdf_reader.dart';

class MyPage extends StatefulWidget {
  final String path;
  const MyPage({super.key, required this.path});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("PDF Page")),
      body: PdfReader(path: widget.path),
    );
  }
}
