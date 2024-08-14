import 'dart:typed_data';
import 'package:kms_e2ee_package/src/kk/structure.dart';

import 'package:e2ee_sdk_flutter/core/e2ee_sdk.dart';
import 'package:e2ee_sdk_flutter/core/e2ee_sdk_in_secure_storage.dart';

/// This class defines all methods available in Kripta Key E2EE Mobile SDK
class E2eeSdkPackage {
  /// Generate a random string
  ///
  /// Passing parameter [length] in bytes and return random in String type.
  ///
  /// ```
  /// Example:
  ///
  /// import 'package:kms_e2ee_package/api.dart';
  ///
  /// void main() {
  ///   final String randomString = await E2eeSdkPackage().generateRandomString(10);
  ///   print(randomString);
  /// }
  /// ```
  Future<String> generateRandomString(int length) async {
    return E2eeSdk().generateRandomString(length);
  }

  /// Get RSA public key in PEM format from a [certificate]
  ///
  /// Passing a [certificate] in PEM format and extract public key from it.
  ///
  /// ```
  /// Example:
  ///
  /// import 'package:kms_e2ee_package/api.dart';
  ///
  /// void main() {
  ///   const String certificatePem = '''
  ///   -----BEGIN CERTIFICATE-----
  ///   MIIEKzCCAxOgAwIBAgIBADANBgkqhkiG9w0BAQ0FADCBpDELMAkGA1UEBhMCSUQx
  ///   FzAVBgNVBAgMDktlcHVsYXVhbiBSaWF1MQ4wDAYDVQQHDAVCYXRhbTEcMBoGA1UE
  ///   CgwTUHJvZHVjdCBEZXZlbG9wbWVudDEMMAoGA1UECwwDUm5EMR0wGwYDVQQDDBR3
  ///   d3cua2xhdmlza3JpcHRhLmNvbTEhMB8GCSqGSIb3DQEJARYSc3VwcG9ydEBrbGF2
  ///   aXMuY29tMB4XDTIzMTAxODA5NDEwMFoXDTI0MTAxNzA5NDEwMFowgaQxCzAJBgNV
  ///   BAYTAklEMRcwFQYDVQQIDA5LZXB1bGF1YW4gUmlhdTEOMAwGA1UEBwwFQmF0YW0x
  ///   HDAaBgNVBAoME1Byb2R1Y3QgRGV2ZWxvcG1lbnQxDDAKBgNVBAsMA1JuRDEdMBsG
  ///   A1UEAwwUd3d3LmtsYXZpc2tyaXB0YS5jb20xITAfBgkqhkiG9w0BCQEWEnN1cHBv
  ///   cnRAa2xhdmlzLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMTY
  ///   AivIM33QhcinV2CsWNiAdt3Guww3YLOMQs5bz1pd7KJIy6LWGr3+U0ji2x1SNgVH
  ///   Ns56EPaK2IKk4okgwlyDmIS+Xchy0OuSop9w6p7LC/nPPUjrhb8cX1ME1WHNsghY
  ///   gaf83OEpzLxcSjE7JP8B+XZ0/gJ7bUNx2sBHGQJVuT3zQCOVusO6nJGLaf8WgdRs
  ///   HtljEjuYHPG9IjQtNjSoL4gQIpihYls25dCdeqGqCWF73zVZMjd489gwB97V/w5L
  ///   8GIxlWUxzEjIkPGv6sUntzZQv7kwxJPsm0XsSJdNNOQd8Lcwb1ckjWbgLcGywUwJ
  ///   TG265p4KA7nlgdct4HsCAwEAAaNmMGQwEgYDVR0TAQH/BAgwBgEB/wIBATAOBgNV
  ///   HQ8BAf8EBAMCAQYwHQYDVR0OBBYEFGyo9MdssVzvgQmRb2EEaiPMnmD+MB8GA1Ud
  ///   IwQYMBaAFGyo9MdssVzvgQmRb2EEaiPMnmD+MA0GCSqGSIb3DQEBDQUAA4IBAQA0
  ///   F6iF4BlKclWGYJFFEIPQqwUyLskYTenn3nMu41lCanmHB+VAbJq9mIeoNZ1cnjxl
  ///   EmKbbR/UMvREmWtJcOFzMH7OPF8E6a3WY1iemlIHNbEtjct0z4PsUeXsmaHRNb7o
  ///   MgQPIaFgFdDijoYfJOcNb2U/Chn6RF6aHvJJfUPgjY1TBLqhj+YmnzOctC+38KeT
  ///   Mbd4KXBHCcwDIECOUOXx9N24iCL7QuqjkTW1dnraC5KvkwyA944idckZABHWM853
  ///   c4G2cPAoJxrMCb06xSTHk1BipPwy4bQM6Tpo7Ykj4d+Ws6I2LJffDCuvaLKcL+AP
  ///   k2R6mPb3d1BHpMTe8eX/
  ///   -----END CERTIFICATE-----
  ///   ''';
  ///
  ///   final String rsaPublicKeyPem = await E2eeSdkPackage().getRSAPublicKeyPemFromCertificate(certificatePem);
  ///   print(rsaPublicKeyPem);
  /// }
  /// ```
  Future<String> getRSAPublicKeyPemFromCertificate(String certificate) async {
    return E2eeSdk().getRSAPublicKeyPemFromCertificate(certificate);
  }

