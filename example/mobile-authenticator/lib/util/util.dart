import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

import 'package:e2ee_device_binding_demo_flutter/main.dart';
import 'package:e2ee_device_binding_demo_flutter/screens/device_registration.dart';
import 'package:e2ee_device_binding_demo_flutter/screens/account.dart';

class Demo {
  final String name;
  final String route;
  final WidgetBuilder builder;

  const Demo({required this.name, required this.route, required this.builder});
}

final demos = [
  Demo(
    name: 'Sign Up',
    route: 'register',
    builder: (context) => const DeviceRegistrationScreen(),
  ),
  Demo(
    name: 'Password-based Login',
    route: 'password_based_login',
    builder: (context) => const AccountScreen(),
  )
];

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
      routes: [
        for (final demo in demos)
          GoRoute(
            path: demo.route,
            builder: (context, state) => demo.builder(context),
          ),
      ],
    ),
  ],
);

class Util {
  Future<String> get localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get localFile async {
    final path = await localPath;
    return File('$path/deviceCertificate.pem');
  }

  Future<File> writeDataToFile(String data) async {
    final file = await localFile;
    return file.writeAsString(data);
  }

  Future<Uint8List> readImageAsBytesFromGallery() async {
    final pickedFile = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 400, maxHeight: 400);
    Uint8List imageBytes = Uint8List.fromList([0]);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      imageBytes = await imageFile.readAsBytes();
    }
    return imageBytes;
  }
}
