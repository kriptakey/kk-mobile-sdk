import 'dart:typed_data';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import 'package:kms_e2ee_package/api.dart';

import 'package:e2ee_device_binding_demo_flutter/main.dart';
import 'package:e2ee_device_binding_demo_flutter/core/api_client.dart';
import 'package:e2ee_device_binding_demo_flutter/screens/account.dart';
import 'package:e2ee_device_binding_demo_flutter/core/structure.dart';

class ApprovalLogin extends StatefulWidget {
  const ApprovalLogin({
    Key? key,
    this.scannedData,
    this.username,
  }) : super(key: key);

  final String? scannedData;
  final String? username;

  @override
  State<ApprovalLogin> createState() => _ApprovalLoginState();
}

class _ApprovalLoginState extends State<ApprovalLogin> {
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  final String _authenticationMessage = "Please authenticate yourself";
  final ApiClient _apiClient = ApiClient();

  // Variable to hold the scanned data
  String? _scannedData;

  void switchToLoginScreen(String message) {
    if (!context.mounted) return;
    // Notify user that session has been created
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'OK',
        onPressed: () {
          // Switch to insert otp screen
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const LoginScreen()));
        },
      ),
      backgroundColor: Colors.deepPurple,
    ));
  }

  void getAlert(String message) {
    if (!context.mounted) return;
    // Notify user that session creation is failed
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'OK',
        onPressed: () {
          // Switch to main builder
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const ApprovalLogin()));
        },
      ),
      backgroundColor: Colors.red[400],
    ));
  }

  void switchToAccountScreen(String message) {
    if (!context.mounted) return;
    // Notify user that session has been created
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'OK',
        onPressed: () {
          // Switch to account screen
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      AccountScreen(username: widget.username!)));
        },
      ),
      backgroundColor: Colors.deepPurple,
    ));
  }

  Future<void> _authenticateDeviceAndUserToServer(
      String nonceSignature, Map<String, dynamic> preAuthenticationData) async {
    // Encrypt signature before sending to server
    Uint8List signatureUint8List =
        Uint8List.fromList(utf8.encode(nonceSignature));
    final RequestE2eeEncrypt requestE2eeEncrypt = RequestE2eeEncrypt(
        preAuthenticationData['publicKey'],
        preAuthenticationData['oaepLabel'],
        [signatureUint8List]);
    ResponseE2eeEncrypt? responseE2eeEncrypt;
    try {
      responseE2eeEncrypt =
          await E2eeSdkPackage().e2eeEncrypt(requestE2eeEncrypt);
    } on KKException catch (e) {
      print("Error: ${e.message}, error code: ${e.code}");
      rethrow;
    }

    // Send encrypted signature and metadata to app server
    final RequestEncryptedSecretObject requestSecretObject =
        RequestEncryptedSecretObject(
            preAuthenticationData['e2eeSessionId'],
            "AES",
            "HMAC-SHA512",
            responseE2eeEncrypt.encryptedDataBlockList[0],
            responseE2eeEncrypt.metadata);
    Map<String, dynamic> deviceAuthenticationData = {
      "username": widget.username!,
      "sessionMetadata": requestSecretObject
    };

    dynamic deviceActivationResponse =
        await _apiClient.processQR(deviceAuthenticationData);

    if (deviceActivationResponse['success'] == true) {
      switchToAccountScreen(
          "Notification: User and device authenticated successfully.");
    } else {
      getAlert('Alert: ${deviceActivationResponse['message']}');
    }
  }

  Future<void> _authenticateUserAndDevice(dynamic scannedData) async {
    setState(() {
      _scannedData = scannedData;
    });

    try {
      final parsedData = scannedData.isNotEmpty ? scannedData : null;
      if (parsedData != null) {
        // Deserialize scanned data to get pre-authentication data
        final response = jsonDecode(parsedData) as Map<String, dynamic>;

        // Authenticate user
        final bool canAuthenticateWithBiometrics =
            await _localAuthentication.canCheckBiometrics;
        final bool canAuthenticate = canAuthenticateWithBiometrics ||
            await _localAuthentication.isDeviceSupported();

        print("Nonce: ${response['oaepLabel']}");

        // The following authentication prompt is only for Android sample.
        // Meanwhile, the iOS authentication prompt has been covered by the SDK itself.
        // NOTE: iOS based SDK authentication does not work in simulator.
        // You need to test iOS use case in actual device.
        if (canAuthenticate && Platform.isAndroid) {
          try {
            final bool didAuthenticate =
                await _localAuthentication.authenticate(
                    localizedReason: _authenticationMessage,
                    options: const AuthenticationOptions(stickyAuth: true));
            if (didAuthenticate) {
              Uint8List? nonceSignature;
              // We assume that oaep label can be used as nonce
              try {
                nonceSignature = await E2eeSdkPackage()
                    .signByDeviceIdKeypairInSecureStorage(Uint8List.fromList(
                        utf8.encode(response['e2eeSessionId'])));
              } on KKException catch (e) {
                print("Error: ${e.message}, error code: ${e.code}");
                rethrow;
              }

              // Activate device to application server
              await _authenticateDeviceAndUserToServer(
                  base64Encode(nonceSignature), response);
            }
          } on PlatformException catch (e) {
            getAlert('Error - ${e.message}');
          }
        } else if (Platform.isIOS) {
          // Generate 10 bytes random
          Uint8List? nonceSignature;
          try {
            nonceSignature = await E2eeSdkPackage()
                .signByDeviceIdKeypairInSecureStorage(
                    Uint8List.fromList(utf8.encode(response['oaepLabel'])));
          } on KKException catch (e) {
            print("Error: ${e.message}, error code: ${e.code}");
            rethrow;
          }

          // Activate device to application server
          await _authenticateDeviceAndUserToServer(
              base64Encode(nonceSignature), response['e2eeSessionId']);
        }
      }
    } on KKException catch (e) {
      print("Error: ${e.message}, error code: ${e.code}");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[100],
      body: Form(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              const SizedBox(height: 150),
              Center(
                child: Text("Are you sure to authenticate your device?",
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center),
              ),
              const SizedBox(height: 50),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      MaterialButton(
                        onPressed: () async {
                          await _authenticateUserAndDevice(widget.scannedData!);
                        },
                        height: 45,
                        minWidth: 140,
                        color: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text("Yes",
                            style: TextStyle(color: Colors.white)),
                      ),
                      MaterialButton(
                        onPressed: () async {
                          switchToLoginScreen(
                              "Notification: Device registration has been canceled!");
                        },
                        height: 45,
                        minWidth: 140,
                        color: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text("No",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