  /// Encrypt [data] by using RSA mechanism
  ///
  /// Passing [rsaPublicKeyPem] as the key to encrypt [data] and optional [oaepLabel]
  ///
  /// ```
  /// Example:
  ///
  /// import 'dart:typed_data';
  /// import 'dart:convert';
  ///
  /// import 'package:kms_e2ee_package/api.dart';
  ///
  /// void main() {
  ///   const String rsaPublicKeyPem = '''
  ///   -----BEGIN PUBLIC KEY-----
  ///   MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEA08717ObQ9Plw3XAR80ad
  ///   RMYRzEc9GxbNrbhOVHBCHRpSrgLkmX/gkjqpUj0B+mgW7Ta0qBhR+5JhFfDGoPbH
  ///   +XmU/utLMhCwmtEayKrVka9CapaDWu1/nVInHvrDWd2cE9JusLYQBnTY0E9FiPJb
  ///   YbhgUKG28dPwbeYpcFCPhMgZSkyvkWdKmR/RMcYohe9ewIxubPvcHRGmNAwcwNGN
  ///   yAeyWowKSd7We+CoD3SHh/CFj/+JLZ9oecOrjlG5KitpassDkSsNDYvXLP1I6xBU
  ///   SvAAMXmQkJ2V0LpSF0DpIaCXHxCFzDkpJ0mWWjJjeodoCWYGP/pEUMib0aPvS/Qt
  ///   tNrVaJdCX9qLM5MnLV39R874vuF4kzBXrfemwWgMo7aedSTPVCl2d9dUMaTGrKq7
  ///   dPJnRmI57A++LJPMNtyGnvfXCSZcf/hPudjiss4V+ufNqlmRilyl+RB6CEllPIb+
  ///   LfN/khDJQym1dT9ESJ9nqNBH05FCou+ygOYkMfmPGX7XAgMBAAE=
  ///   -----END PUBLIC KEY-----
  ///   ''';
  ///
  ///   final String data = "Hello World";
  ///   const String oaepLabel = "oaepLabel";
  ///
  ///   final Uint8List ciphertext = await E2eeSdkPackage().encryptRSA(
  ///                                                 rsaPublicKeyPem,
  ///                                                 Uint8List.fromList(utf8.encode(data)),
  ///                                                 Uint8List.fromList(utf8.encode(oaepLabel)));
  ///   print(base64Encode(ciphertext));
  /// }
  /// ```
  Future<Uint8List> encryptRSA(String rsaPublicKeyPem, Uint8List data,
      [Uint8List? oaepLabel]) async {
    return E2eeSdk().encryptRSA(rsaPublicKeyPem, data);
  }

