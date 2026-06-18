import 'package:flutter/material.dart';
import 'package:than_pdf_engine_example/v3/t_pdf_render_v3_base.dart';

class MyPage extends StatefulWidget {
  final String path;
  const MyPage({super.key, required this.path});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final controller = TPdfControllerV3();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("PDF Page")),
      body: TPdfReaderV3(source: widget.path, controller: controller),
    );
  }
}
