import 'dart:convert';
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:asn1lib/asn1lib.dart';

// import 'package:e2ee_bridge/core/crypto.dart';
// import 'package:e2ee_bridge/bridge/e2ee_bridge.dart';
// import 'package:e2ee_bridge/core/structure.dart';
// import 'package:e2ee_bridge/core/constants.dart';
import 'package:e2ee_sdk_flutter/api.dart';
import 'package:e2ee_sdk_flutter_example/core/utility.dart';
import 'package:e2ee_sdk_flutter_example/core/api_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ApiClient _apiClient = ApiClient();
  final String _username = "E2eeUser";
  final String _userPassword = "E2eeUserPassword";
  final String _authenticationMessage = "Please authenticate yourself";

  Future<void> authenticateBackendServer(String pinnedCertificatePem) async {
    // NOTE: the mobile app is developed with the KriptaKey certificate being pinned.
    final BackendServerAuth backendServerAuth =
        BackendServerAuth(pinnedCertificatePem);
    final String encryptedNonce = await backendServerAuth.getEncryptedNonce();

    // Start server authentication
    Map<String, dynamic> serverAuthenticationData = {
      "encryptedNonce": encryptedNonce
    };

    dynamic response =
        await _apiClient.startServerAuthentication(serverAuthenticationData);
    if (response['message'] != "Signature generated successfully.") {
      throw Exception(response['message']);
    }

    final bool isNonceVerified = await backendServerAuth
        .verifyNonceSignature(response['nonceSignature']);
  }

  Future<void> resetPassword(int i) async {
    dynamic preAuthenticationResponse = await _apiClient.preAuthentication();

    var username = _username + i.toString();
    var userPassword = _userPassword + i.toString();

    final RequestE2eeEncrypt requestE2eeEncrypt = RequestE2eeEncrypt(
        preAuthenticationResponse['publicKey'],
        [Uint8List.fromList(utf8.encode(userPassword))],
        preAuthenticationResponse['oaepLabel']);

    final ResponseE2eeEncrypt responseE2eeEncrypt =
        await E2eeSdk().e2eeEncrypt(requestE2eeEncrypt);

    Map<String, dynamic> userData = {
      "name": username,
      "encryptedPasswordBlock": responseE2eeEncrypt.encryptedDataBlockList[0],
      "publicKey": preAuthenticationResponse['publicKey'],
      "e2eeSessionId": preAuthenticationResponse['e2eeSessionId'],
      "metaData": responseE2eeEncrypt.metadata
    };

    dynamic registerUserWithPasswordResponse =
        await _apiClient.registerUserWithPassword(userData);
    if (registerUserWithPasswordResponse['message'] != "User registered!") {
      print(registerUserWithPasswordResponse['message']);
    }
  }

  Future<void> verifyPassword(int i) async {
    dynamic preAuthenticationResponse = await _apiClient.preAuthentication();

    var username = _username + i.toString();
    var userPassword = _userPassword + i.toString();

    final RequestE2eeEncrypt requestE2eeEncrypt = RequestE2eeEncrypt(
        preAuthenticationResponse['publicKey'],
        [Uint8List.fromList(utf8.encode(userPassword))],
        preAuthenticationResponse['oaepLabel']);

    final ResponseE2eeEncrypt responseE2eeEncrypt =
        await E2eeSdk().e2eeEncrypt(requestE2eeEncrypt);

    Map<String, dynamic> userData = {
      "name": username,
      "encryptedPasswordBlock": responseE2eeEncrypt.encryptedDataBlockList[0],
      "publicKey": preAuthenticationResponse['publicKey'],
      "e2eeSessionId": preAuthenticationResponse['e2eeSessionId'],
      "metaData": responseE2eeEncrypt.metadata
    };

    dynamic loginUserWithPasswordResponse =
        await _apiClient.loginWithPassword(userData);
    if (loginUserWithPasswordResponse['message'] != "User authenticated!") {
      print(loginUserWithPasswordResponse['message']);
    }
  }

  Future<void> updateAccount(int i) async {
    dynamic preAuthenticationResponse = await _apiClient.preAuthentication();

    var username = "E2eeUser$i";
    var firstName = "First Name $i";
    var familyName = "Family Name $i";
    var address = "Address $i";
    var dayOfBirth = "0101$i";
    var personalIdNumber = "12346789178$i";
    var phoneNumber = "081345678$i";
    var imageBytes = Uint8List.fromList(utf8.encode("Image $i"));

    final RequestE2eeEncrypt requestE2eeEncrypt = RequestE2eeEncrypt(
        preAuthenticationResponse['publicKey'],
        [
          Uint8List.fromList(utf8.encode(firstName)),
          Uint8List.fromList(utf8.encode(familyName)),
          Uint8List.fromList(utf8.encode(dayOfBirth)),
          Uint8List.fromList(utf8.encode(address)),
          Uint8List.fromList(utf8.encode(personalIdNumber)),
          Uint8List.fromList(utf8.encode(phoneNumber)),
          imageBytes
        ],
        preAuthenticationResponse['oaepLabel']);

    final ResponseE2eeEncrypt responseE2eeEncrypt =
        await E2eeSdk().e2eeEncrypt(requestE2eeEncrypt);

    Map<String, dynamic> userData = {
      "name": username,
      "encryptedFirstNameBlock": responseE2eeEncrypt.encryptedDataBlockList[0],
      "encryptedFamilyNameBlock": responseE2eeEncrypt.encryptedDataBlockList[1],
      "encryptedDayOfBirthBlock": responseE2eeEncrypt.encryptedDataBlockList[2],
      "encryptedAddressBlock": responseE2eeEncrypt.encryptedDataBlockList[3],
      "encryptedPersonalIdBlock": responseE2eeEncrypt.encryptedDataBlockList[4],
      "encryptedPhoneNumberBlock":
          responseE2eeEncrypt.encryptedDataBlockList[5],
      "encryptedImage": responseE2eeEncrypt.encryptedDataBlockList[6],
      "publicKey": preAuthenticationResponse['publicKey'],
      "e2eeSessionId": preAuthenticationResponse['e2eeSessionId'],
      "metaData": responseE2eeEncrypt.metadata
    };

    dynamic updateUserAccountResponse =
        await _apiClient.updateUserAccount(userData);
    if (updateUserAccountResponse['message'] != "User account updated.") {
      print(updateUserAccountResponse['message']);
    }
    print("Test $i");
  }

  Future<void> importWrappedClientKey(int i) async {
    final String clientKeyWrapper =
        await E2eeSdkInSecureStorage().generateRSAKeypair();

    late String wrappingMethod;
    if (Platform.isAndroid) {
      wrappingMethod = "android";
    } else if (Platform.isIOS) {
      wrappingMethod = "ios";
    }

    // Request wrapped client key to server
    Map<String, dynamic> payload = {
      "wrappingMethod": wrappingMethod,
      "externalPublicKey": clientKeyWrapper
    };

    // Register user to server
    dynamic response = await _apiClient.getWrappedClientKey(payload);
    if (response['message'] != "Client key generated successfully!") {
      print(response['message']);
    }

    final ResponseGetWrappedClientKey responseGetWrappedClientKey =
        ResponseGetWrappedClientKey(
            response['wrappedKey'], response['kmsKeyWrapped']);

    // Import wrapped client key to secure storage
    await E2eeSdkInSecureStorage().updateClientKey(
        responseGetWrappedClientKey.wrappedKey,
        responseGetWrappedClientKey.kmsKeyWrapped);

    print("Test $i");
  }

  Future<void> decryptUserData(int i) async {
    // Fetch ClientKey
    final KMSWrappedKeyMetadata kmsWrappedKeyMetadata =
        await E2eeSdkInSecureStorage().fetchWrappedClientKey();

    // Get user data from database
    Map<String, dynamic> getAccountData = {
      "name": "E2eeUser$i",
      "encryptedClientKey": kmsWrappedKeyMetadata.encodedKMSKeyWrapped,
      "encryptedClientKeyMetadata":
          kmsWrappedKeyMetadata.encodedEncryptedMetadata
    };

    dynamic getAccountResponse = await _apiClient.getUserData(getAccountData);
    List<RequestSingleE2eeDecrypt> singleEncryptedDataBlockList = [];
    for (final ciphertext in getAccountResponse['ciphertextList']) {
      final RequestSingleE2eeDecrypt singleEncryptedDataBlock =
          RequestSingleE2eeDecrypt(
              ciphertext['text'], ciphertext['mac'], ciphertext['iv']);
      singleEncryptedDataBlockList.add(singleEncryptedDataBlock);
    }

    // Decrypt client data
    final RequestE2eeDecrypt requestE2eeDecrypt = RequestE2eeDecrypt(
        singleEncryptedDataBlockList, kmsWrappedKeyMetadata.aad);
    final ResponseE2eeDecrypt responseE2eeDecrypt =
        await E2eeSdkInSecureStorage().e2eeDecrypt(requestE2eeDecrypt);

    final String firstName = utf8.decode(responseE2eeDecrypt.messages[0]);
    final String familyName = utf8.decode(responseE2eeDecrypt.messages[1]);
    final String personalIdNumber =
        utf8.decode(responseE2eeDecrypt.messages[2]);
    final String dayOfBirth = utf8.decode(responseE2eeDecrypt.messages[3]);
    final String address = utf8.decode(responseE2eeDecrypt.messages[4]);
    final String phoneNumber = utf8.decode(responseE2eeDecrypt.messages[5]);
    final Uint8List imageBytes = responseE2eeDecrypt.messages[6];

    print("First Name: $firstName");
    print("Family Name: $familyName");
    print("Personal ID number: $personalIdNumber");
    print("Day of birth: $dayOfBirth");
    print("Address: $address");
    print("Phone number: $phoneNumber");

    print("Test $i");
  }

  Future<void> generateDeviceBasedEncryptedPassword(int i) async {
    dynamic preAuthenticationResponse = await _apiClient.preAuthentication();

    final ResponseE2eeEncrypt responseE2eeEncrypt =
        await E2eeSdkInSecureStorage().generateDeviceBasedEncryptedPassword(
            preAuthenticationResponse['publicKey'],
            preAuthenticationResponse['oaepLabel']);
  }

  Future<void> getDeviceBasedEncryptedPassword(int i) async {
    dynamic preAuthenticationResponse = await _apiClient.preAuthentication();

    final ResponseE2eeEncrypt responseE2eeEncrypt =
        await E2eeSdkInSecureStorage().getDeviceBasedEncryptedPassword(
            preAuthenticationResponse['publicKey'],
            preAuthenticationResponse['oaepLabel']);
  }

  Future<void> generateDeviceIdKeyPairInSecureStorage(int i) async {
    final DistinguishedName distinguishedName = DistinguishedName(
        "www.example$i.com",
        "ID",
        "Location$i",
        "Province$i",
        "Organization$i",
        "Organization Unit$i");

    final String deviceCsr = await E2eeSdkInSecureStorage()
        .generateDeviceIdKeypair(distinguishedName);
    print("Test $i");
  }

  Future<void> registerDevice(int i, String pinnedCertificatePem) async {
    dynamic preAuthenticationResponse = await _apiClient.preAuthentication();

    // Generate CSR
    final DistinguishedName distinguishedName = DistinguishedName(
        "www.example$i.com",
        "ID",
        "Location$i",
        "Province$i",
        "Organization$i",
        "Organization Unit$i");

    final String deviceCsr = await E2eeSdkInSecureStorage()
        .generateDeviceIdKeypair(distinguishedName);

    // Send request to app server to sign the CSR
    Map<String, dynamic> certificateRequestData = {
      "csr": deviceCsr,
      "e2eeSessionId": preAuthenticationResponse['e2eeSessionId']
    };

    dynamic certificateSigningResponse =
        await _apiClient.certificateSigning(certificateRequestData);
    if (certificateSigningResponse['message'] !=
        "Certificate generated successfully!") {
      final String errorMessage = certificateSigningResponse['message'];
      throw Exception(errorMessage);
    } else {
      // Verify certificate signature. If valid, store the certificate
      final String mobileCertificate =
          certificateSigningResponse['certificate'];

      // 2. Call API verify certificate chain and return true if verified
      if ((await E2eeSdk().verifyCertificateSignature(mobileCertificate)) &&
          (await E2eeSdk().verifyCertificateSignature(pinnedCertificatePem))) {
        print("Test $i");
      } else {
        throw Exception(certificateSigningResponse['message']);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    try {
      Future.delayed(Duration.zero, () async {
        // ===== 1. setDeviceBinding() stress testing =====
        // for (var i = 0; i < 1000000; i++) {
        // await E2eeSdkInSecureStorage().setDeviceBinding();
        //   print("Test $i");
        // }
        // print("1000000 setDeviceBinding records done");
        // ================================================

        // ===== 2. isDeviceBinding() stress testing ======
        // for (var i = 0; i < 1000000; i++) {
        // final bool isDeviceBinding =
        //     await E2eeSdkInSecureStorage().isDeviceBinding();
        //   print("Test $i");
        // }
        // print("1000000 isDeviceBinding records done");
        // ================================================

        // ======= 3. Backend server authentication =======
        // final String pinnedCertificatePem = await DefaultAssetBundle.of(context)
        //     .loadString("assets/app_server_cert.pem");

        // for (var i = 0; i < 1000000; i++) {
        //  await authenticateBackendServer(pinnedCertificatePem);
        //  print("Test $i");
        // }
        // print("1000000 backendServerAuthentication() records done");
        // =================================================

        // ================ 4. Password reset ==============
        // for (var i = 0; i < 10000; i++) {
        //   await resetPassword(i);
        // }
        // print("10000 password reset records done");
        // =================================================

        // ============== 5. Password verify ===============
        // for (var i = 0; i < 10000; i++) {
        //   await verifyPassword(i);
        // }
        // print("10000 password verify records done");
        // =================================================

        // === 6. Data Protection From Client To Server ====
        // for (var i = 0; i < 10000; i++) {
        //    await updateAccount(i);
        // }
        // print("10 DP from client to server records done.");
        // =================================================

        // === 7. Generate RSA Keypair in Secure Storage ===
        final int timeBefore = DateTime.now().millisecondsSinceEpoch;
        for (var i = 0; i < 100; i++) {
        final String clientKeyWrapper =
            await E2eeSdkInSecureStorage().generateRSAKeypair();
        // print("Test $i");
        }
        final int timeAfter = DateTime.now().millisecondsSinceEpoch;
        final int duration = timeAfter - timeBefore;
        print("E2EE generate RSA key pair in secure storage: $duration ms");
        print("10 RSA keypair generation done");
        // =================================================

        // ===== 8. Get wrapped client key from server =====
        // for (var i = 0; i < 100000; i++) {
        //   await importWrappedClientKey(i);
        // }
        // =================================================

        // ============= 9. Decrypt client data ============
        // await importWrappedClientKey(1);
        // for (var i = 0; i < 10000; i++) {
        //    await decryptUserData(i);
        // }
        // print("10000 decryptUserData() records done.");
        // =================================================

        // ============== 10. Reset Verify =================
        // for (var i = 0; i < 1000; i++) {
        //   await resetPassword(i);
        //   await verifyPassword(i);
        //   print("Test $i");
        // }
        // =================================================

        // ========= 11. Generate Device ID Keypair ========
        // for (var i = 0; i < 1000000; i++) {
        // await generateDeviceIdKeyPairInSecureStorage(i);
        // }
        // print("1000000 generateDeviceIdKeyPair() records done.");
        // =================================================

        // == 12. Generate Device Based Encrypted Password =
        // for (var i = 0; i < 1000; i++) {
        // await generateDeviceBasedEncryptedPassword(i);
        // await getDeviceBasedEncryptedPassword(i);
        // print("Test $i");
        // }
        // print("1000 generateDeviceBasedEncryptedPassword() records done.");
        // =================================================

        // =========== 13. Device registration  ============
        // for (var i = 0; i < 10; i++) {
        //   await registerDevice(i, pinnedCertificatePem);
        // }
        // print("10 registerDevice records done.");
        // =================================================

        // ========== 14. Sign by device id keypair ========
        // for (var i = 0; i < 1000; i++) {
        //  var plainData = "Hello World 1";
        // final String signature = await E2eeSdkInSecureStorage()
        //     .signByDeviceIdKeypair(Uint8List.fromList(utf8.encode(plainData)));
        //  print("Signature: $signature");
        // }
        // print("1000 signByDeviceIdKeypair() records done");
        // =================================================
      });
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
  }

  // Future<void> initStrongboxStatus() async {
  //   _e2eeBridgePlugin.isStrongboxAvailable().then((value) => setState(() {
  //         if (value!) {
  //           _strongboxMessage = "Strongbox is available";
  //         } else {
  //           _strongboxMessage = "Strongbox is unavailable";
  //         }
  //       }));

  //   if (!mounted) return;
  // }

  // Future<void> initGenerateApplicationCSR() async {
  //   CertificateInformation certificateInformation = CertificateInformation(
  //       "commonName",
  //       "country",
  //       "location",
  //       "state",
  //       "organizationName",
  //       "organizationUnit");

  //   _e2eeBridgePlugin
  //       .generateApplicationCSR(_asymmetricECKeyName, certificateInformation)
  //       .then((value) => setState(() {
  //             _applicationCSR = value!;
  //           }));

  //   if (!mounted) return;
  // }

  // Future<void> initGenerateEncryptedData() async {
  //   final Future<Uint8List> iv = generateRandomBytes(GCM_IV_LENGTH);
  //   final Future<Uint8List> aad = generateRandomBytes(AAD_LENGTH);

  //   final Future<EncryptedData> encryptedData = _e2eeBridgePlugin.aesEncrypt(
  //       _symmetricKeyName,
  //       Uint8List.fromList(utf8.encode(_plainData)),
  //       await iv,
  //       await aad);
  //   encryptedData.then((value) => setState(() {
  //         _encryptedData = base64Encode(value.ciphertext);
  //       }));

  //   _e2eeBridgePlugin
  //       .aesDecrypt(_symmetricKeyName, (await encryptedData).ciphertext,
  //           (await encryptedData).tag, (await encryptedData).iv, await aad)
  //       .then((value) => setState(() {
  //             _decryptedData = String.fromCharCodes(value!);
  //           }));

  //   if (!mounted) return;
  // }

  // Future<void> initGenerateDataSignature() async {
  //   _e2eeBridgePlugin
  //       .generateSignature(
  //           _asymmetricECKeyName, Uint8List.fromList(utf8.encode(_plainData)))
  //       .then((value) => setState(() {
  //             _signature = base64Encode(value!);
  //           }));

  //   if (!mounted) return;
  // }

  // Future<Uint8List> createImportableKey() async {
  //   // Generate target key
  //   final Future<Uint8List> targetKey = generateRandomBytes(32);
  //   final Future<Uint8List> iv = generateRandomBytes(12);
  //   final Future<Uint8List> ephemeralKey = generateRandomBytes(32);

  //   // Get public key
  //   final Future<String?> publicKeyPEM =
  //       E2eeBridge().getPublicKeyPEM(_asymmetricRSAKeyName);

  //   // Build authorization level
  //   final ASN1Set purposeSet = ASN1Set();
  //   purposeSet.add(ASN1Integer.fromInt(0));
  //   purposeSet.add(ASN1Integer.fromInt(1));
  //   final ASN1Object purpose =
  //       ASN1Object.preEncoded(0xA1, purposeSet.encodedBytes);
  //   final ASN1Object algorithm =
  //       ASN1Object.preEncoded(0xA2, ASN1Integer.fromInt(32).encodedBytes);
  //   final ASN1Object keySize =
  //       ASN1Object.preEncoded(0xA3, ASN1Integer.fromInt(256).encodedBytes);

  //   final ASN1Set blockModeSet = ASN1Set();
  //   blockModeSet.add(ASN1Integer.fromInt(32));
  //   final ASN1Object blockMode =
  //       ASN1Object.preEncoded(0xA4, blockModeSet.encodedBytes);

  //   final ASN1Set paddingSet = ASN1Set();
  //   paddingSet.add(ASN1Integer.fromInt(1));
  //   final ASN1Object padding =
  //       ASN1Object.preEncoded(0xA6, paddingSet.encodedBytes);

  //   final ASN1Object callerNonce =
  //       ASN1Object.preEncoded(0xA7, ASN1Null().encodedBytes);
  //   final ASN1Object minMacLength =
  //       ASN1Object.preEncoded(0xA8, ASN1Integer.fromInt(128).encodedBytes);
  //   final ASN1Object noAuthRequired = ASN1Object.fromBytes(
  //       Uint8List.fromList([0xBF, 0x83, 0x77, 0x02, 0x05, 0x00]));

  //   // Build sequence
  //   final ASN1Sequence authList = ASN1Sequence();
  //   authList.add(purpose);
  //   authList.add(algorithm);
  //   authList.add(keySize);
  //   authList.add(blockMode);
  //   authList.add(padding);
  //   authList.add(callerNonce);
  //   authList.add(minMacLength);
  //   authList.add(noAuthRequired);

  //   // Build description
  //   final ASN1Sequence descItems = ASN1Sequence();
  //   descItems.add(ASN1Integer.fromInt(3));
  //   descItems.add(authList);

  //   // Encrypt ephemeral keys
  //   final Future<Uint8List> encryptedEphemeralKey =
  //       encryptRSA((await publicKeyPEM)!, await ephemeralKey);

  //   // Encrypt ephemeral keys
  //   final Future<EncryptedData> encryptedTargetKey = encryptAES256GCM(
  //       await targetKey, await ephemeralKey, await iv, descItems.encodedBytes);

  //   // Build ASN.1 DER encoded sequence SecureKeyWrapper
  //   final ASN1Sequence secureKeyWrapper = ASN1Sequence();
  //   secureKeyWrapper.add(ASN1Integer.fromInt(0));
  //   secureKeyWrapper.add(ASN1OctetString(await encryptedEphemeralKey));
  //   secureKeyWrapper.add(ASN1OctetString((await encryptedTargetKey).iv));
  //   secureKeyWrapper.add(descItems);
  //   secureKeyWrapper
  //       .add(ASN1OctetString((await encryptedTargetKey).ciphertext));
  //   secureKeyWrapper.add(ASN1OctetString((await encryptedTargetKey).tag));

  //   return secureKeyWrapper.encodedBytes;
  // }

  // Future<void> initImportKey() async {
  //   // Import key to TEE
  //   const String newKeyAlias = "ImportedKey";
  //   await E2eeBridge().importAES256GCMKey(
  //       _asymmetricRSAKeyName, newKeyAlias, await createImportableKey(), true);

  //   final Future<Uint8List> iv = generateRandomBytes(GCM_IV_LENGTH);
  //   final Future<Uint8List> aad = generateRandomBytes(AAD_LENGTH);

  //   final Future<EncryptedData> encryptedData = _e2eeBridgePlugin.aesEncrypt(
  //       _symmetricKeyName,
  //       Uint8List.fromList(utf8.encode(_plainData)),
  //       await iv,
  //       await aad);
  //   encryptedData.then((value) => setState(() {
  //         _encryptedImportedData = base64Encode(value.ciphertext);
  //       }));

  //   _e2eeBridgePlugin
  //       .aesDecrypt(_symmetricKeyName, (await encryptedData).ciphertext,
  //           (await encryptedData).tag, (await encryptedData).iv, await aad)
  //       .then((value) => setState(() {
  //             _decryptedImportedData = String.fromCharCodes(value!);
  //           }));

  //   if (!mounted) return;
  // }

  Future<String> authenticateUser() async {
    // Authenticate user
    final LocalAuthentication auth = LocalAuthentication();
    final Future<bool> canAuthenticateWithBiometrics = auth.canCheckBiometrics;
    final bool canAuthenticate =
        await canAuthenticateWithBiometrics || await auth.isDeviceSupported();
    var deviceCsr = "";
    var encryptedPasswordBlock = "";

    if (canAuthenticate) {
      try {
        final bool didAuthenticate = await auth.authenticate(
            localizedReason: _authenticationMessage,
            options: const AuthenticationOptions(stickyAuth: true));
        if (!didAuthenticate) {
          throw "Failed to authenticate!";
        } else {
          // Generate device CSR
          // deviceCsr = await E2eeSdkInSecureStorage().generateDeviceIdKeypair(
          //     DistinguishedName("www.example.com", "ID", "location", "state",
          //         "organizationName", "organizationUnit"));
          // print("Device CSR: $deviceCsr");

          // Generate device based encrypted password
          const String publicKeyPem = '''
          -----BEGIN PUBLIC KEY-----
          MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEA08717ObQ9Plw3XAR80ad
          RMYRzEc9GxbNrbhOVHBCHRpSrgLkmX/gkjqpUj0B+mgW7Ta0qBhR+5JhFfDGoPbH
          +XmU/utLMhCwmtEayKrVka9CapaDWu1/nVInHvrDWd2cE9JusLYQBnTY0E9FiPJb
          YbhgUKG28dPwbeYpcFCPhMgZSkyvkWdKmR/RMcYohe9ewIxubPvcHRGmNAwcwNGN
          yAeyWowKSd7We+CoD3SHh/CFj/+JLZ9oecOrjlG5KitpassDkSsNDYvXLP1I6xBU
          SvAAMXmQkJ2V0LpSF0DpIaCXHxCFzDkpJ0mWWjJjeodoCWYGP/pEUMib0aPvS/Qt
          tNrVaJdCX9qLM5MnLV39R874vuF4kzBXrfemwWgMo7aedSTPVCl2d9dUMaTGrKq7
          dPJnRmI57A++LJPMNtyGnvfXCSZcf/hPudjiss4V+ufNqlmRilyl+RB6CEllPIb+
          LfN/khDJQym1dT9ESJ9nqNBH05FCou+ygOYkMfmPGX7XAgMBAAE=
          -----END PUBLIC KEY-----
          ''';
          const String oaepLabel = "FzDkpJ0mWWjJjeodoCWYGP/pEUMib0aPvS/Qt";
          final ResponseE2eeEncrypt newDevicePassword =
              await E2eeSdkInSecureStorage()
                  .generateDeviceBasedEncryptedPassword(
                      publicKeyPem, oaepLabel);
          encryptedPasswordBlock = newDevicePassword.encryptedDataBlockList[0];
          print("Encrypted user password: $encryptedPasswordBlock");

          // Get device based encrypted password
          // final ResponseE2eeEncrypt devicePassword =
          //     await E2eeSdkInSecureStorage()
          //         .getDeviceBasedEncryptedPassword(
          //             publicKeyPem, oaepLabel);
          // encryptedPasswordBlock = devicePassword.encryptedDataBlockList[0];
          // print("Encrypted user password: $encryptedPasswordBlock");
        }
      } on PlatformException {
        rethrow;
      }
    }
    return deviceCsr;
    // return encryptedPasswordBlock;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              // Text('Strongbox status: $_strongboxMessage\n'
              //     'Application CSR: $_applicationCSR\n'
              //     'Plain data: $_plainData\n'
              //     'Encrypted data: $_encryptedData\n'
              //     'Decrypted data: $_decryptedData\n'
              //     'Encrypted imported data: $_encryptedImportedData\n'
              //     'Decrypted imported data: $_decryptedImportedData\n'
              //     'Signature: $_signature\n'),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    // initStrongboxStatus();
                    // initGenerateApplicationCSR();
                    // initGenerateEncryptedData();
                    // initGenerateDataSignature();
                    // initImportKey();

                    final String encryptedPassword = await authenticateUser();
                    Text('Encrypted user password: $encryptedPassword');
                    // final E2eeSdkPlatform e2eeSdkPlatform = E2eeSdkPlatform();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lime[900],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 10)),
                  child: const Text(
                    "Load",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