  /// Verify signature by using RSA mechanism
  ///
  /// Passing [messageBytes] and its [signatureBytes].
  /// Verify the signature correctness by using [rsaPublicKeyPem].
  ///
  /// ```
  /// Example:
  ///
  /// import 'dart:typed_data';
  ///
  /// import 'package:kms_e2ee_package/api.dart';
  ///
  /// void main() {
  ///   const String rsaPublicKeyPem = '''
  ///   -----BEGIN PUBLIC KEY-----
  ///   MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEA08717ObQ9Plw3XAR80ad
  ///   RMYRzEc9GxbNrbhOVHBCHRpSrgLkmX/gkjqpUj0B+mgW7Ta0qBhR+5JhFfDGoPbH
  ///   +XmU/utLMhCwmtEayKrVka9CapaDWu1/nVInHvrDWd2cE9JusLYQBnTY0E9FiPJb
  ///   YbhgUKG28dPwbeYpcFCPhMgZSkyvkWdKmR/RMcYohe9ewIxubPvcHRGmNAwcwNGN
  ///   yAeyWowKSd7We+CoD3SHh/CFj/+JLZ9oecOrjlG5KitpassDkSsNDYvXLP1I6xBU
  ///   SvAAMXmQkJ2V0LpSF0DpIaCXHxCFzDkpJ0mWWjJjeodoCWYGP/pEUMib0aPvS/Qt
  ///   tNrVaJdCX9qLM5MnLV39R874vuF4kzBXrfemwWgMo7aedSTPVCl2d9dUMaTGrKq7
  ///   dPJnRmI57A++LJPMNtyGnvfXCSZcf/hPudjiss4V+ufNqlmRilyl+RB6CEllPIb+
  ///   LfN/khDJQym1dT9ESJ9nqNBH05FCou+ygOYkMfmPGX7XAgMBAAE=
  ///   -----END PUBLIC KEY-----
  ///   ''';
  ///
  ///   const String message = "ped[fc`qclYidr[m";
  ///   const String signature = "Ve6xUBPX+/hLk+7X6gUAvi4lGesbBetza5IktPfn3H+7TB+F52eONSfWto9DmrJfkxINWfopMkgT25y8zN73uk/WBuGC1ZYQ/FxeBTXxKCg7VCg+gLCcWYNFVVTXEj0VeQ+tCQF3kzBGs+Q4OaxVBYFRJShEEnxLNtrkINdEcnekHoOs7fNeIcRlcVRTZO/ZmW2kGA4Sps8YCsKqy1dTBojZP/1ut612SIFA3QioIOoYrjzFhPhWmGka9ayFMRE9ZMqFRbe8mDJo3OmoR4aht25HG48uO+ZjfIYExJHNwn0MO2HEqTXHsaOj406SI83ftjUA3yj0LupC+xCxyyvGKg==";
  ///
  ///   final bool verifyResult = await E2eeSdkPackage().verifyRSASignature(rsaPublicKeyPem,
  ///                                                                       Uint8List.fromList(utf8.encode(message)),
  ///                                                                       base64Decode(signature));
  ///   print(verifyResult);
  /// }
  /// ```
  Future<bool> verifyRSASignature(String rsaPublicKeyPem,
      Uint8List messageBytes, Uint8List signatureBytes) async {
    return E2eeSdk()
        .verifyRSASignature(rsaPublicKeyPem, messageBytes, signatureBytes);
  }

  /// Generate bytes of random
  ///
  /// Passing [length] to define the length of random bytes to be generated.
  ///
  /// ```
  /// Example:
  ///
  /// import 'dart:typed_data';
  ///
  /// import 'package:kms_e2ee_package/api.dart';
  ///
  /// void main() {
  ///   final Uint8List randomBytes = await E2eeSdkPackage().generateRandomBytes(10);
  /// }
  /// ```
  Future<Uint8List> generateRandomBytes(int length) async {
    return E2eeSdk().generateRandomBytes(length);
  }

  /// Fetch wrapped client key from secure storage.
  ///
  /// Return [KMSWrappedKeyMetadata]
  ///
  /// ```
  /// Example:
  ///
  /// import 'package:kms_e2ee_package/api.dart';
  ///
  /// void main() {
  ///   final KMSWrappedKeyMetadata kmsWrappedKeyMetadata = await E2eeSdkPackage().fetchWrappedClientKeyFromSecureStorage();
  /// }
  /// ```
  Future<KMSWrappedKeyMetadata> fetchWrappedClientKeyFromSecureStorage() async {
    return E2eeSdkInSecureStorage().fetchWrappedClientKey();
  }

  /// Generate RSA key pair in secure storage.
  ///
  /// Passing [requireAuth] with default false and [allowOverwrite] with default true.
  /// Return a public key of the key pair in PEM format.
  /// Once assigning [requireAuth] to true, the user must authenticate themselves by using
  /// biometric or mobile PIN/Passcode to use the key.
  ///
  /// ```
  /// Example:
  ///
  /// import 'package:kms_e2ee_package/api.dart';
  ///
  /// void main() {
  ///   final String publicKeyPem = await E2eeSdkPackage().generateRSAKeypairInSecureStorage();
  ///   print(publicKeyPem);
  /// }
  /// ```
  Future<String> generateRSAKeypairInSecureStorage(
      [bool requireAuth = false, bool allowOverwrite = true]) async {
    return E2eeSdkInSecureStorage().generateRSAKeypair();
  }

