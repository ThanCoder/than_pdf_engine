// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:than_pdf_engine_example/my_page.dart';
import 'package:than_pkg/than_pkg.dart' show ThanPkg;

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
    return Scaffold(body: _content(), floatingActionButton: button());
  }

  FloatingActionButton button() {
    return FloatingActionButton(
      onPressed: () async {
        try {
          if (!await ThanPkg.platform.isStoragePermissionGranted()) {
            await ThanPkg.platform.requestStoragePermission();
          }
          // final g = PdfThumbnailGenerator.instance;

          // final dir = Directory('/home/thancoder/Documents/Docs');
          // final outDir = Directory('${dir.path}/thumbnails');
          // if (!outDir.existsSync()) {
          //   outDir.createSync(recursive: false);
          // }
          // for (var file in dir.listSync(followLinks: false)) {
          //   final name = file.getName();
          //   if (!name.endsWith('.pdf')) continue;
          //   print('$name: Starting...');

          //   final res = await g.generate(
          //     file.path,
          //     '${outDir.path}/$name.jpg',
          //     overrideImage: true,
          //     height: 200,
          //     width: 200,
          //   );
          //   print('$name: $res');
          // }
        } catch (e) {
          debugPrint(e.toString());
        }
      },
    );
  }

  Center _content() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            child: Text('Test'),
            onPressed: () => goPage('/home/thancoder/Documents/pdf/test.pdf'),
          ),
          TextButton(
            child: Text('Test 1'),
            onPressed: () => goPage('/home/thancoder/Documents/pdf/test1.pdf'),
          ),
          TextButton(
            child: Text('Test 2'),
            onPressed: () => goPage('/home/thancoder/Documents/pdf/test2.pdf'),
          ),
          TextButton(
            child: Text('Test 3'),
            onPressed: () => goPage('/home/thancoder/Documents/pdf/test3.pdf'),
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
    );
  }

  void goPage(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MyPage(path: path)),
    );
  }
}
