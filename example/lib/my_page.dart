import 'package:flutter/material.dart';
import 'package:than_pdf_engine_example/src/t_pdf_reader_base.dart';

class MyPage extends StatefulWidget {
  final String path;
  const MyPage({super.key, required this.path});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final controller = TPdfController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("PDF Page")),
      body: TPdfReader(path: widget.path, controller: controller),
    );
  }
}