  /// Update [encodedWrappedClientKey] and [encodedWrappedKMSKeyWrapped] to the secure storage
  ///
  /// The usage of this API is for E2EE Data Protection from server to client use case.
  /// The application server returns two wrapped keys that consist of
  /// a wrapped key by an internal mobile key pair [encodedWrappedClientKey]
  /// and another wrapped key by KMS internal key [encodedWrappedKMSKeyWrapped].
  /// Both keys are in base64 encoded format.
  ///
  /// When user activate device binding, then [isDeviceBinding] must be set to true.
  ///
  /// ```
  /// Example:
  ///
  /// import 'package:kms_e2ee_package/api.dart';
  ///
  /// void main() {
  ///   final const encodedWrappedClientKey = "e206IOKAnGoxWEFjUkltQ2g1ZGhORm1qV2s3aUlXOWpER01oaGxsS1F6eExhb3lOZz3igJ0sIGM6IOKAnGoxWEFjUkltQ2gzZWhkTW15YWs2bjBaWHBWSFowNVE4L3RRUHFEQVRETmhJQT094oCdfQo=";
  ///   final const encodedWrappedKMSKeyWrapped = "e206IOKAnGoxWEFjUkltQ2g1ZGhORm1qV2s3aUlXOWpER01oaGxsS1F6eExhb3lOZz3igJ0sIGM6IOKAnGoxWEFjUkltQ2gzZWhkTW15YWs2bjBaWHBWSFowNVE4L3RRUHFEQVRETmhJQT094oCdfQo=";
  ///
  ///   await E2eeSdkPackage().updateClientKeyToSecureStorage(encodedWrappedClientKey, encodedWrappedKMSKeyWrapped);
  /// }
  /// ```
  Future<void> updateClientKeyToSecureStorage(
      String encodedWrappedClientKey, String encodedWrappedKMSKeyWrapped,
      [bool isDeviceBinding = false]) async {
    return E2eeSdkInSecureStorage()
        .updateClientKey(encodedWrappedClientKey, encodedWrappedKMSKeyWrapped);
  }

  /// Encrypt data from mobile side to KMS server
  ///
  /// Use this method to encrypt data by using RSA mechanism and send the encrypted data
  /// to KMS server. The data is encrypted by using public key sent by the application
  /// server during preAuthentication.
  ///
  /// Passing object parameter [RequestE2eeEncrypt] and return [ResponseE2eeEncrypt]
  ///
  /// ```
  /// Example:
  ///
  /// import 'package:kms_e2ee_package/api.dart';
  ///
  /// void main() {
  ///   const String publicKeyPem = '''
  ///   -----BEGIN PUBLIC KEY-----
  ///   MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEA08717ObQ9Plw3XAR80ad
  ///   RMYRzEc9GxbNrbhOVHBCHRpSrgLkmX/gkjqpUj0B+mgW7Ta0qBhR+5JhFfDGoPbH
  ///   +XmU/utLMhCwmtEayKrVka9CapaDWu1/nVInHvrDWd2cE9JusLYQBnTY0E9FiPJb
  ///   YbhgUKG28dPwbeYpcFCPhMgZSkyvkWdKmR/RMcYohe9ewIxubPvcHRGmNAwcwNGN
  ///   yAeyWowKSd7We+CoD3SHh/CFj/+JLZ9oecOrjlG5KitpassDkSsNDYvXLP1I6xBU
  ///   SvAAMXmQkJ2V0LpSF0DpIaCXHxCFzDkpJ0mWWjJjeodoCWYGP/pEUMib0aPvS/Qt
  ///   tNrVaJdCX9qLM5MnLV39R874vuF4kzBXrfemwWgMo7aedSTPVCl2d9dUMaTGrKq7
  ///   dPJnRmI57A++LJPMNtyGnvfXCSZcf/hPudjiss4V+ufNqlmRilyl+RB6CEllPIb+
  ///   LfN/khDJQym1dT9ESJ9nqNBH05FCou+ygOYkMfmPGX7XAgMBAAE=
  ///   -----END PUBLIC KEY-----
  ///   ''';
  ///
  ///   const String plainData = "Hello World";
  ///   const String oaepLabel = "BXrfemwWgMo7aedSTPVCl2d9dUMaTGrKq7";
  ///
  ///   final RequestE2eeEncrypt requestE2eeEncrypt = RequestE2eeEncrypt(
  ///                                       publicKeyPem,
  ///                                       [Uint8List.fromList(utf8.encode(plainData))],
  ///                                       oaepLabel);
  ///   final ResponseE2eeEncrypt responseE2eeEncrypt = await E2eeSdkPackage().e2eeEncrypt(requestE2eeEncrypt);
  /// }
  /// ```
  Future<ResponseE2eeEncrypt> e2eeEncrypt(RequestE2eeEncrypt request) async {
    return E2eeSdk().e2eeEncrypt(request);
  }

