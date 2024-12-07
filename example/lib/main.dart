import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:window_size/window_size.dart';

import 'package:e2ee_device_binding_demo_flutter/util/util.dart';
import 'package:e2ee_device_binding_demo_flutter/util/cache_parameters.dart';
import 'package:e2ee_device_binding_demo_flutter/screens/account.dart';
import 'package:e2ee_device_binding_demo_flutter/screens/passwordless_login.dart';

import 'package:kms_e2ee_package/api.dart';

void main() async {
  setupWindow();

  // NOTE: For any exception returned from platform channel will not be propagated to flutter side.
  // https://docs.flutter.dev/testing/errors
  // The exception or error will be captured in PlatformDispatcher as shown in the codes below.
  // It is up to developer to handle such error based on error code returned from the channel.
  PlatformDispatcher.instance.onError = (error, stack) {
    // Example of error handler
    var platformException = error as PlatformException;
    if (platformException.code == "4000003") {
      print("Platform not supported to generate such type of key!");
      // You can also properly handle the error by notifying user through an alert dialog.
    }
    return true;
  };

  runApp(const MaterialApp(home: FormApp()));
}

const double windowWidth = 480;
const double windowHeight = 854;

void setupWindow() {
  if (!kIsWeb && (Platform.isLinux || Platform.isMacOS)) {
    WidgetsFlutterBinding.ensureInitialized();
    setWindowTitle('E2EE Device Binding Demo');
    setWindowMinSize(const Size(windowWidth, windowHeight));
    setWindowMaxSize(const Size(windowWidth, windowHeight));
    getCurrentScreen().then((screen) {
      setWindowFrame(Rect.fromCenter(
        center: screen!.frame.center,
        width: windowWidth,
        height: windowHeight,
      ));
    });
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _controllerUsername = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  final FocusNode _focusNodePassword = FocusNode();

  bool _obscurePassword = true;
  final Util _util = Util();

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
                      AccountScreen(username: _controllerUsername.text)));
        },
      ),
      backgroundColor: Colors.deepPurple,
    ));
  }

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
      backgroundColor: Colors.red[400],
    ));
  }

  Future<void> showAlertDialog() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('AlertDialog'),
            content: const SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Your device has not yet registered.'),
                  Text('Do you want to register your device?'),
                  Text('Please authenticate your self to register the device.'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  // Switch to Login screen
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()));
                },
              ),
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  // Switch to Login screen
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()));
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) { // UI for Login/Main screen
    return Scaffold(
      backgroundColor: Colors.deepPurple[100],
      body: Form(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              const SizedBox(height: 150),
              Center(
                child: Text("Welcome back",
                    style: Theme.of(context).textTheme.headlineLarge),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text("Login to your account",
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              // Username or person id
              const SizedBox(height: 60),
              TextFormField(
                controller: _controllerUsername,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  // NOTE: User id can be NIK or username. By entering NIK,
                  // we can calculate the password hash before encrypting the password.
                  // It provides more secured password.
                  labelText: "Person Id",
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
              // Password
              const SizedBox(height: 10),
              TextFormField(
                controller: _controllerPassword,
                focusNode: _focusNodePassword,
                obscureText: _obscurePassword,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.password_outlined),
                  suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: _obscurePassword
                          ? const Icon(Icons.visibility_outlined)
                          : const Icon(Icons.visibility_off_outlined)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter password.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 50),
              Column(
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        MaterialButton(
                          onPressed: () async {
                            final String loginResponse = await _util.login(
                                _controllerUsername.text,
                                _controllerPassword.text);
                            if (loginResponse == "User authenticated!") {
                              switchToAccountScreen(loginResponse); // Password-based authentication / Login
                            } else {
                              getAlert(loginResponse);
                            }
                          },
                          height: 45,
                          minWidth: 250,
                          color: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text("Login",
                              style: TextStyle(color: Colors.white)),
                        ),
                        MaterialButton(
                            onPressed: () async {
                              if (CacheParameters().getDeviceBindingFlag()) {
                                switchToPasswordlessLoginScreen(
                                    "Notification: Device based password login.");
                              } else {
                                // Register device
                                await showAlertDialog();
                              }
                            },
                            height: 45,
                            minWidth: 40,
                            color: Colors.deepPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.fingerprint_outlined,
                              size: 25,
                            )),
                      ]),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          context.go('/${demos[0].route}');
                        },
                        child: const Text("Sign Up",
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

class FormApp extends StatefulWidget {
  const FormApp({super.key});

  @override
  State<FormApp> createState() => _FormAppState();
}

class _FormAppState extends State<FormApp> {
  void getAlertDialog(String message) {
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
      backgroundColor: Colors.red[400],
    ));
  }

  @override
  void initState() {
    super.initState();
    try {
      Future.delayed(Duration.zero, () async {
        final Util util = Util();

        // NOTE: Unregister device to support testing only.
        // Don't use it during production unless if it's necessary.
        await E2eeSdkPackage().unregisterDeviceFromSecureStorage();

        // Backend server authentication
        final String pinnedCertificatePem = await DefaultAssetBundle.of(context)
            .loadString("assets/app_server_cert.pem");
        try {
          final bool isServerAuthenticated =
              await util.authenticateBackendServer(pinnedCertificatePem);
          if (!isServerAuthenticated) {
            getAlertDialog("Server is not authenticate.");
          }
        } catch (e, s) {
          getAlertDialog(e.toString());
        }

        // Check whether the app is bound to the device or not
        // Line 371 - 426 is for Data Protection use case
        bool? isDeviceBinding;
        try {
          isDeviceBinding =
              await E2eeSdkPackage().isDeviceBindingInSecureStorage();
        } on KKException catch (e) {
          print("Error: ${e.message}, error code: ${e.code}");
          rethrow;
        }
        if (!isDeviceBinding) {
          // Generate key pair in TEE
          // NOTE: The default function parameters of function generateRSAKeypairInSecureStorage():
          // requireAuth is false and allowOverwrite is true
          String? clientKeyWrapper;
          try {
            // NOTE: Only applicable for Android API level >= 28, or starting from Android 9
            clientKeyWrapper =
                await E2eeSdkPackage().generateRSAKeypairInSecureStorage();
          } on KKException catch (e) {
            print("Error: ${e.message}, error code: ${e.code}");
            rethrow;
          }

          // Get secure key import availability information
          if (Platform.isAndroid) {
            final isSecureKeyImportAvailable = await E2eeSdkPackage()
                .isSecureKeyImportAvailableInSecureStorage();
            print("Secure key import information: $isSecureKeyImportAvailable"); // For debugging
          }

          // Get wrapped client key from server
          // NOTE: Only applicable for Android API level >= 28, or starting from Android 9
          final responseGetWrappedClientKey =
              await util.getWrappedClientKeyFromServer(clientKeyWrapper, false);

          // Store the wrapped client key
          // NOTE: Only applicable for Android API level >= 28, or starting from Android 9
          try {
            await E2eeSdkPackage().updateClientKeyToSecureStorage(
                responseGetWrappedClientKey!.wrappedKey,
                responseGetWrappedClientKey.kmsKeyWrapped);
            print("Importing client key success.");
          } on KKException catch (e) {
            print("Error: ${e.message}, error code: ${e.code}");
            rethrow;
          }
        } else {
          // Cache device binding flag for further use
          CacheParameters().setDeviceBinding(true);
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'E2EE Device Binding Demo',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
