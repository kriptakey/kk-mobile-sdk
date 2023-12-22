import 'dart:typed_data';
import 'dart:convert';

/// The result of single data encryption
class EncryptedData {
  /// An initialization vector
  final Uint8List iv;

  /// An Message Authentication Code (MAC) of the encryption result
  final Uint8List tag;

  /// The ciphertext of encrypted data
  final Uint8List ciphertext;

  EncryptedData(this.iv, this.tag, this.ciphertext);
}

/// An object to store key pair (public key and private key)
class AsymmetricKeyPairObject {
  /// An asymmetric public key in PEM format
  String publicKeyPem;

  /// An asymmetric private key in PEM format
  String privateKeyPem;

  AsymmetricKeyPairObject(this.publicKeyPem, this.privateKeyPem);

  /// Convert a json map to [AsymmetricKeyPairObject]
  AsymmetricKeyPairObject.fromJson(Map<String, dynamic> json)
      : publicKeyPem = json['publicKey'],
        privateKeyPem = json['privateKey'];

  /// Convert [AsymmetricKeyPairObject] to json String
  Map<String, dynamic> toJson() => {
        'publicKey': publicKeyPem,
        'privateKey': privateKeyPem,
      };
}

/// An object to store wrapped key metadata
class KMSWrappedKeyMetadata {
  /// An additional authentication data (aad) to protect integrity
  final Uint8List aad;

  /// The base64 encoded encrypted metadata
  final String encodedEncryptedMetadata;

  /// The base64 encoded wrappedKey by KMS internal key
  final String encodedKMSKeyWrapped;

  KMSWrappedKeyMetadata(
      this.aad, this.encodedEncryptedMetadata, this.encodedKMSKeyWrapped);

  /// Convert a json map to [KMSWrappedKeyMetadata]
  KMSWrappedKeyMetadata.fromJson(Map<String, dynamic> json)
      : aad = json['aad'],
        encodedEncryptedMetadata = json['encodedEncryptedMetadata'],
        encodedKMSKeyWrapped = json['encodedKMSKeyWrapped'];

  /// Convert [KMSWrappedKeyMetadata] to json String
  Map<String, dynamic> toJson() => {
        'aad': aad,
        'encodedEncryptedMetadata': encodedEncryptedMetadata,
        'encodedKMSKeyWrapped': encodedKMSKeyWrapped
      };
}

/// An object to store response wrapped key metadata
class ResponseKMSWrappedKeyMetadata {
  /// An base64 additional authentication data (aad) to protect integrity
  final String aad;

  /// The base64 encoded encrypted metadata
  final String encodedEncryptedMetadata;

  /// The base64 encoded wrappedKey by KMS internal key
  final String encodedKMSKeyWrapped;

  ResponseKMSWrappedKeyMetadata(
      this.aad, this.encodedEncryptedMetadata, this.encodedKMSKeyWrapped);

  /// Convert a json map to [ResponseKMSWrappedKeyMetadata]
  ResponseKMSWrappedKeyMetadata.fromJson(Map<String, dynamic> json)
      : aad = json['aad'],
        encodedEncryptedMetadata = json['encodedEncryptedMetadata'],
        encodedKMSKeyWrapped = json['encodedKMSKeyWrapped'];

  /// Convert [ResponseKMSWrappedKeyMetadata] to json String
  Map<String, dynamic> toJson() => {
        'aad': aad,
        'encodedEncryptedMetadata': encodedEncryptedMetadata,
        'encodedKMSKeyWrapped': encodedKMSKeyWrapped
      };
}

/// An object to store e2ee encryption result
class ResponseE2eeEncrypt {
  /// A wrapped metadata
  String metadata;

  /// A list of encrypted data
  List<String> encryptedDataBlockList;

  ResponseE2eeEncrypt(this.metadata, this.encryptedDataBlockList);

  /// Convert a json map to [ResponseE2eeEncrypt]
  ResponseE2eeEncrypt.fromJson(Map<String, dynamic> json)
      : metadata = json['metadata'],
        encryptedDataBlockList = json['encryptedDataBlockList'];

  /// Convert [ResponseE2eeEncrypt] to json String
  Map<String, dynamic> toJson() => {
        'metadata': metadata,
        'encryptedDataBlockList': encryptedDataBlockList,
      };
}