  /// Decrypt data from KMS server to mobile side
  ///
  /// Use this method to decrypt data from KMS server by using RSA mechanism.
  /// The wrappedClientKey is retrieved from mobile TEE or secure storage.
  /// First, you must download the client key and store the key in the secure storage.
  /// Then use this API to decrypt the data.
  ///
  /// Passing object parameter [RequestE2eeDecrypt] and return [ResponseE2eeDecrypt]
  ///
  /// ```
  /// Example:
  /// import 'dart:typed_data';
  /// import 'dart:convert';
  ///
  /// import 'package:kms_e2ee_package/api.dart';
  ///
  /// void main() {
  ///   final RequestE2eeDecrypt requestE2eeDecrypt = RequestE2eeDecrypt(
  ///                                       ["BXrfemwWgMo7aedSTPVCl2d9dUMaTGrKq7", "Zcf/hPudjiss4V+ufNqlmRilyl+RB6CEl"]);
  ///   final ResponseE2eeDecrypt responseE2eeDecrypt = await E2eeSdkPackage().e2eeDecryptInSecureStorage(requestE2eeDecrypt);
  /// }
  /// ```
  Future<ResponseE2eeDecrypt> e2eeDecryptInSecureStorage(
      RequestE2eeDecrypt request) async {
    return E2eeSdkInSecureStorage().e2eeDecrypt(request);
  }

  /// Set deviceBinding flag if application is bound to a device
  ///
  /// If the user and application are authenticated by using device based authentication,
  /// this flag must be set during device registration process.
  ///
  /// ```
  /// Example:
  ///
  /// import 'package:kms_e2ee_package/api.dart';
  ///
  /// void main() {
  ///   await E2eeSdkPackage().setDeviceBindingInSecureStorage();
  /// }
  /// ```
  Future<void> setDeviceBindingInSecureStorage() async {
    return E2eeSdkInSecureStorage().setDeviceBinding();
  }

  /// Verify if the application has been registered using device binding scenario.
  ///
  /// Return true if the application is bound to a device or false if not.
  ///
  /// ```
  /// Example:
  ///
  /// import 'package:kms_e2ee_package/api.dart';
  ///
  /// void main() {
  ///   final bool isDeviceBinding = await E2eeSdkPackage().isDeviceBindingInSecureStorage();
  ///   print(isDeviceBinding);
  /// }
  /// ```
  Future<bool> isDeviceBindingInSecureStorage() async {
    return E2eeSdkInSecureStorage().isDeviceBinding();
  }

  /// Generate device Id key pair
  ///
  /// Passing [DistinguishedName] parameter and generate device key pair which type is EC key.
  /// Return the device Certificate Signing Request (CSR) in a PEM format.
  ///
  /// ```
  /// Example:
  ///
  /// import 'package:kms_e2ee_package/api.dart';
  ///
  /// void main() {
  ///   final DistinguishedName distinguishedName = DistinguishedName("www.example.com", "ID"
  ///                                                                 "location", "state",
  ///                                                                  "organizationName", "organizationUnit");
  ///   final String deviceCsr = await E2eeSdkPackage().generateDeviceIdKeypairInSecureStorage(distinguishedName);
  ///   print(deviceCsr);
  /// }
  /// ```
  Future<String> generateDeviceIdKeypairInSecureStorage(
      DistinguishedName distinguishedName) async {
    return E2eeSdkInSecureStorage().generateDeviceIdKeypair(distinguishedName);
  }

