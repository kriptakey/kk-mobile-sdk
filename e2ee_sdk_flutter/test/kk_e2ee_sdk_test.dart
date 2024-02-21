import 'dart:convert';
import 'dart:typed_data';

import 'package:e2ee_sdk_flutter/core/exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e2ee_sdk_flutter/api.dart';
import 'api_client.dart';

void main() {
  final ApiClient apiClient = ApiClient();
  const String username = "E2eeUser";
  const String userPassword = "E2eeUserPassword";

  Future<void> resetPassword(int i) async {
    dynamic preAuthenticationResponse = await apiClient.preAuthentication();

    var usernameTesting = username + i.toString();
    var userPasswordTesting = userPassword + i.toString();

    final RequestE2eeEncrypt requestE2eeEncrypt = RequestE2eeEncrypt(
        preAuthenticationResponse['publicKey'],
        preAuthenticationResponse['oaepLabel'],
        [Uint8List.fromList(utf8.encode(userPasswordTesting))]);

    final ResponseE2eeEncrypt responseE2eeEncrypt =
        await E2eeSdk().e2eeEncrypt(requestE2eeEncrypt);

    Map<String, dynamic> userData = {
      "name": usernameTesting,
      "encryptedPasswordBlock": responseE2eeEncrypt.encryptedDataBlockList[0],
      "publicKey": preAuthenticationResponse['publicKey'],
      "e2eeSessionId": preAuthenticationResponse['e2eeSessionId'],
      "metaData": responseE2eeEncrypt.metadata
    };

    dynamic registerUserWithPasswordResponse =
        await apiClient.registerUserWithPassword(userData);
    if (registerUserWithPasswordResponse['message'] != "User registered!") {
      print(registerUserWithPasswordResponse['message']);
    }
  }

  Future<void> verifyPassword(int i) async {
    dynamic preAuthenticationResponse = await apiClient.preAuthentication();

    var usernameTesting = username + i.toString();
    var userPasswordTesting = userPassword + i.toString();

    final RequestE2eeEncrypt requestE2eeEncrypt = RequestE2eeEncrypt(
      preAuthenticationResponse['publicKey'],
      preAuthenticationResponse['oaepLabel'],
      [Uint8List.fromList(utf8.encode(userPasswordTesting))],
    );

    final ResponseE2eeEncrypt responseE2eeEncrypt =
        await E2eeSdk().e2eeEncrypt(requestE2eeEncrypt);

    Map<String, dynamic> userData = {
      "name": usernameTesting,
      "encryptedPasswordBlock": responseE2eeEncrypt.encryptedDataBlockList[0],
      "publicKey": preAuthenticationResponse['publicKey'],
      "e2eeSessionId": preAuthenticationResponse['e2eeSessionId'],
      "metaData": responseE2eeEncrypt.metadata
    };

    dynamic loginUserWithPasswordResponse =
        await apiClient.loginWithPassword(userData);
    if (loginUserWithPasswordResponse['message'] != "User authenticated!") {
      print(loginUserWithPasswordResponse['message']);
    }
  }

  test('generateRandomBytes(+)', () {
    expect(E2eeSdk().generateRandomBytes(32), isNotEmpty);
  });

  test('generateRandomBytes(-)', () {
    expect(() async => E2eeSdk().generateRandomBytes(-1),
        throwsA(isA<KKException>()));
  });

  test('generateRandomBytesLoadTest', () {
    for (var i = 0; i < 1000000; i++) {
      final Uint8List randomBytes = E2eeSdk().generateRandomBytes(32);
    }
    print("1000000 records done");
  });

  test('generateRandomString(+)', () {
    expect(E2eeSdk().generateRandomString(32), isNotEmpty);
  });

  test('generateRandomString(-)', () {
    expect(() async => E2eeSdk().generateRandomString(-1),
        throwsA(isA<KKException>()));
  });

  test('generateRandomStringLoadTest', () {
    for (var i = 0; i < 1000000; i++) {
      final String randomString = E2eeSdk().generateRandomString(32);
    }
    print("1000000 records done");
  });

  test('encryptRSA(+)', () {
    const String rsaPublicKeyPem = '''
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
    const String plaintext = "plaintext";
    final Uint8List ciphertext = E2eeSdk().encryptRSA(
        rsaPublicKeyPem,
        Uint8List.fromList(utf8.encode(plaintext)),
        Uint8List.fromList(utf8.encode(oaepLabel)));
    expect(ciphertext, isNotEmpty);
  });

  test('encryptRSA(-)', () {
    const String rsaPublicKeyPem = '''
    -----BEGIN PUBLIC KEY-----
    yAeyWowKSd7We+CoD3SHh/CFj/+JLZ9oecOrjlG5KitpassDkSsNDYvXLP1I6xBU
    SvAAMXmQkJ2V0LpSF0DpIaCXHxCFzDkpJ0mWWjJjeodoCWYGP/pEUMib0aPvS/Qt
    LfN/khDJQym1dT9ESJ9nqNBH05FCou+ygOYkMfmPGX7XAgMBAAE=
    -----END PUBLIC KEY-----
    ''';

    const String oaepLabel = "FzDkpJ0mWWjJjeodoCWYGP/pEUMib0aPvS/Qt";
    const String plaintext = "plaintext";
    expect(
        () async => E2eeSdk().encryptRSA(
            rsaPublicKeyPem,
            Uint8List.fromList(utf8.encode(plaintext)),
            Uint8List.fromList(utf8.encode(oaepLabel))),
        throwsA(isA<KKException>()));
  });

  test('encryptRSALoadTest', () {
    const String rsaPublicKeyPem = '''
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
    for (var i = 0; i < 1000000; i++) {
      final String plaintext = "plaintext$i";
      final Uint8List ciphertext = E2eeSdk().encryptRSA(
          rsaPublicKeyPem,
          Uint8List.fromList(utf8.encode(plaintext)),
          Uint8List.fromList(utf8.encode(oaepLabel)));
    }
    print("1000000 records done");
  });

  test('getRSAPublicKeyPemFromCertificate(+)', () {
    const String certificatePem = '''
      -----BEGIN CERTIFICATE-----
      MIIEKzCCAxOgAwIBAgIBADANBgkqhkiG9w0BAQ0FADCBpDELMAkGA1UEBhMCSUQx
      FzAVBgNVBAgMDktlcHVsYXVhbiBSaWF1MQ4wDAYDVQQHDAVCYXRhbTEcMBoGA1UE
      CgwTUHJvZHVjdCBEZXZlbG9wbWVudDEMMAoGA1UECwwDUm5EMR0wGwYDVQQDDBR3
      d3cua2xhdmlza3JpcHRhLmNvbTEhMB8GCSqGSIb3DQEJARYSc3VwcG9ydEBrbGF2
      aXMuY29tMB4XDTIzMTAxODA5NDEwMFoXDTI0MTAxNzA5NDEwMFowgaQxCzAJBgNV
      BAYTAklEMRcwFQYDVQQIDA5LZXB1bGF1YW4gUmlhdTEOMAwGA1UEBwwFQmF0YW0x
      HDAaBgNVBAoME1Byb2R1Y3QgRGV2ZWxvcG1lbnQxDDAKBgNVBAsMA1JuRDEdMBsG
      A1UEAwwUd3d3LmtsYXZpc2tyaXB0YS5jb20xITAfBgkqhkiG9w0BCQEWEnN1cHBv
      cnRAa2xhdmlzLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMTY
      AivIM33QhcinV2CsWNiAdt3Guww3YLOMQs5bz1pd7KJIy6LWGr3+U0ji2x1SNgVH
      Ns56EPaK2IKk4okgwlyDmIS+Xchy0OuSop9w6p7LC/nPPUjrhb8cX1ME1WHNsghY
      gaf83OEpzLxcSjE7JP8B+XZ0/gJ7bUNx2sBHGQJVuT3zQCOVusO6nJGLaf8WgdRs
      HtljEjuYHPG9IjQtNjSoL4gQIpihYls25dCdeqGqCWF73zVZMjd489gwB97V/w5L
      8GIxlWUxzEjIkPGv6sUntzZQv7kwxJPsm0XsSJdNNOQd8Lcwb1ckjWbgLcGywUwJ
      TG265p4KA7nlgdct4HsCAwEAAaNmMGQwEgYDVR0TAQH/BAgwBgEB/wIBATAOBgNV
      HQ8BAf8EBAMCAQYwHQYDVR0OBBYEFGyo9MdssVzvgQmRb2EEaiPMnmD+MB8GA1Ud
      IwQYMBaAFGyo9MdssVzvgQmRb2EEaiPMnmD+MA0GCSqGSIb3DQEBDQUAA4IBAQA0
      F6iF4BlKclWGYJFFEIPQqwUyLskYTenn3nMu41lCanmHB+VAbJq9mIeoNZ1cnjxl
      EmKbbR/UMvREmWtJcOFzMH7OPF8E6a3WY1iemlIHNbEtjct0z4PsUeXsmaHRNb7o
      MgQPIaFgFdDijoYfJOcNb2U/Chn6RF6aHvJJfUPgjY1TBLqhj+YmnzOctC+38KeT
      Mbd4KXBHCcwDIECOUOXx9N24iCL7QuqjkTW1dnraC5KvkwyA944idckZABHWM853
      c4G2cPAoJxrMCb06xSTHk1BipPwy4bQM6Tpo7Ykj4d+Ws6I2LJffDCuvaLKcL+AP
      k2R6mPb3d1BHpMTe8eX/
      -----END CERTIFICATE-----
      ''';
    final publicKeyPem =
        E2eeSdk().getRSAPublicKeyPemFromCertificate(certificatePem);
  });

  test('getRSAPublicKeyPemFromCertificate(-)', () {
    const String certificatePem = '''
      -----BEGIN CERTIFICATE-----
      MIIEKzCCAxOgAwIBAgIBADANBgkqhkiG9w0BAQ0FADCBpDELMAkGA1UEBhMCSUQx
      FzAVBgNVBAgMDktlcHVsYXVhbiBSaWF1MQ4wDAYDVQQHDAVCYXRhbTEcMBoGA1UE
      CgwTUHJvZHVjdCBEZXZlbG9wbWVudDEMMAoGA1UECwwDUm5EMR0wGwYDVQQDDBR3
      d3cua2xhdmlza3JpcHRhLmNvbTEhMB8GCSqGSIb3DQEJARYSc3VwcG9ydEBrbGF2
      aXMuY29tMB4XDTIzMTAxODA5NDEwMFoXDTI0MTAxNzA5NDEwMFowgaQxCzAJBgNV
      EmKbbR/UMvREmWtJcOFzMH7OPF8E6a3WY1iemlIHNbEtjct0z4PsUeXsmaHRNb7o
      MgQPIaFgFdDijoYfJOcNb2U/Chn6RF6aHvJJfUPgjY1TBLqhj+YmnzOctC+38KeT
      Mbd4KXBHCcwDIECOUOXx9N24iCL7QuqjkTW1dnraC5KvkwyA944idckZABHWM853
      c4G2cPAoJxrMCb06xSTHk1BipPwy4bQM6Tpo7Ykj4d+Ws6I2LJffDCuvaLKcL+AP
      k2R6mPb3d1BHpMTe8eX/
      -----END CERTIFICATE-----
      ''';
    expect(
        () async => E2eeSdk().getRSAPublicKeyPemFromCertificate(certificatePem),
        throwsA(isA<KKException>()));
  });

  test('getRSAPublicKeyPemFromCertificateLoadTest', () {
    const String certificatePem = '''
      -----BEGIN CERTIFICATE-----
      MIIEKzCCAxOgAwIBAgIBADANBgkqhkiG9w0BAQ0FADCBpDELMAkGA1UEBhMCSUQx
      FzAVBgNVBAgMDktlcHVsYXVhbiBSaWF1MQ4wDAYDVQQHDAVCYXRhbTEcMBoGA1UE
      CgwTUHJvZHVjdCBEZXZlbG9wbWVudDEMMAoGA1UECwwDUm5EMR0wGwYDVQQDDBR3
      d3cua2xhdmlza3JpcHRhLmNvbTEhMB8GCSqGSIb3DQEJARYSc3VwcG9ydEBrbGF2
      aXMuY29tMB4XDTIzMTAxODA5NDEwMFoXDTI0MTAxNzA5NDEwMFowgaQxCzAJBgNV
      BAYTAklEMRcwFQYDVQQIDA5LZXB1bGF1YW4gUmlhdTEOMAwGA1UEBwwFQmF0YW0x
      HDAaBgNVBAoME1Byb2R1Y3QgRGV2ZWxvcG1lbnQxDDAKBgNVBAsMA1JuRDEdMBsG
      A1UEAwwUd3d3LmtsYXZpc2tyaXB0YS5jb20xITAfBgkqhkiG9w0BCQEWEnN1cHBv
      cnRAa2xhdmlzLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMTY
      AivIM33QhcinV2CsWNiAdt3Guww3YLOMQs5bz1pd7KJIy6LWGr3+U0ji2x1SNgVH
      Ns56EPaK2IKk4okgwlyDmIS+Xchy0OuSop9w6p7LC/nPPUjrhb8cX1ME1WHNsghY
      gaf83OEpzLxcSjE7JP8B+XZ0/gJ7bUNx2sBHGQJVuT3zQCOVusO6nJGLaf8WgdRs
      HtljEjuYHPG9IjQtNjSoL4gQIpihYls25dCdeqGqCWF73zVZMjd489gwB97V/w5L
      8GIxlWUxzEjIkPGv6sUntzZQv7kwxJPsm0XsSJdNNOQd8Lcwb1ckjWbgLcGywUwJ
      TG265p4KA7nlgdct4HsCAwEAAaNmMGQwEgYDVR0TAQH/BAgwBgEB/wIBATAOBgNV
      HQ8BAf8EBAMCAQYwHQYDVR0OBBYEFGyo9MdssVzvgQmRb2EEaiPMnmD+MB8GA1Ud
      IwQYMBaAFGyo9MdssVzvgQmRb2EEaiPMnmD+MA0GCSqGSIb3DQEBDQUAA4IBAQA0
      F6iF4BlKclWGYJFFEIPQqwUyLskYTenn3nMu41lCanmHB+VAbJq9mIeoNZ1cnjxl
      EmKbbR/UMvREmWtJcOFzMH7OPF8E6a3WY1iemlIHNbEtjct0z4PsUeXsmaHRNb7o
      MgQPIaFgFdDijoYfJOcNb2U/Chn6RF6aHvJJfUPgjY1TBLqhj+YmnzOctC+38KeT
      Mbd4KXBHCcwDIECOUOXx9N24iCL7QuqjkTW1dnraC5KvkwyA944idckZABHWM853
      c4G2cPAoJxrMCb06xSTHk1BipPwy4bQM6Tpo7Ykj4d+Ws6I2LJffDCuvaLKcL+AP
      k2R6mPb3d1BHpMTe8eX/
      -----END CERTIFICATE-----
      ''';
    for (var i = 0; i < 1000000; i++) {
      final publicKeyPem =
          E2eeSdk().getRSAPublicKeyPemFromCertificate(certificatePem);
    }
    print("1000000 records done");
  });

  test('verifyCertificateSignature(+)', () {
    const String certificateChain = '''
      -----BEGIN CERTIFICATE-----
      MIIFWjCCA0KgAwIBAgIBADANBgkqhkiG9w0BAQ0FADCBozELMAkGA1UEBhMCSUQx
      EDAOBgNVBAgMB0pha2FydGExFTATBgNVBAoMDEtsYXZpc0tyaXB0YTEcMBoGA1UE
      CwwTUHJvZHVjdCBEZXZlbG9wbWVudDEkMCIGA1UEAwwbZGVwbG95bWVudC5rbGF2
      aXNrcmlwdGEuY29tMScwJQYJKoZIhvcNAQkBFhhzdXBwb3J0QGtsYXZpc2tyaXB0
      YS5jb20wHhcNMjMxMTA3MDgwODA0WhcNMjQxMTA2MDgwODA0WjB5MQswCQYDVQQG
      EwJJRDEUMBIGA1UECAwLREtJIEpha2FydGExGDAWBgNVBAcMD0pha2FydGEgU2Vs
      YXRhbjETMBEGA1UECgwKUFQuIEhpYmFuazEQMA4GA1UECwwHU3VwcG9ydDETMBEG
      A1UEAwwKaGliYW5rLmNvbTCCAaIwDQYJKoZIhvcNAQEBBQADggGPADCCAYoCggGB
      AMcBKz0Ww0IJCZqrzAff8b+kI6wwzcA2+5kfNYdxaBJ3JOCZPDYBc7+WiS5YrgNV
      TdVWaPe932FjFAqsWUjWAohROv6hn46a4q7XC7C2e4Q1UijkTnry7Kn2gxPL+MvV
      bLbx/j1gq2DCpem3VH5bYD9Ci9p452b3y9wU+LYER8FGVSI/Di48o54t+PsBg4+Q
      laQQ1z9K+S6iLXgwYMYP1rS17neu9YWjXyVsFzy+RPJQWXAsxFPlRn6JGSwo3HTq
      ddOSDzTB/DlKytQ2ERAjP2Z9BxJtaUks3JiBfAFOSD/oNzH8ScDdruASzJ46iLKT
      Y/ZWk07HTxFp4KMuxvv1xVnx7mgncNuaNzbZ4vm5S3wdCYnkWb4qpPMPkQt8DZm8
      c0Uxc2pG223HoBSwkwYfCAMGtHF+Hz0r7HzKiYT+THhiaBbhnuGQdoppUfcIVSs3
      T7B4Z9M+3qam/NMXbqlVnYRb2Lr0cr4vHjx0LOzaRRV40xR/8p0qIT07U2ANF4nE
      7QIDAQABo0IwQDAdBgNVHQ4EFgQUacTK7XOXStDmCIzaI7SsRP5cOmAwHwYDVR0j
      BBgwFoAU84i9pmBUr1IPJv0Ew0+k6b0umJUwDQYJKoZIhvcNAQENBQADggIBALms
      wAQFdjIpalu0xVLKrknlAj8PKPdT3BRuAH/tTjGwQza1lfvjGFjs5kA14+lkDq0I
      0STxr/vq3Pg1Ro6GgiESBKUhKXAJhyJvv3oRT6DEjIWnbBgJxfaay5hHgB0Ju81F
      5ghkWy1eVKVUAQ0ZPLd/tz4J82EI6lNuMcTTkWwngmjTHI9si89aBZfFwyUjTTbP
      D+1YvM6JUIgHB1uaBuPxZApzHSKwpIjDi2qEcnoFM7XLiqm5iU9rfv+Rih7MKU3x
      AwX1q5yLvDnE0viVW+hzeLIrdyKGAM/H9DCuWYD+7DeSHYj4J7PFwbz4uxZKMYWa
      2KDyZIQA9mS0iHWWago9Z5VOGcgfICM+U+v7oC+mLYvtFcqF/aT7qsXcBuyNi/rt
      6PkbeXMohmCzWMeEYmVcMHRUDQDB6UkYaq0Fln1ZNcKpXzp3EN+A8HcusXi9GhJT
      KepyV8ym2Oxj7IVgtqmNl3CvE+kbiTauaciY7B9n56EmI9chM9wc4IetFT3B7n9K
      g+6HtECKe1Cvf1lwZsdrs+DQDXiMHKAZFkv/GvKIe8IJIb4IgEQsGzLl2PMpSrbf
      CxrBsE/d0B5T0V42pcCoJFCdZoiZYIvtf5CbpQcSwuJQmPiLWSBBoBKLW0RZjMXe
      U+1YxIcVhIyMNFiNAXxl0t3iSmd+/SsSSPFwkTsG
      -----END CERTIFICATE-----
      -----BEGIN CERTIFICATE-----
      MIIGKzCCBBOgAwIBAgIBADANBgkqhkiG9w0BAQ0FADCBozELMAkGA1UEBhMCSUQx
      EDAOBgNVBAgMB0pha2FydGExFTATBgNVBAoMDEtsYXZpc0tyaXB0YTEcMBoGA1UE
      CwwTUHJvZHVjdCBEZXZlbG9wbWVudDEkMCIGA1UEAwwbZGVwbG95bWVudC5rbGF2
      aXNrcmlwdGEuY29tMScwJQYJKoZIhvcNAQkBFhhzdXBwb3J0QGtsYXZpc2tyaXB0
      YS5jb20wIBcNMjMxMTA3MDgwMTM5WhgPMjEyMjEwMTQwODAxMzlaMIGjMQswCQYD
      VQQGEwJJRDEQMA4GA1UECAwHSmFrYXJ0YTEVMBMGA1UECgwMS2xhdmlzS3JpcHRh
      MRwwGgYDVQQLDBNQcm9kdWN0IERldmVsb3BtZW50MSQwIgYDVQQDDBtkZXBsb3lt
      ZW50LmtsYXZpc2tyaXB0YS5jb20xJzAlBgkqhkiG9w0BCQEWGHN1cHBvcnRAa2xh
      dmlza3JpcHRhLmNvbTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAN2k
      UpAr5i8j7i1WfKhIIY6yzOOhIegyHFdbh+IVZ8qm007JUaz3iN8YPPdyEV3hQI6r
      /7AiC29xHSPJXq2xNV2861bD8MeatWq6K55+SpFb+QrU9r7W7qJKLB0Vm6KMvRjb
      6jr90zJRcdFo/PBd8vt7RgaLs7BLHuP7uP7Gp0AFju0bByYQsCLZ7COHrO+87Lcn
      TzRbc/NXumQFeg++HTtSLhbGUMna7+U6z2KM6JQIcpQah9wPa3rky/FS/kX82UOb
      ClsQ5aVByjlSxjtwK1VFMLa3z9lW5+n9wKJbYt7/I0wFn3ykdR/VLwlkaUxejUwo
      SGUrrI3WHXF/iWF+y+1SR9xS1SWa5fkszu6X0TVBqxWREwaA1v4NLbNkHQ0AmwAp
      O5Ox5KrswwSDX02xXVfiB2KI4804S4h2coLDWe3f8Mqc2+4tPMgarZsjesyvyKhx
      Y1gnlqCTA4BGkldG9sYi9be5X26VC1Vle5C9FUml4wXCXwOCcL0AsxdWchOt16eV
      ZfqAfKFiucIjp7K7t4dpf8FgUVY2vX+cxUq7V8cVOluvUVrmtfoaICuq92Rj2DOV
      VnWx9AcWmxyj8JmJyXc88wUapKgEaCBHi7/jQGm9yF2gJ431Qio2T3DkPQWDkuxc
      a0l1HzKdx1OgkFb3w8RrHwDLd5uuCFtSdcEOqIYZAgMBAAGjZjBkMBIGA1UdEwEB
      /wQIMAYBAf8CAQEwDgYDVR0PAQH/BAQDAgEGMB0GA1UdDgQWBBTziL2mYFSvUg8m
      /QTDT6TpvS6YlTAfBgNVHSMEGDAWgBTziL2mYFSvUg8m/QTDT6TpvS6YlTANBgkq
      hkiG9w0BAQ0FAAOCAgEAS6s/jiqyD0WWxtH9nj3FLnXmqa6MrX5ofq2+HnVqofZU
      ogm3dYHN3/DyfRrzCeiz8LRijc3wvl8kdXi+yGOfAi7kJOc8SVqCnZ8C+rn8A24J
      ez7N9oI+Bro87hIElvrGBy+u7A4qA1qIRxp/cQ3GSUzLbblE68FmklWEdwrOuayd
      SFFNu2NV0Dh1rvPvCJZ4dA3tnFDX1jH4fN+AxDXaiaHcJLSgzWqM5UoDtvyimAgM
      3JqHeptEDilUdr8gE2kMFNw8yJ/xkA1f0sNCKUnhPQ+V3e5ckSgYU/1qsfINLy6t
      3PVtB1JoUNybqy+jXbTu6mmwYjqCJLYAlUK9oQ4Nq1Dam9sY/7r1YrNwcHmF34kE
      2/4v2MzkheRnXDnj/JukxIHyLi6cflHfKUM/jpFQ8MaAg4Yk+59USIym8NGOd8VD
      TF93q7J5QVvM+wuN10TA5I5kOPMCay1AtRqPShR6WO3r6ZkXfoara6N3lQFFuUj9
      pTvWX3hD4ruhxWaf/nKrreAQgrFHYLwYZAfi1fWaHodxCeIQBAgcNjKe38XJQEJY
      JoGc99pyEtVnlougHyfyAniY0gx0xSqJmHVR3+PzJHxEM7iYLaseCyqmOS2yd0IE
      jjTxuAcrj/vKBO0lE6fF1h2vuC+Kd15v5M/kWs/H3sK6OIwCOCZrHUeY0M6lkDI=
      -----END CERTIFICATE-----
      ''';
    final isVerified = E2eeSdk().verifyCertificateSignature(certificateChain);
    expect(isVerified, true);
  });

  test('verifyCertificateSignatureLoadTest(-)', () {
    const String certificateChain = '''
      -----BEGIN CERTIFICATE-----
      MIIFWjCCA0KgAwIBAgIBADANBgkqhkiG9w0BAQ0FADCBozELMAkGA1UEBhMCSUQx
      EDAOBgNVBAgMB0pha2FydGExFTATBgNVBAoMDEtsYXZpc0tyaXB0YTEcMBoGA1UE
      CwwTUHJvZHVjdCBEZXZlbG9wbWVudDEkMCIGA1UEAwwbZGVwbG95bWVudC5rbGF2
      aXNrcmlwdGEuY29tMScwJQYJKoZIhvcNAQkBFhhzdXBwb3J0QGtsYXZpc2tyaXB0
      YS5jb20wHhcNMjMxMTA3MDgwODA0WhcNMjQxMTA2MDgwODA0WjB5MQswCQYDVQQG
      EwJJRDEUMBIGA1UECAwLREtJIEpha2FydGExGDAWBgNVBAcMD0pha2FydGEgU2Vs
      YXRhbjETMBEGA1UECgwKUFQuIEhpYmFuazEQMA4GA1UECwwHU3VwcG9ydDETMBEG
      A1UEAwwKaGliYW5rLmNvbTCCAaIwDQYJKoZIhvcNAQEBBQADggGPADCCAYoCggGB
      AMcBKz0Ww0IJCZqrzAff8b+kI6wwzcA2+5kfNYdxaBJ3JOCZPDYBc7+WiS5YrgNV
      TdVWaPe932FjFAqsWUjWAohROv6hn46a4q7XC7C2e4Q1UijkTnry7Kn2gxPL+MvV
      bLbx/j1gq2DCpem3VH5bYD9Ci9p452b3y9wU+LYER8FGVSI/Di48o54t+PsBg4+Q
      laQQ1z9K+S6iLXgwYMYP1rS17neu9YWjXyVsFzy+RPJQWXAsxFPlRn6JGSwo3HTq
      ddOSDzTB/DlKytQ2ERAjP2Z9BxJtaUks3JiBfAFOSD/oNzH8ScDdruASzJ46iLKT
      Y/ZWk07HTxFp4KMuxvv1xVnx7mgncNuaNzbZ4vm5S3wdCYnkWb4qpPMPkQt8DZm8
      c0Uxc2pG223HoBSwkwYfCAMGtHF+Hz0r7HzKiYT+THhiaBbhnuGQdoppUfcIVSs3
      T7B4Z9M+3qam/NMXbqlVnYRb2Lr0cr4vHjx0LOzaRRV40xR/8p0qIT07U2ANF4nE
      7QIDAQABo0IwQDAdBgNVHQ4EFgQUacTK7XOXStDmCIzaI7SsRP5cOmAwHwYDVR0j
      BBgwFoAU84i9pmBUr1IPJv0Ew0+k6b0umJUwDQYJKoZIhvcNAQENBQADggIBALms
      wAQFdjIpalu0xVLKrknlAj8PKPdT3BRuAH/tTjGwQza1lfvjGFjs5kA14+lkDq0I
      0STxr/vq3Pg1Ro6GgiESBKUhKXAJhyJvv3oRT6DEjIWnbBgJxfaay5hHgB0Ju81F
      5ghkWy1eVKVUAQ0ZPLd/tz4J82EI6lNuMcTTkWwngmjTHI9si89aBZfFwyUjTTbP
      D+1YvM6JUIgHB1uaBuPxZApzHSKwpIjDi2qEcnoFM7XLiqm5iU9rfv+Rih7MKU3x
      AwX1q5yLvDnE0viVW+hzeLIrdyKGAM/H9DCuWYD+7DeSHYj4J7PFwbz4uxZKMYWa
      2KDyZIQA9mS0iHWWago9Z5VOGcgfICM+U+v7oC+mLYvtFcqF/aT7qsXcBuyNi/rt
      6PkbeXMohmCzWMeEYmVcMHRUDQDB6UkYaq0Fln1ZNcKpXzp3EN+A8HcusXi9GhJT
      KepyV8ym2Oxj7IVgtqmNl3CvE+kbiTauaciY7B9n56EmI9chM9wc4IetFT3B7n9K
      g+6HtECKe1Cvf1lwZsdrs+DQDXiMHKAZFkv/GvKIe8IJIb4IgEQsGzLl2PMpSrbf
      CxrBsE/d0B5T0V42pcCoJFCdZoiZYIvtf5CbpQcSwuJQmPiLWSBBoBKLW0RZjMXe
      U+1YxIcVhIyMNFiNAXxl0t3iSmd+/SsSSPFwkTsG
      -----END CERTIFICATE-----
      -----BEGIN CERTIFICATE-----
      MIIGKzCCBBOgAwIBAgIBADANBgkqhkiG9w0BAQ0FADCBozELMAkGA1UEBhMCSUQx
      EDAOBgNVBAgMB0pha2FydGExFTATBgNVBAoMDEtsYXZpc0tyaXB0YTEcMBoGA1UE
      CwwTUHJvZHVjdCBEZXZlbG9wbWVudDEkMCIGA1UEAwwbZGVwbG95bWVudC5rbGF2
      aXNrcmlwdGEuY29tMScwJQYJKoZIhvcNAQkBFhhzdXBwb3J0QGtsYXZpc2tyaXB0
      YS5jb20wIBcNMjMxMTA3MDgwMTM5WhgPMjEyMjEwMTQwODAxMzlaMIGjMQswCQYD
      VQQGEwJJRDEQMA4GA1UECAwHSmFrYXJ0YTEVMBMGA1UECgwMS2xhdmlzS3JpcHRh
      MRwwGgYDVQQLDBNQcm9kdWN0IERldmVsb3BtZW50MSQwIgYDVQQDDBtkZXBsb3lt
      ZW50LmtsYXZpc2tyaXB0YS5jb20xJzAlBgkqhkiG9w0BCQEWGHN1cHBvcnRAa2xh
      dmlza3JpcHRhLmNvbTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAN2k
      UpAr5i8j7i1WfKhIIY6yzOOhIegyHFdbh+IVZ8qm007JUaz3iN8YPPdyEV3hQI6r
      /7AiC29xHSPJXq2xNV2861bD8MeatWq6K55+SpFb+QrU9r7W7qJKLB0Vm6KMvRjb
      hkiG9w0BAQ0FAAOCAgEAS6s/jiqyD0WWxtH9nj3FLnXmqa6MrX5ofq2+HnVqofZU
      TF93q7J5QVvM+wuN10TA5I5kOPMCay1AtRqPShR6WO3r6ZkXfoara6N3lQFFuUj9
      pTvWX3hD4ruhxWaf/nKrreAQgrFHYLwYZAfi1fWaHodxCeIQBAgcNjKe38XJQEJY
      JoGc99pyEtVnlougHyfyAniY0gx0xSqJmHVR3+PzJHxEM7iYLaseCyqmOS2yd0IE
      jjTxuAcrj/vKBO0lE6fF1h2vuC+Kd15v5M/kWs/H3sK6OIwCOCZrHUeY0M6lkDI=
      -----END CERTIFICATE-----
      ''';
    expect(() async => E2eeSdk().verifyCertificateSignature(certificateChain),
        throwsA(isA<KKException>()));
  });

  test('verifyCertificateSignatureLoadTest', () {
    const String certificateChain = '''
      -----BEGIN CERTIFICATE-----
      MIIFWjCCA0KgAwIBAgIBADANBgkqhkiG9w0BAQ0FADCBozELMAkGA1UEBhMCSUQx
      EDAOBgNVBAgMB0pha2FydGExFTATBgNVBAoMDEtsYXZpc0tyaXB0YTEcMBoGA1UE
      CwwTUHJvZHVjdCBEZXZlbG9wbWVudDEkMCIGA1UEAwwbZGVwbG95bWVudC5rbGF2
      aXNrcmlwdGEuY29tMScwJQYJKoZIhvcNAQkBFhhzdXBwb3J0QGtsYXZpc2tyaXB0
      YS5jb20wHhcNMjMxMTA3MDgwODA0WhcNMjQxMTA2MDgwODA0WjB5MQswCQYDVQQG
      EwJJRDEUMBIGA1UECAwLREtJIEpha2FydGExGDAWBgNVBAcMD0pha2FydGEgU2Vs
      YXRhbjETMBEGA1UECgwKUFQuIEhpYmFuazEQMA4GA1UECwwHU3VwcG9ydDETMBEG
      A1UEAwwKaGliYW5rLmNvbTCCAaIwDQYJKoZIhvcNAQEBBQADggGPADCCAYoCggGB
      AMcBKz0Ww0IJCZqrzAff8b+kI6wwzcA2+5kfNYdxaBJ3JOCZPDYBc7+WiS5YrgNV
      TdVWaPe932FjFAqsWUjWAohROv6hn46a4q7XC7C2e4Q1UijkTnry7Kn2gxPL+MvV
      bLbx/j1gq2DCpem3VH5bYD9Ci9p452b3y9wU+LYER8FGVSI/Di48o54t+PsBg4+Q
      laQQ1z9K+S6iLXgwYMYP1rS17neu9YWjXyVsFzy+RPJQWXAsxFPlRn6JGSwo3HTq
      ddOSDzTB/DlKytQ2ERAjP2Z9BxJtaUks3JiBfAFOSD/oNzH8ScDdruASzJ46iLKT
      Y/ZWk07HTxFp4KMuxvv1xVnx7mgncNuaNzbZ4vm5S3wdCYnkWb4qpPMPkQt8DZm8
      c0Uxc2pG223HoBSwkwYfCAMGtHF+Hz0r7HzKiYT+THhiaBbhnuGQdoppUfcIVSs3
      T7B4Z9M+3qam/NMXbqlVnYRb2Lr0cr4vHjx0LOzaRRV40xR/8p0qIT07U2ANF4nE
      7QIDAQABo0IwQDAdBgNVHQ4EFgQUacTK7XOXStDmCIzaI7SsRP5cOmAwHwYDVR0j
      BBgwFoAU84i9pmBUr1IPJv0Ew0+k6b0umJUwDQYJKoZIhvcNAQENBQADggIBALms
      wAQFdjIpalu0xVLKrknlAj8PKPdT3BRuAH/tTjGwQza1lfvjGFjs5kA14+lkDq0I
      0STxr/vq3Pg1Ro6GgiESBKUhKXAJhyJvv3oRT6DEjIWnbBgJxfaay5hHgB0Ju81F
      5ghkWy1eVKVUAQ0ZPLd/tz4J82EI6lNuMcTTkWwngmjTHI9si89aBZfFwyUjTTbP
      D+1YvM6JUIgHB1uaBuPxZApzHSKwpIjDi2qEcnoFM7XLiqm5iU9rfv+Rih7MKU3x
      AwX1q5yLvDnE0viVW+hzeLIrdyKGAM/H9DCuWYD+7DeSHYj4J7PFwbz4uxZKMYWa
      2KDyZIQA9mS0iHWWago9Z5VOGcgfICM+U+v7oC+mLYvtFcqF/aT7qsXcBuyNi/rt
      6PkbeXMohmCzWMeEYmVcMHRUDQDB6UkYaq0Fln1ZNcKpXzp3EN+A8HcusXi9GhJT
      KepyV8ym2Oxj7IVgtqmNl3CvE+kbiTauaciY7B9n56EmI9chM9wc4IetFT3B7n9K
      g+6HtECKe1Cvf1lwZsdrs+DQDXiMHKAZFkv/GvKIe8IJIb4IgEQsGzLl2PMpSrbf
      CxrBsE/d0B5T0V42pcCoJFCdZoiZYIvtf5CbpQcSwuJQmPiLWSBBoBKLW0RZjMXe
      U+1YxIcVhIyMNFiNAXxl0t3iSmd+/SsSSPFwkTsG
      -----END CERTIFICATE-----
      -----BEGIN CERTIFICATE-----
      MIIGKzCCBBOgAwIBAgIBADANBgkqhkiG9w0BAQ0FADCBozELMAkGA1UEBhMCSUQx
      EDAOBgNVBAgMB0pha2FydGExFTATBgNVBAoMDEtsYXZpc0tyaXB0YTEcMBoGA1UE
      CwwTUHJvZHVjdCBEZXZlbG9wbWVudDEkMCIGA1UEAwwbZGVwbG95bWVudC5rbGF2
      aXNrcmlwdGEuY29tMScwJQYJKoZIhvcNAQkBFhhzdXBwb3J0QGtsYXZpc2tyaXB0
      YS5jb20wIBcNMjMxMTA3MDgwMTM5WhgPMjEyMjEwMTQwODAxMzlaMIGjMQswCQYD
      VQQGEwJJRDEQMA4GA1UECAwHSmFrYXJ0YTEVMBMGA1UECgwMS2xhdmlzS3JpcHRh
      MRwwGgYDVQQLDBNQcm9kdWN0IERldmVsb3BtZW50MSQwIgYDVQQDDBtkZXBsb3lt
      ZW50LmtsYXZpc2tyaXB0YS5jb20xJzAlBgkqhkiG9w0BCQEWGHN1cHBvcnRAa2xh
      dmlza3JpcHRhLmNvbTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAN2k
      UpAr5i8j7i1WfKhIIY6yzOOhIegyHFdbh+IVZ8qm007JUaz3iN8YPPdyEV3hQI6r
      /7AiC29xHSPJXq2xNV2861bD8MeatWq6K55+SpFb+QrU9r7W7qJKLB0Vm6KMvRjb
      6jr90zJRcdFo/PBd8vt7RgaLs7BLHuP7uP7Gp0AFju0bByYQsCLZ7COHrO+87Lcn
      TzRbc/NXumQFeg++HTtSLhbGUMna7+U6z2KM6JQIcpQah9wPa3rky/FS/kX82UOb
      ClsQ5aVByjlSxjtwK1VFMLa3z9lW5+n9wKJbYt7/I0wFn3ykdR/VLwlkaUxejUwo
      SGUrrI3WHXF/iWF+y+1SR9xS1SWa5fkszu6X0TVBqxWREwaA1v4NLbNkHQ0AmwAp
      O5Ox5KrswwSDX02xXVfiB2KI4804S4h2coLDWe3f8Mqc2+4tPMgarZsjesyvyKhx
      Y1gnlqCTA4BGkldG9sYi9be5X26VC1Vle5C9FUml4wXCXwOCcL0AsxdWchOt16eV
      ZfqAfKFiucIjp7K7t4dpf8FgUVY2vX+cxUq7V8cVOluvUVrmtfoaICuq92Rj2DOV
      VnWx9AcWmxyj8JmJyXc88wUapKgEaCBHi7/jQGm9yF2gJ431Qio2T3DkPQWDkuxc
      a0l1HzKdx1OgkFb3w8RrHwDLd5uuCFtSdcEOqIYZAgMBAAGjZjBkMBIGA1UdEwEB
      /wQIMAYBAf8CAQEwDgYDVR0PAQH/BAQDAgEGMB0GA1UdDgQWBBTziL2mYFSvUg8m
      /QTDT6TpvS6YlTAfBgNVHSMEGDAWgBTziL2mYFSvUg8m/QTDT6TpvS6YlTANBgkq
      hkiG9w0BAQ0FAAOCAgEAS6s/jiqyD0WWxtH9nj3FLnXmqa6MrX5ofq2+HnVqofZU
      ogm3dYHN3/DyfRrzCeiz8LRijc3wvl8kdXi+yGOfAi7kJOc8SVqCnZ8C+rn8A24J
      ez7N9oI+Bro87hIElvrGBy+u7A4qA1qIRxp/cQ3GSUzLbblE68FmklWEdwrOuayd
      SFFNu2NV0Dh1rvPvCJZ4dA3tnFDX1jH4fN+AxDXaiaHcJLSgzWqM5UoDtvyimAgM
      3JqHeptEDilUdr8gE2kMFNw8yJ/xkA1f0sNCKUnhPQ+V3e5ckSgYU/1qsfINLy6t
      3PVtB1JoUNybqy+jXbTu6mmwYjqCJLYAlUK9oQ4Nq1Dam9sY/7r1YrNwcHmF34kE
      2/4v2MzkheRnXDnj/JukxIHyLi6cflHfKUM/jpFQ8MaAg4Yk+59USIym8NGOd8VD
      TF93q7J5QVvM+wuN10TA5I5kOPMCay1AtRqPShR6WO3r6ZkXfoara6N3lQFFuUj9
      pTvWX3hD4ruhxWaf/nKrreAQgrFHYLwYZAfi1fWaHodxCeIQBAgcNjKe38XJQEJY
      JoGc99pyEtVnlougHyfyAniY0gx0xSqJmHVR3+PzJHxEM7iYLaseCyqmOS2yd0IE
      jjTxuAcrj/vKBO0lE6fF1h2vuC+Kd15v5M/kWs/H3sK6OIwCOCZrHUeY0M6lkDI=
      -----END CERTIFICATE-----
      ''';
    for (var i = 0; i < 1000000; i++) {
      final isVerified = E2eeSdk().verifyCertificateSignature(certificateChain);
    }
    print("1000000 records done");
  });

  test('verifyRSASignature(+)', () {
    const String message = "cx_onaxr`pmnsx`k";
    const String signature =
        "kQ6SbzUGxFigFjJLkYSPmp6/45wZxIVO2kY5ADrhhKCfaeb7NuXT6X6dSUJm+JKUfwq01Ek3S0eT6C+z0efSQZJ5QYzu1uOmjZjBM8LPUL41qTLeR2oYqAMTDVWJqvKLUdb3y109S9WjNqGNvcxcZKztd2Kd9yRGdjW7EwVbMuO89WI2U83aPnBBbUPQvrm0QIdQl4Wc7+0aiMhEuIWSIKaPDM2XWTOCjFdbS2crZ3luSMtiYHY65sMq8f7QzDg9hZWbETM/4w1jV3KQv+GBlJVTzH78R8myGbyWLWh92WR5Kn67DdLXtwG9xgDbYj1uoUphUYqFSC2uEqg7nKwO0Q==";

    const String rsaPublicKeyPem = '''
    -----BEGIN PUBLIC KEY-----
    MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5BHIxsFxYRdnIZNSam0i
    SavpDxtnEpiwFbEuJXh8NpLI2XGv2XlexpqNw4d1RKh1IyEgXSCLyp1T7gXWxWAb
    1xymyB1WtgIK3bmeDUa+GfuFj2kyUMfTZq6FZPixdRiaeJ+SNCNmOFStBI1EL9dW
    kY+amNPGLzkNVqwsnYKUQ+7ktIhup8qKaZd6Bq9g2Ik6AUBQZW57SvF4YNVHpBSa
    EhZ9GB0K/NfxIBCpC+8NMvjQvD8MhJXFQmmoalonCufBE//WEI6P12ZFff3wClaA
    7T0nUWoYyY3PfiRuDnI//LzQyW90rm12lNN60cr1cRXK7RqBXtChzK4PZL1DleOD
    FwIDAQAB
    -----END PUBLIC KEY-----
    ''';

    final bool isVerified = E2eeSdk().verifyRSASignature(rsaPublicKeyPem,
        Uint8List.fromList(utf8.encode(message)), base64Decode(signature));
    expect(isVerified, true);
  });

  test('verifyRSASignature(-)', () {
    const String message = "cx_onaxr`pmnsx`k";
    const String signature =
        "kQ6SbzUGxFigFjJLkYSPmp6/45wZxIVO2kY5ADrhhKCfaeb7NuXT6X6dSUJm+JKUfwq01Ek3S0eT6C+z0efSQZJ5QYzu1uOmjZjBM8LPUL41qTLeR2oYqAMTDVWJqvKLUdb3y109S9WjNqGNvcxcZKztd2Kd9yRGdjW7EwVbMuO89WI2U83aPnBBbUPQvrm0QIdQl4Wc7+0aiMhEuIWSIKaPDM2XWTOCjFdbS2crZ3luSMtiYHY65sMq8f7QzDg9hZWbETM/4w1jV3KQv+GBlJVTzH78R8myGbyWLWh92WR5Kn67DdLXtwG9xgDbYj1uoUphUYqFSC2uEqg7nKwO0Q==";

    const String rsaPublicKeyPem = '''
    -----BEGIN PUBLIC KEY-----
    MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5BHIxsFxYRdnIZNSam0i
    SavpDxtnEpiwFbEuJXh8NpLI2XGv2XlexpqNw4d1RKh1IyEgXSCLyp1T7gXWxWAb
    7T0nUWoYyY3PfiRuDnI//LzQyW90rm12lNN60cr1cRXK7RqBXtChzK4PZL1DleOD
    FwIDAQAB
    -----END PUBLIC KEY-----
    ''';

    expect(
        () async => E2eeSdk().verifyRSASignature(rsaPublicKeyPem,
            Uint8List.fromList(utf8.encode(message)), base64Decode(signature)),
        throwsA(isA<KKException>()));
  });

  test('verifyRSASignatureLoadTest', () {
    const String message = "cx_onaxr`pmnsx`k";
    const String signature =
        "kQ6SbzUGxFigFjJLkYSPmp6/45wZxIVO2kY5ADrhhKCfaeb7NuXT6X6dSUJm+JKUfwq01Ek3S0eT6C+z0efSQZJ5QYzu1uOmjZjBM8LPUL41qTLeR2oYqAMTDVWJqvKLUdb3y109S9WjNqGNvcxcZKztd2Kd9yRGdjW7EwVbMuO89WI2U83aPnBBbUPQvrm0QIdQl4Wc7+0aiMhEuIWSIKaPDM2XWTOCjFdbS2crZ3luSMtiYHY65sMq8f7QzDg9hZWbETM/4w1jV3KQv+GBlJVTzH78R8myGbyWLWh92WR5Kn67DdLXtwG9xgDbYj1uoUphUYqFSC2uEqg7nKwO0Q==";

    const String rsaPublicKeyPem = '''
    -----BEGIN PUBLIC KEY-----
    MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5BHIxsFxYRdnIZNSam0i
    SavpDxtnEpiwFbEuJXh8NpLI2XGv2XlexpqNw4d1RKh1IyEgXSCLyp1T7gXWxWAb
    1xymyB1WtgIK3bmeDUa+GfuFj2kyUMfTZq6FZPixdRiaeJ+SNCNmOFStBI1EL9dW
    kY+amNPGLzkNVqwsnYKUQ+7ktIhup8qKaZd6Bq9g2Ik6AUBQZW57SvF4YNVHpBSa
    EhZ9GB0K/NfxIBCpC+8NMvjQvD8MhJXFQmmoalonCufBE//WEI6P12ZFff3wClaA
    7T0nUWoYyY3PfiRuDnI//LzQyW90rm12lNN60cr1cRXK7RqBXtChzK4PZL1DleOD
    FwIDAQAB
    -----END PUBLIC KEY-----
    ''';

    for (var i = 0; i < 1000000; i++) {
      final bool isVerified = E2eeSdk().verifyRSASignature(rsaPublicKeyPem,
          Uint8List.fromList(utf8.encode(message)), base64Decode(signature));
    }
    print("1000000 records done");
  });

  test('e2eeEncrypt(+)', () async {
    const String rsaPublicKeyPem = '''
    -----BEGIN PUBLIC KEY-----
    MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEA2rc0rKVeaUPSUZR4JWOi
    2jIoEBPUulcZAbFZDPJqtP29SPEDJA4efJi9+7o04PC4o+vyqKMHTyr3vooKJot6
    iCoUBQsWHcklb4M/i9Xaxk430/N0fgGz4q2skIvaLQ5xpC12QBjuQ+3rP2yTe5SH
    pCHnAulcGTSO27OSbgjBQ6TmNRh2X+2jBJ3JAaIEyiZ41ArrBnfYA20Cnh50Tra3
    tjlRJQskNN9pUE+u8grItQYde2xich5Dd2EtIe2GF/YNkvj2sKv4Kmtc6OQ5ImdK
    qkKQGM/JvmODcTzLXUvvgIGhFUmX1ub2+recKbZLR/jQeVAo+ZZ5SaIfuQrKya5E
    l6qPLPcmMhvhG5Uz31t6WRgeR65eQuuCdVC8tJrZT7DJ7cHr8wtHxrmMt7UxmBCQ
    +mou9Qol1iVear7/ruJIPjG/6vHPElJ1STvwK+/rOFdSIhfog6baHberCMez/HaJ
    qIoqfGQmXO+GwxhUzOkR7swOKlq9MZTOgAHNhlCFfDrlAgMBAAE=
    -----END PUBLIC KEY-----
    ''';
    const String oaepLabel =
        "CqzG1+llVis5Jppks7gStPPxN73mWh1zwNrFKXkEqs6eLNJq5JrkdneJ2anNFUBC";

    const String plainData = "PasswordHibankTest";

    final RequestE2eeEncrypt requestE2eeEncrypt = RequestE2eeEncrypt(
        rsaPublicKeyPem, oaepLabel, [Uint8List.fromList(plainData.codeUnits)]);
    final ResponseE2eeEncrypt responseE2eeEncrypt =
        await E2eeSdk().e2eeEncrypt(requestE2eeEncrypt);
    print("Metadata: ${responseE2eeEncrypt.metadata}");
    print("Encrypted password: ${responseE2eeEncrypt.encryptedDataBlockList}");
    expect(responseE2eeEncrypt.metadata, isNotEmpty);
    expect(responseE2eeEncrypt.encryptedDataBlockList, isNotEmpty);
  });

  test('e2eeEncrypt(-)', () async {
    const String rsaPublicKeyPem = '''
    -----BEGIN PUBLIC KEY-----
    MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEA2rc0rKVeaUPSUZR4JWOi
    2jIoEBPUulcZAbFZDPJqtP29SPEDJA4efJi9+7o04PC4o+vyqKMHTyr3vooKJot6
    +mou9Qol1iVear7/ruJIPjG/6vHPElJ1STvwK+/rOFdSIhfog6baHberCMez/HaJ
    qIoqfGQmXO+GwxhUzOkR7swOKlq9MZTOgAHNhlCFfDrlAgMBAAE=
    -----END PUBLIC KEY-----
    ''';
    const String oaepLabel =
        "CqzG1+llVis5Jppks7gStPPxN73mWh1zwNrFKXkEqs6eLNJq5JrkdneJ2anNFUBC";

    const String plainData = "Password";

    final RequestE2eeEncrypt requestE2eeEncrypt = RequestE2eeEncrypt(
      rsaPublicKeyPem,
      oaepLabel,
      [Uint8List.fromList(utf8.encode(plainData))],
    );

    try {
      final responseE2eeEncrypt =
          await E2eeSdk().e2eeEncrypt(requestE2eeEncrypt);
    } catch (ex) {
      print("Error code: ${ex.toString()}");
      // rethrow;
    }
    // expect(() async => await E2eeSdk().e2eeEncrypt(requestE2eeEncrypt),
    //     throwsA(isA<KKException>()));
  });

  test('e2eeEncryptLoadTest', () async {
    const String rsaPublicKeyPem = '''
    -----BEGIN PUBLIC KEY-----
    MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEA2rc0rKVeaUPSUZR4JWOi
    2jIoEBPUulcZAbFZDPJqtP29SPEDJA4efJi9+7o04PC4o+vyqKMHTyr3vooKJot6
    iCoUBQsWHcklb4M/i9Xaxk430/N0fgGz4q2skIvaLQ5xpC12QBjuQ+3rP2yTe5SH
    pCHnAulcGTSO27OSbgjBQ6TmNRh2X+2jBJ3JAaIEyiZ41ArrBnfYA20Cnh50Tra3
    tjlRJQskNN9pUE+u8grItQYde2xich5Dd2EtIe2GF/YNkvj2sKv4Kmtc6OQ5ImdK
    qkKQGM/JvmODcTzLXUvvgIGhFUmX1ub2+recKbZLR/jQeVAo+ZZ5SaIfuQrKya5E
    l6qPLPcmMhvhG5Uz31t6WRgeR65eQuuCdVC8tJrZT7DJ7cHr8wtHxrmMt7UxmBCQ
    +mou9Qol1iVear7/ruJIPjG/6vHPElJ1STvwK+/rOFdSIhfog6baHberCMez/HaJ
    qIoqfGQmXO+GwxhUzOkR7swOKlq9MZTOgAHNhlCFfDrlAgMBAAE=
    -----END PUBLIC KEY-----
    ''';
    const String oaepLabel =
        "CqzG1+llVis5Jppks7gStPPxN73mWh1zwNrFKXkEqs6eLNJq5JrkdneJ2anNFUBC";

    final int timeBefore = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < 1000; i++) {
      final String plainData = "Password$i";

      final RequestE2eeEncrypt requestE2eeEncrypt = RequestE2eeEncrypt(
        rsaPublicKeyPem,
        oaepLabel,
        [Uint8List.fromList(utf8.encode(plainData))],
      );
      final ResponseE2eeEncrypt responseE2eeEncrypt =
          await E2eeSdk().e2eeEncrypt(requestE2eeEncrypt);
    }
    final int timeAfter = DateTime.now().millisecondsSinceEpoch;
    final int duration = timeAfter - timeBefore;
    print("E2EE encrypt duration with flutter: $duration");

    print("1000000 records done");
  });

  test('calculateDigest(+)', () async {
    const String plainData = "PasswordHibankTest";

    final Uint8List digestUint8List = E2eeSdk()
        .calculateDigest(Uint8List.fromList(plainData.codeUnits), "SHA-512");
    expect(digestUint8List, isNotEmpty);
  });

  test('calculateDigest(-)', () async {
    const String plainData = "PasswordHibankTest";
    expect(
        () async => E2eeSdk().calculateDigest(
            Uint8List.fromList(utf8.encode(plainData)), "SHA512"),
        throwsA(isA<KKException>()));
  });

  test('reset and verify', () async {
    for (var i = 0; i < 1000000; i++) {
      await resetPassword(i);
      await verifyPassword(i);
      print("Test $i");
    }
  });
}
