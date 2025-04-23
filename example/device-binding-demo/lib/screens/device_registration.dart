import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import 'package:e2ee_device_binding_demo_flutter/core/api_client.dart';
import 'package:e2ee_device_binding_demo_flutter/main.dart';
import 'package:e2ee_device_binding_demo_flutter/screens/passwordless_login.dart';
import 'package:e2ee_device_binding_demo_flutter/util/util.dart';

import 'package:kms_e2ee_package/api.dart';

class DeviceRegistrationScreen extends StatefulWidget {
  static String id = "register_screen";
  const DeviceRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<DeviceRegistrationScreen> createState() =>
      _DeviceRegistrationScreenState();
}

class _DeviceRegistrationScreenState extends State<DeviceRegistrationScreen> {
  final TextEditingController _controllerUsername = TextEditingController();
  final String _authenticationMessage = "Please authenticate yourself";
  final FocusNode _focusNodePassword = FocusNode();
  final ApiClient _apiClient = ApiClient();
  final Util _util = Util();
  final LocalAuthentication _localAuthentication = LocalAuthentication();

  void switchToPasswordlessLoginScreen(String message) {
    if (!context.mounted) return;
    // Notify user that session has been created
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'OK',
        onPressed: () {
          // Switch to insert otp screen
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const PasswordlessLoginScreen()));
        },
      ),
      backgroundColor: Colors.deepPurple,
    ));
  }

  void switchToLoginAccountScreen(String message) {
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
              MaterialPageRoute(builder: (context) => const LoginScreen()));
        },
      ),
      backgroundColor: Colors.redAccent[100],
    ));
  }

  Future<void> downloadWrappedClientKeyAndSetDeviceBindingFlag() async {
    // Generate key pair in TEE
    // NOTE: The default function parameters of function generateRSAKeypairInSecureStorage():
    // requireAuth is false and allowOverwrite is true
    String? clientKeyWrapper;
    try {
      clientKeyWrapper =
          await E2eeSdkPackage().generateRSAKeypairInSecureStorage();
    } on KKException catch (e) {
      print("Error: ${e.message}, error code: ${e.code}");
      rethrow;
    }

    // Get wrapped client key from server
    final responseGetWrappedClientKey =
        await _util.getWrappedClientKeyFromServer(clientKeyWrapper, true);

    // Store the wrapped client key
    try {
      // NOTE: Only applicable for Android API level >= 28, or starting from Android 9
      await E2eeSdkPackage().updateClientKeyToSecureStorage(
          responseGetWrappedClientKey!.wrappedKey,
          responseGetWrappedClientKey.kmsKeyWrapped,
          true);
      print("Importing client key for device binding success.");
    } on KKException catch (e) {
      print("Error: ${e.message}, error code: ${e.code}");
      rethrow;
    }

    // Set device binding
    try {
      await E2eeSdkPackage().setDeviceBindingInSecureStorage();
    } on KKException catch (e) {
      print("Error: ${e.message}, error code: ${e.code}");
      rethrow;
    }
  }

  Future<void> processRegistration(String e2eeSessionId) async { // Generate key pair and CSR
    // CertificateInformation: CN (Common Name), C (Country), L (Location), ST (State), O (Organization), OU (Organizational Unit)
    final DistinguishedName distinguishedName = DistinguishedName(
        "www.example.com",
        "ID",
        "Jakarta",
        "South Jakarta",
        "Company A",
        "Core Banking");

    // 1. Call API generate key pair in secure storage and return CSR
    String? applicationCsr;
    try {
      applicationCsr = await E2eeSdkPackage()
          .generateDeviceIdKeypairInSecureStorage(distinguishedName);
    } on KKException catch (e) {
      print("Error: ${e.message}, error code: ${e.code}");
      rethrow;
    }

    print(applicationCsr);
    /////////////////////////////////////////////////////////////////

    // Send request to app server to sign the CSR
    Map<String, dynamic> certificateRequestData = {
      "csr": applicationCsr,
      "e2eeSessionId": e2eeSessionId
    };

    dynamic certificateSigningResponse =
        await _apiClient.certificateSigning(certificateRequestData);
    if (certificateSigningResponse['message'] !=
        "Certificate generated successfully!") {
      final String errorMessage = certificateSigningResponse['message'];
      getAlert("Alert: $errorMessage");
    } else {
      // Verify certificate signature. If valid, store the certificate
      final String mobileCertificate =
          certificateSigningResponse['certificate'];

      final String pinnedCertificatePem = await DefaultAssetBundle.of(context)
          .loadString("assets/app_server_cert.pem");

      try {
        if ((await E2eeSdkPackage()
                .verifyCertificateSignature(mobileCertificate)) &&
            (await E2eeSdkPackage()
                .verifyCertificateSignature(pinnedCertificatePem))) {
          // Store device certificate if verified
          final File file = await _util.writeDataToFile(mobileCertificate);

          // Send response to backend that certificate has been verified successfully
          Map<String, dynamic> verificationInfo = {
            "message": "Certificate has been verified successfuly!",
            "name": _controllerUsername.text,
            "e2eeSessionId": e2eeSessionId
          };

          dynamic successResponse = await _apiClient
              .sendCertificateVerificationResult(verificationInfo);
          if (successResponse['message'] !=
              "Device public key has been stored successfully!") {
            final String errorMessage = successResponse['message'];
            getAlert("Alert: $errorMessage");
          }

          // Download wrapped client key and set device binding flag
          await downloadWrappedClientKeyAndSetDeviceBindingFlag(); // For data protection use case only

          // Switch to device activation screen
          switchToPasswordlessLoginScreen(
              "Notification: Device activated successfully. Please authenticate to complete the registration process!");
        } else {
          getAlert("Alert: Invalid certificate!");
          // Send response to backend that certificate has been verified successfully
          Map<String, dynamic> verificationInfo = {
            "message": "Certificate verification failed!",
            "name": _controllerUsername.text,
            "e2eeSessionId": e2eeSessionId
          };

          dynamic failedResponse = await _apiClient
              .sendCertificateVerificationResult(verificationInfo);
          if (failedResponse['message'] !=
              "Storing device public key has been failed!") {
            final String errorMessage = failedResponse['message'];
            getAlert("Alert: $errorMessage");
          }
        }
      } on KKException catch (e) {
        print("Error: ${e.message}, error code: ${e.code}");
        rethrow;
      }
      //////////////////////////////////////////////////////////////////
    }
  }

  Future<void> registerDevice() async { // Device registration E2EE scenario
    // Do pre-authentication
    dynamic response = await _apiClient.preAuthentication();

    // Authenticate user
    final bool canAuthenticateWithBiometrics =
        await _localAuthentication.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics ||
        await _localAuthentication.isDeviceSupported();

    // The following authentication prompt is only for Android sample.
    // Meanwhile, the iOS authentication prompt has been covered by the SDK itself.
    // NOTE: iOS based SDK authentication does not work in simulator.
    // You need to test iOS use case in actual device.
    if (canAuthenticate && Platform.isAndroid) {
      try {
        final bool didAuthenticate = await _localAuthentication.authenticate(
            localizedReason: _authenticationMessage,
            options: const AuthenticationOptions(stickyAuth: true));
        if (didAuthenticate) {
          await processRegistration(response['e2eeSessionId']);
        }
      } on PlatformException catch (e) {
        getAlert('Error - ${e.message}');
      }
    } else if (Platform.isIOS) {
      try {
        await processRegistration(response['e2eeSessionId']);
      } on PlatformException catch (e) {
        getAlert('Error - ${e.message}');
      }
    }
  }

  @override
  Widget build(BuildContext context) { // UI for device registration with digital certificate 
    return Scaffold(
      backgroundColor: Colors.deepPurple[100],
      body: Form(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              const SizedBox(height: 120),
              Center(
                child: Text("Register",
                    style: Theme.of(context).textTheme.headlineLarge),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text("Register your device",
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(height: 5),

              // Username
              const SizedBox(height: 60),
              TextFormField(
                controller: _controllerUsername,
                keyboardType: TextInputType.name,
                decoration: InputDecoration(
                  labelText: "Username",
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onEditingComplete: () => _focusNodePassword.requestFocus(),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter username.";
                  }
                  return null;
                },
              ),

              // Button
              const SizedBox(height: 50),
              Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      minimumSize: const Size.fromHeight(45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () async {
                      await registerDevice(); // Function to proceed device registration
                    },
                    child: const Text(
                      "Register",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already register the device?"),
                      TextButton(
                        onPressed: () {
                          switchToLoginAccountScreen("Switch to login screen");
                        },
                        child: const Text("Cancel",
                            style: TextStyle(color: Colors.deepPurple)),
                      )
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
