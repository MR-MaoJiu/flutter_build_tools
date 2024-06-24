import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:process_run/process_run.dart';
import 'package:yaml_magic/yaml_magic.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Build Tools',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Build Tools'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _version = '1.0.0';
  int _buildNum = 10001;
  String? selectedDirectory;
  final TextEditingController _controller = TextEditingController();
  Map<String, dynamic> buildConfig = {
    "version": '1.0.0+10001',
    "channel": ["huawei", "honor", "tencent", "xiaomi", "vivo", "oppo"],
  };
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      ),
      body: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextButton(
                onPressed: () async {
                  selectedDirectory =
                      await FilePicker.platform.getDirectoryPath();

                  if (selectedDirectory != null) {
                    // 获取build.yaml 如果存在直接读取如果不存在创建新的
                    if (File('$selectedDirectory/build.yaml').existsSync()) {
                      final build =
                          YamlMagic.load('$selectedDirectory/build.yaml');
                      final pubspec =
                          YamlMagic.load('$selectedDirectory/pubspec.yaml');

                      _version = build['version'].toString().split('+')[0];
                      _buildNum =
                          int.parse(build['version'].toString().split('+')[1]) +
                              1;
                      //读取配置文件版本号+1并写入pubspec.yaml
                      pubspec['version'] = '$_version+$_buildNum';
                      pubspec.save();
                      buildConfig['version'] = '$_version+$_buildNum';
                      String buildJsonStr = json.encode(buildConfig).toString();
                      print(buildJsonStr);
                      _controller.text = buildJsonStr;
                      setState(() {});
                    } else {
                      //获取pubspec.yaml 拿到当前版本号和构建号
                      final pubspec =
                          YamlMagic.load('$selectedDirectory/pubspec.yaml');
                      print('version: ${pubspec['version']}');
                      _version = pubspec['version'].toString().split('+')[0];
                      _buildNum = int.parse(
                              pubspec['version'].toString().split('+')[1]) +
                          1;
                      pubspec['version'] = '$_version+$_buildNum';
                      pubspec.save();
                      buildConfig['version'] = '$_version+$_buildNum';
                      String buildJsonStr = json.encode(buildConfig).toString();
                      print(buildJsonStr);
                      _controller.text = buildJsonStr;
                      var file = Directory('$selectedDirectory/build.yaml');
                      await File(file.path).create();
                      final build =
                          YamlMagic.load('$selectedDirectory/build.yaml');
                      //创建build.yaml
                      build['version'] = '$_version+$_buildNum';
                      build.save();
                      setState(() {});
                    }
                  }
                },
                child: const Text('Pick your flutter project directory path ')),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                height: MediaQuery.of(context).size.height * 0.3,
                width: MediaQuery.of(context).size.width,
                child: CupertinoTextField(
                  controller: _controller,
                  maxLines: 20,
                  placeholder: 'Pick your flutter project directory path ',
                ),
              ),
            ),
          ],
        ),
      ),
      // floatingActionButton: Column(
      //   mainAxisAlignment: MainAxisAlignment.end,
      //   children: [
      //     FloatingActionButton(
      //       onPressed: () async {
      //         String? selectedDirectory =
      //             await FilePicker.platform.getDirectoryPath();
      //
      //         if (selectedDirectory == null) {
      //           // User canceled the picker
      //         }
      //       },
      //       tooltip: 'Build',
      //       child: const Icon(
      //         CupertinoIcons.play_arrow_solid,
      //         color: Colors.green,
      //       ),
      //     ),
      //     const SizedBox(height: 10),
      //     FloatingActionButton(
      //       onPressed: () {},
      //       tooltip: 'Debug',
      //       child: const Icon(
      //         CupertinoIcons.ant_circle_fill,
      //         color: Colors.red,
      //       ),
      //     ),
      //   ],
      // ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          //自动打包
          var shell = Shell();
          buildConfig['channel'].forEach((element) async {
            print('--channel--$element');
            await shell.run('''
    flutter build apk --release --dart-define=APP_CHANNEL=$element
    mv build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/$element-release.apk
''');
          });

          //TODO:自动上架到应用商店
        },
        tooltip: 'Build',
        child: const Icon(
          CupertinoIcons.play_arrow_solid,
          color: Colors.green,
        ),
      ),
    );
  }
}