  /// Verify the correctness of [certificateChain]
  ///
  /// ```
  /// Example:
  ///
  /// import 'package:kms_e2ee_package/api.dart';
  ///
  /// void main() {
  ///   const String certificateChain = '''
  ///   -----BEGIN CERTIFICATE-----
  ///   MIIB8TCCAZegAwIBAgIBADAKBggqhkjOPQQDBDBgMQswCQYDVQQGEwJJRDEXMBUG
  ///   A1UECAwOS2VwdWxhdWFuIFJpYXUxDjAMBgNVBAcMBUJhdGFtMRMwEQYDVQQKDApz
  ///   YW5kaGlndW5hMRMwEQYDVQQDDApzYW5kaGlndW5hMB4XDTIzMDkwODA4NTk0NVoX
  ///   DTI0MDkwNzA4NTk0NVowYDELMAkGA1UEBhMCSUQxFzAVBgNVBAgMDktlcHVsYXVh
  ///   biBSaWF1MQ4wDAYDVQQHDAVCYXRhbTETMBEGA1UECgwKc2FuZGhpZ3VuYTETMBEG
  ///   A1UEAwwKc2FuZGhpZ3VuYTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABKZELXXm
  ///   LFfvzehWOsgeBpMBAb/pCx3YI0G4u/IxU5o7J3jmPGSwyL1v5kPdr5SShDkuCtKY
  ///   sK8In9OI3exI/x6jQjBAMB0GA1UdDgQWBBQi7Yq2o0Nwy0ngjasoPMaR1fx6lDAf
  ///   BgNVHSMEGDAWgBQi7Yq2o0Nwy0ngjasoPMaR1fx6lDAKBggqhkjOPQQDBANIADBF
  ///   AiBGpqJpBQls783lEsV5crRHeC/Ow6emJfcZ7u4nEdUWNgIhAIn1iSQvnmZQ9LLc
  ///   ltznCxg7NWkz/0kv4JryYs5tevHr
  ///   -----END CERTIFICATE-----
  ///   -----BEGIN CERTIFICATE-----
  ///   MIICFTCCAbugAwIBAgIBADAKBggqhkjOPQQDBDBgMQswCQYDVQQGEwJJRDEXMBUG
  ///   A1UECAwOS2VwdWxhdWFuIFJpYXUxDjAMBgNVBAcMBUJhdGFtMRMwEQYDVQQKDApz
  ///   YW5kaGlndW5hMRMwEQYDVQQDDApzYW5kaGlndW5hMB4XDTIzMDgyMzA3NTkxMloX
  ///   DTI0MDgyMjA3NTkxMlowYDELMAkGA1UEBhMCSUQxFzAVBgNVBAgMDktlcHVsYXVh
  ///   biBSaWF1MQ4wDAYDVQQHDAVCYXRhbTETMBEGA1UECgwKc2FuZGhpZ3VuYTETMBEG
  ///   A1UEAwwKc2FuZGhpZ3VuYTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABKZELXXm
  ///   LFfvzehWOsgeBpMBAb/pCx3YI0G4u/IxU5o7J3jmPGSwyL1v5kPdr5SShDkuCtKY
  ///   sK8In9OI3exI/x6jZjBkMBIGA1UdEwEB/wQIMAYBAf8CAQEwDgYDVR0PAQH/BAQD
  ///   AgEGMB0GA1UdDgQWBBQi7Yq2o0Nwy0ngjasoPMaR1fx6lDAfBgNVHSMEGDAWgBQi
  ///   7Yq2o0Nwy0ngjasoPMaR1fx6lDAKBggqhkjOPQQDBANIADBFAiEA2Biipfrax5FH
  ///   pl34lBbomdcXtq/Y1p9udJngJj1E/PkCIBoVsyy77nDd0VdxgoMjlgucd08NgHFJ
  ///   pnBgUL1QHurq
  ///   -----END CERTIFICATE-----
  ///   ''';
  ///
  ///   final bool isCertificateVerified = await E2eeSdkPackage().verifyCertificateSignature(certificateChain);
  ///   print(isCertificateVerified);
  /// }
  /// ```
  Future<bool> verifyCertificateSignature(String certificateChain) async {
    return E2eeSdk().verifyCertificateSignature(certificateChain);
  }