/// An object to store request parameters for e2eeEncrypt()
class RequestE2eeEncrypt {
  /// An application server public key in PEM format
  final String publicKeyPem;

  /// An optional value for Optimal Asymmetric Encryption Padding (OAEP) label
  final String? oaepLabel;

  /// The list of plain buffers
  final List<Uint8List> messages;

  RequestE2eeEncrypt(this.publicKeyPem, this.oaepLabel, this.messages);
}

/// An object to store e2ee decryption result
class ResponseE2eeDecrypt {
  /// The list of plain buffers
  List<Uint8List> messages;

  ResponseE2eeDecrypt(this.messages);

  /// Convert a json map to [ResponseE2eeDecrypt]
  ResponseE2eeDecrypt.fromJson(Map<String, dynamic> json)
      : messages = json['messages'];

  /// Convert [ResponseE2eeDecrypt] to json String
  Map<String, dynamic> toJson() {
    List<String> plainMessageList = [];
    for (final message in messages) {
      plainMessageList.add(base64Encode(message));
    }
    return {'messages': plainMessageList};
  }
}

/// An object to store single request parameters of e2eeDecrypt()
class RequestSingleE2eeDecrypt {
  /// The base64 encoded ciphertext
  String text;

  /// The base64 encoded Message Authentication Code (MAC)
  String mac;

  /// The base 64 encoded initialization vector (iv)
  String iv;

  RequestSingleE2eeDecrypt(this.text, this.mac, this.iv);

  // Convert a json map to [RequestSingleE2eeDecrypt]
  RequestSingleE2eeDecrypt.fromJson(Map<String, dynamic> json)
      : text = json['text'],
        mac = json['mac'],
        iv = json['iv'];

  /// Convert [RequestSingleE2eeDecrypt] to json map
  Map<String, dynamic> toJson() => {'text': text, 'mac': mac, 'iv': iv};
}

/// An object to store request parameters of e2eeDecrypt()
class RequestE2eeDecrypt {
  /// The list of [RequestSingleE2eeDecrypt]
  List<RequestSingleE2eeDecrypt> ciphertext;

  /// An additional authentication data (aad)
  Uint8List aad;

  RequestE2eeDecrypt(this.ciphertext, this.aad);
}

/// An object to store distinguished name of a certificate
class DistinguishedName {
  /// E.g., "www.example.com"
  final String commonName;

  /// E.g., "ID"
  final String country;

  /// E.g., "South Jakarta"
  final String location;

  /// E.g., "Jakarta"
  final String state;

  /// E.g., "PT. Example"
  final String organizationName;

  /// E.g., "Product Development"
  final String organizationUnit;

  DistinguishedName(this.commonName, this.country, this.location, this.state,
      this.organizationName, this.organizationUnit);
}

/// An object to store generate RSA keypair in secure storage result
class ResponseGenerateRsaKeypairInSecureStorage {
  /// Return public key in PEM format
  String publicKeyPem;

  ResponseGenerateRsaKeypairInSecureStorage(this.publicKeyPem);

  /// Convert a json map to [ResponseGenerateRsaKeypairInSecureStorage]
  ResponseGenerateRsaKeypairInSecureStorage.fromJson(Map<String, dynamic> json)
      : publicKeyPem = json['publicKeyPem'];

  /// Convert [ResponseGenerateRsaKeypairInSecureStorage] to json map
  Map<String, dynamic> toJson() => {'publicKeyPem': publicKeyPem};
}

/// An object to store the result of encryptRSA()
class ResponseEncryptRSA {
  /// Return encrypted data in base64 encode
  String ciphertext;

  ResponseEncryptRSA(this.ciphertext);

  /// Convert a json map to [ResponseEncryptRSA]
  ResponseEncryptRSA.fromJson(Map<String, dynamic> json)
      : ciphertext = json['ciphertext'];

  /// Convert [ResponseEncryptRSA] to json map
  Map<String, dynamic> toJson() => {'ciphertext': ciphertext};
}

/// An object to store the result of generateRandomBytes()
class ResponseGenerateRandomBytes {
  /// Return random bytes
  Uint8List randomBytes;

  ResponseGenerateRandomBytes(this.randomBytes);

