import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:window_size/window_size.dart';
import 'package:kms_e2ee_package/api.dart';

import 'package:e2ee_device_binding_demo_flutter/util/util.dart';
import 'package:e2ee_device_binding_demo_flutter/screens/mobile_scanner_login.dart';

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
  void switchToMobileScannerLoginScreen(String message, String username) {
    if (!context.mounted) return;
    // Notify user that session has been created
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'OK',
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      MobileScannerLoginScreen(username: username)));
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
  Widget build(BuildContext context) {
    // UI for Login/Main screen
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
                      // Get username from secure storage
                      final String? username = await E2eeSdkPackage()
                          .getSecretFromSecureStorage("username");
                      print("Stored username: ${username!}");
                      switchToMobileScannerLoginScreen(
                          "Notification: Device based signature login.",
                          username!);
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
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
        // NOTE: Unregister device to support testing only.
        // Don't use it during production unless if it's necessary.
        // await E2eeSdkPackage().unregisterDeviceFromSecureStorage();

        final deviceBindingLabel =
            await E2eeSdkPackage().isDeviceBindingInSecureStorage();
        if (!deviceBindingLabel) {
          await E2eeSdkPackage().unregisterDeviceFromSecureStorage();
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