  /// Generate device based encrypted password
  ///
  /// Generate an AES-GCM-256 key in mobile TEE and encrypt the device id by using the key.
  /// The ciphertext resulted from the encryption is base64 encoded, and it is encrypted by
  /// using RSA mechanism.
  ///
  /// RSA public key is extracted from the [authPublicKeyPEM] sent by the application server.
  /// Passing parameter [oaepLabel] to protect the integrity.
  ///
  /// ```
  /// Example:
  ///
  /// import 'dart:typed_data';
  /// import 'dart:convert';
  ///
  /// import 'package:kms_e2ee_package/api.dart';
  ///
  /// void main() {
  ///   const String authPublicKeyPEM = '''
  ///   -----BEGIN PUBLIC KEY-----
  ///   MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEA08717ObQ9Plw3XAR80ad
  ///   RMYRzEc9GxbNrbhOVHBCHRpSrgLkmX/gkjqpUj0B+mgW7Ta0qBhR+5JhFfDGoPbH
  ///   +XmU/utLMhCwmtEayKrVka9CapaDWu1/nVInHvrDWd2cE9JusLYQBnTY0E9FiPJb
  ///   YbhgUKG28dPwbeYpcFCPhMgZSkyvkWdKmR/RMcYohe9ewIxubPvcHRGmNAwcwNGN
  ///   yAeyWowKSd7We+CoD3SHh/CFj/+JLZ9oecOrjlG5KitpassDkSsNDYvXLP1I6xBU
  ///   SvAAMXmQkJ2V0LpSF0DpIaCXHxCFzDkpJ0mWWjJjeodoCWYGP/pEUMib0aPvS/Qt
  ///   tNrVaJdCX9qLM5MnLV39R874vuF4kzBXrfemwWgMo7aedSTPVCl2d9dUMaTGrKq7
  ///   dPJnRmI57A++LJPMNtyGnvfXCSZcf/hPudjiss4V+ufNqlmRilyl+RB6CEllPIb+
  ///   LfN/khDJQym1dT9ESJ9nqNBH05FCou+ygOYkMfmPGX7XAgMBAAE=
  ///   -----END PUBLIC KEY-----
  ///   ''';
  ///   const String oaepLabel = "DpIaCXHxCFzDkpJ0mWWjJjeodoCWYGP/pEUMib";
  ///
  ///   final ResponseE2eeEncrypt deviceBasedEncryptedPassword = await E2eeSdkPackage().generateDeviceBasedEncryptedPasswordInSecureStorage(
  ///                                                             authPublicKeyPEM, oaepLabel);
  /// }
  /// ```
  Future<ResponseE2eeEncrypt>
      generateDeviceBasedEncryptedPasswordInSecureStorage(
          String authPublicKeyPEM, String oaepLabel) async {
    return E2eeSdkInSecureStorage()
        .generateDeviceBasedEncryptedPassword(authPublicKeyPEM, oaepLabel);
  }

  /// Get device based encrypted password
  ///
  /// Get an AES-GCM-256 key from mobile TEE and encrypt the device id by using the key.
  /// The ciphertext resulted from the encryption is base64 encoded, and it is encrypted by
  /// using RSA mechanism.
  ///
  /// RSA public key is extracted from the [authPublicKeyPEM] sent by the application server.
  /// Passing parameter [oaepLabel] to protect the integrity.
  ///
  /// ```
  /// Example:
  ///
  /// import 'dart:typed_data';
  /// import 'dart:convert';
  ///
  /// import 'package:kms_e2ee_package/api.dart';
  ///
  /// void main() {
  ///   const String authPublicKeyPEM = '''
  ///   -----BEGIN PUBLIC KEY-----
  ///   MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEA08717ObQ9Plw3XAR80ad
  ///   RMYRzEc9GxbNrbhOVHBCHRpSrgLkmX/gkjqpUj0B+mgW7Ta0qBhR+5JhFfDGoPbH
  ///   +XmU/utLMhCwmtEayKrVka9CapaDWu1/nVInHvrDWd2cE9JusLYQBnTY0E9FiPJb
  ///   YbhgUKG28dPwbeYpcFCPhMgZSkyvkWdKmR/RMcYohe9ewIxubPvcHRGmNAwcwNGN
  ///   yAeyWowKSd7We+CoD3SHh/CFj/+JLZ9oecOrjlG5KitpassDkSsNDYvXLP1I6xBU
  ///   SvAAMXmQkJ2V0LpSF0DpIaCXHxCFzDkpJ0mWWjJjeodoCWYGP/pEUMib0aPvS/Qt
  ///   tNrVaJdCX9qLM5MnLV39R874vuF4kzBXrfemwWgMo7aedSTPVCl2d9dUMaTGrKq7
  ///   dPJnRmI57A++LJPMNtyGnvfXCSZcf/hPudjiss4V+ufNqlmRilyl+RB6CEllPIb+
  ///   LfN/khDJQym1dT9ESJ9nqNBH05FCou+ygOYkMfmPGX7XAgMBAAE=
  ///   -----END PUBLIC KEY-----
  ///   ''';
  ///   const String oaepLabel = "DpIaCXHxCFzDkpJ0mWWjJjeodoCWYGP/pEUMib";
  ///
  ///   final ResponseE2eeEncrypt deviceBasedEncryptedPassword = await E2eeSdkPackage().getDeviceBasedEncryptedPasswordFromSecureStorage(
  ///                                                             authPublicKeyPEM, oaepLabel);
  /// }
  /// ```
  Future<ResponseE2eeEncrypt> getDeviceBasedEncryptedPasswordFromSecureStorage(
      String authPublicKeyPEM, String oaepLabel) async {
    return E2eeSdkInSecureStorage()
        .getDeviceBasedEncryptedPassword(authPublicKeyPEM, oaepLabel);
  }

