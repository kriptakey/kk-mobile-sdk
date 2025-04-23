import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

import 'package:e2ee_device_binding_demo_flutter/core/api_client.dart';
import 'package:e2ee_device_binding_demo_flutter/main.dart';
import 'package:e2ee_device_binding_demo_flutter/core/structure.dart';
import 'package:e2ee_device_binding_demo_flutter/screens/register.dart';
import 'package:e2ee_device_binding_demo_flutter/screens/account.dart';
import 'package:e2ee_device_binding_demo_flutter/screens/passwordless_login.dart';
import 'package:e2ee_device_binding_demo_flutter/core/e2ee_sdk_wrapper.dart';

import 'package:kms_e2ee_package/api.dart';

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
    builder: (context) => const RegisterScreen(),
  ),
  Demo(
    name: 'Password-based Login',
    route: 'password_based_login',
    builder: (context) => const AccountScreen(),
  ),
  Demo(
    name: 'Passwordless Login',
    route: "passwordless_login",
    builder: (context) => const PasswordlessLoginScreen(),
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
  Future<bool> authenticateBackendServer(String pinnedCertificatePem) async {
    // NOTE: the mobile app is developed with the KriptaKey certificate being pinned.
    final BackendServerAuth backendServerAuth =
        BackendServerAuth(pinnedCertificatePem);
    final String encryptedNonce = await backendServerAuth.getEncryptedNonce();

    // Start server authentication
    final ApiClient apiClient = ApiClient();
    Map<String, dynamic> serverAuthenticationData = {
      "encryptedNonce": encryptedNonce
    };

    dynamic response =
        await apiClient.startServerAuthentication(serverAuthenticationData);
    if (response['message'] != "Signature generated successfully.") {
      throw Exception(response['message']);
    }

    return backendServerAuth.verifyNonceSignature(response['nonceSignature']);
  }

  Future<ResponseGetWrappedClientKey?> getWrappedClientKeyFromServer(
      String clientKeyWrapper, bool isSecureKeyImportAvailable,
      [bool isDeviceBinding = false]) async {
    late String wrappingMethod;
    if (Platform.isAndroid) {
      if (!isDeviceBinding && isSecureKeyImportAvailable) {
        wrappingMethod = "android";
      } else if (isDeviceBinding && isSecureKeyImportAvailable) {
        wrappingMethod = "androidWithSecureKeyImport";
      } else {
        print("Enter else scenario for android.\r\n");
        wrappingMethod = "androidWithNonSecureKeyImport";
      }
    } else if (Platform.isIOS) {
      wrappingMethod = "ios";
    }

    // Request wrapped client key to server
    final ApiClient apiClient = ApiClient();
    Map<String, dynamic> payload = {
      "wrappingMethod": wrappingMethod,
      "appstoredPublicKey": clientKeyWrapper
    };

    // Register user to server
    dynamic response = await apiClient.getWrappedClientKey(payload);
    if (response['message'] != "Client key generated successfully!") {
      return null;
    }

    return ResponseGetWrappedClientKey(
        response['wrappedKey'], response['kmsKeyWrapped']);
  }

  Future<String> login(String username, String password) async {
    final ApiClient apiClient = ApiClient();
    // Request public key and oaep label from server
    dynamic response = await apiClient.preAuthentication();

    // Salt password with person id, then calculate its hash
    var saltedPassword = password + username;
    final Uint8List passwordDigest = await E2eeSdkPackage().calculateDigest(
        Uint8List.fromList(utf8.encode(saltedPassword)), "SHA-512");

    // Call API e2eeEncrypt to encrypt password entered by user
    final RequestE2eeEncrypt requestE2eeEncrypt = RequestE2eeEncrypt(
        response['publicKey'], response['oaepLabel'], [passwordDigest]);
    ResponseE2eeEncrypt? responseE2eeEncrypt;
    try {
      responseE2eeEncrypt =
          await E2eeSdkPackage().e2eeEncrypt(requestE2eeEncrypt);
    } on KKException catch (e) {
      print("Error: ${e.message}, error code: ${e.code}");
      rethrow;
    }
    ///////////////////////////////////////////////////////////

    return await authenticateUserToServer(username, responseE2eeEncrypt,
        response['publicKey'], response['e2eeSessionId']);
  }

  Future<String> authenticateUserToServer(
      String username,
      ResponseE2eeEncrypt responseE2eeEncrypt,
      String serverPublicKey,
      String e2eeSessionId) async {
    final ApiClient apiClient = ApiClient();
    // Construct Json payload
    Map<String, dynamic> userData = {
      "name": username,
      "encryptedPasswordBlock": responseE2eeEncrypt.encryptedDataBlockList[0],
      "publicKey": serverPublicKey,
      "e2eeSessionId": e2eeSessionId,
      "metaData": responseE2eeEncrypt.metadata
    };

    // Register user to server
    dynamic response = await apiClient.loginWithPassword(userData);
    return response['message'];
  }

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
