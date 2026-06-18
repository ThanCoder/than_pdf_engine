// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:than_pdf_engine_example/reader_v2.dart';
import 'package:than_pkg/than_pkg.dart';

void main() {
  runApp(MaterialApp(theme: ThemeData.dark(), home: const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              child: Text('Test'),
              onPressed: () => goPage('/home/thancoder/Documents/test.pdf'),
            ),
            TextButton(
              child: Text('Test 1'),
              onPressed: () => goPage('/home/thancoder/Documents/test1.pdf'),
            ),
            TextButton(
              child: Text('Test 2'),
              onPressed: () => goPage('/home/thancoder/Documents/test2.pdf'),
            ),
            TextButton(
              child: Text('Test 3'),
              onPressed: () => goPage('/home/thancoder/Documents/test3.pdf'),
            ),
            TextButton(
              onPressed: () => goPage('/storage/emulated/0/test.pdf'),
              child: Text('Android Small Pdf'),
            ),
            TextButton(
              onPressed: () => goPage('/storage/emulated/0/test2.pdf'),
              child: Text('Android Big Pdf'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            if (!await ThanPkg.platform.isStoragePermissionGranted()) {
              await ThanPkg.platform.requestStoragePermission();
            }
            // await TPdfCoreThumbnailer.extractImageAndSave(
            //   pageIndex: 1,
            //   '/home/thancoder/Documents/test2.pdf',
            //   savePath: 'out.png',
            //   overrideExistsImage: true,
            // );
          } catch (e) {
            debugPrint(e.toString());
          }
        },
      ),
    );
  }

  void goPage(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReaderV2(path: path)),
    );
  }
}