  /// Sign [plainData] by using device key pair in mobile TEE/secure storage
  ///
  /// Return signature in binary format.
  ///
  /// ```
  /// Example:
  ///
  /// import 'dart:typed_data';
  /// import 'dart:convert';
  ///
  /// import 'package:kms_e2ee_package/api.dart';
  ///
  /// void main() {
  ///   const String plainData = "Hello World";
  ///   const Uint8List signature = await E2eeSdkPackage().signByDeviceIdKeypairInSecureStorage(Uint8List.fromList(utf8.encode(plainData)));
  ///   print(signature);
  /// }
  /// ```
  Future<Uint8List> signByDeviceIdKeypairInSecureStorage(
      Uint8List plainData) async {
    return E2eeSdkInSecureStorage().signByDeviceIdKeypair(plainData);
  }

  /// Sign [digest] by using device key pair in mobile TEE/secure storage
  ///
  /// Return signature in binary format.
  ///
  /// ```
  /// Example:
  ///
  /// import 'dart:typed_data';
  /// import 'dart:convert';
  ///
  /// import 'package:kms_e2ee_package/api.dart';
  ///
  /// void main() {
  ///   const String digest = "DpIaCXHxCFzDkpJ0mWWjJjeodoCWYGP/pEUMib";
  ///   const Uint8List signature = await E2eeSdkPackage().signDigestByDeviceIdKeypairInSecureStorage(Uint8List.fromList(utf8.encode(digest)));
  ///   print(signature);
  /// }
  /// ```
  Future<Uint8List> signDigestByDeviceIdKeypairInSecureStorage(
      Uint8List digest) async {
    return E2eeSdkInSecureStorage().signDigestByDeviceIdKeypair(digest);
  }

  /// Calculate message digest from [plainData] using the given [hashAlgo]
  /// Available digest types: `SHA-256`, `SHA-384`, and `SHA-512`
  ///
  /// Return message digest.
  ///
  /// ```
  /// Example:
  ///
  /// import 'dart:typed_data';
  /// import 'dart:convert';
  ///
  /// import 'package:kms_e2ee_package/api.dart';
  ///
  /// void main() {
  ///   const String plainData = "Hello World";
  ///   const String signature = await E2eeSdkPackage().calculateDigest(Uint8List.fromList(utf8.encode(plainData)), "SHA-512");
  ///   print(signature);
  /// }
  /// ```
  Future<Uint8List> calculateDigest(Uint8List plainData, String hashAlgo) async {
    return E2eeSdk().calculateDigest(plainData, hashAlgo);
  }

  /// Unregister device and remove device binding status
  ///
  /// If the user wants to unregister the device, then the device binding status must be deleted.
  /// Please be noted, the unregistration process must be completed by removing the user and device entities from database.
  ///
  /// ```
  /// Example:
  ///
  /// import 'package:kms_e2ee_package/api.dart';
  ///
  /// void main() {
  ///   await E2eeSdkPackage().unregisterDeviceFromSecureStorage();
  /// }
  /// ```
  Future<void> unregisterDeviceFromSecureStorage() async {
    return E2eeSdkInSecureStorage().unregisterDevice();
  }

  /// Verify if secure key import is available on platform.
  ///
  /// Return true if secure key import is available.
  ///
  /// ```
  /// Example:
  ///
  /// import 'package:kms_e2ee_package/api.dart';
  ///
  /// void main() {
  ///   final bool isSecureKeyImportAvailable = await E2eeSdkPackage().isSecureKeyImportAvailableInSecureStorage();
  ///   print(isSecureKeyImportAvailable);
  /// }
  /// ```
  Future<bool?> isSecureKeyImportAvailableInSecureStorage() async {
    return E2eeSdkInSecureStorage().isSecureKeyImportAvailable();
  }
}