  /// Convert a json map to [ResponseGenerateRandomBytes]
  ResponseGenerateRandomBytes.fromJson(Map<String, dynamic> json)
      : randomBytes = json['randomBytes'];

  /// Convert [ResponseGenerateRandomBytes] to json map
  Map<String, dynamic> toJson() => {'randomBytes': randomBytes};
}

/// An object to store the result of generateRandomString()
class ResponseGenerateRandomString {
  /// Return random string
  String randomString;

  ResponseGenerateRandomString(this.randomString);

  /// Convert a json map to [ResponseGenerateRandomString]
  ResponseGenerateRandomString.fromJson(Map<String, dynamic> json)
      : randomString = json['randomString'];

  /// Convert [ResponseGenerateRandomString] to json map
  Map<String, dynamic> toJson() => {'randomString': randomString};
}

/// An object to store the result of getPublicKeyPemFromCertificate()
class ResponseGetPublicKeyPemFromCertificate {
  /// Return public key PEM
  String publicKeyPem;

  ResponseGetPublicKeyPemFromCertificate(this.publicKeyPem);

  /// Convert a json map to [ResponseGetPublicKeyPemFromCertificate]
  ResponseGetPublicKeyPemFromCertificate.fromJson(Map<String, dynamic> json)
      : publicKeyPem = json['publicKeyPem'];

  /// Convert [ResponseGetPublicKeyPemFromCertificate] to json map
  Map<String, dynamic> toJson() => {'publicKeyPem': publicKeyPem};
}

/// An object to store the result of verifyCertificateSignature()
class ResponseVerifyCertificateSignature {
  /// Return boolean of the verification result
  bool isVerified;

  ResponseVerifyCertificateSignature(this.isVerified);

  /// Convert a json map to [ResponseVerifyCertificateSignature]
  ResponseVerifyCertificateSignature.fromJson(Map<String, dynamic> json)
      : isVerified = json['isVerified'];

  /// Convert [ResponseVerifycertificateSignature] to json map
  Map<String, dynamic> toJson() => {'isVerified': isVerified};
}

/// An object to store the result of generateDeviceIdKeypairInSecureStorage()
class ResponseGenerateDeviceIdKeypairInSecureStorage {
  /// Return device CSR
  String deviceCsr;

  ResponseGenerateDeviceIdKeypairInSecureStorage(this.deviceCsr);

  /// Convert a json map to [ResponseGenerateDeviceIdKeypairInSecureStorage]
  ResponseGenerateDeviceIdKeypairInSecureStorage.fromJson(
      Map<String, dynamic> json)
      : deviceCsr = json['deviceCsr'];

  /// Convert [ResponseGenerateDeviceIdKeypairInSecureStorage] to json map
  Map<String, dynamic> toJson() => {'deviceCsr': deviceCsr};
}

/// An object to store the result of signByDeviceIdKeypairInSecureStorage()
class ResponseSignByDeviceIdKeypairInSecureStorage {
  /// Return base64 signature
  String signature;

  ResponseSignByDeviceIdKeypairInSecureStorage(this.signature);

  /// Convert a json map to [ResponseSignByDeviceIdKeypairInSecureStorage]
  ResponseSignByDeviceIdKeypairInSecureStorage.fromJson(
      Map<String, dynamic> json)
      : signature = json['signature'];

  /// Convert [ResponseSignByDeviceIdKeypairInSecureStorage] to json map
  Map<String, dynamic> toJson() => {'signature': signature};
}

/// An object to store the result of calculateDigest()
class ResponseCalculateDigest {
  /// Return base64 message digest
  String digest;

  ResponseCalculateDigest(this.digest);

  /// Convert a json map to [ResponseCalculateDigest]
  ResponseCalculateDigest.fromJson(Map<String, dynamic> json)
      : digest = json['digest'];

  /// Convert [ResponseCalculateDigest] to json map
  Map<String, dynamic> toJson() => {'digest': digest};
}

typedef ResponseVerifyRSASignature = ResponseVerifyCertificateSignature;
typedef ResponseIsDeviceBinding = ResponseVerifyCertificateSignature;
typedef ResponseSignDigestByDeviceIdKeypairInSecureStorage = ResponseSignByDeviceIdKeypairInSecureStorage;