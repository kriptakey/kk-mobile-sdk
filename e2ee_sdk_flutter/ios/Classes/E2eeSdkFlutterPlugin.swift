import Flutter
import UIKit

public class E2eeSdkFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "e2ee_sdk_flutter", binaryMessenger: registrar.messenger())
    let instance = E2eeSdkFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "generateECP256Keypair":
      if let arguments = call.arguments as? Dictionary<String, Any> {
        let keyAlias = arguments["keyAlias"] as? String
        let requireAuth = arguments["requireAuth"] as? Bool
        let allowOverwrite = arguments["allowOverwrite"] as? Bool
        if #available(iOS 13.0, *) {
          try? Crypto().generateECP256Keypair(
                          keyAlias: keyAlias!,
                          requireAuth: requireAuth!,
                          allowOverwrite: allowOverwrite!)
        }
      }
      result(nil)
    case "generateApplicationCSR":
      if let arguments = call.arguments as? Dictionary<String, Any> {
        let keyAlias = arguments["keyAlias"] as? String
        let commonName = arguments["commonName"] as? String
        let country = arguments["country"] as? String
        let location = arguments["location"] as? String
        let state = arguments["state"] as? String
        let organizationName = arguments["organizationName"] as? String
        let organizationUnit = arguments["organizationUnit"] as? String
        let applicationCsr = try? Crypto().generateApplicationCSR(
                      keyAlias: keyAlias!,
                      commonName: commonName!,
                      country: country!,
                      location: location!,
                      state: state!,
                      organizationName: organizationName!,
                      organizationUnit: organizationUnit!)
        result(applicationCsr!)
      } else {
        result(nil)
      }
    case "generateAES256Key":
      if let arguments = call.arguments as? Dictionary<String, Any> {
        let keyAlias = arguments["keyAlias"] as? String
        let requireAuth = arguments["requireAuth"] as? Bool
        let allowOverwrite = arguments["allowOverwrite"] as? Bool
        if #available(iOS 13.0, *) {
          try? Crypto().generateAES256Key(
                        keyAlias: keyAlias!,
                        requireAuth: requireAuth!,
                        allowOverwrite: allowOverwrite!)
        }
      }
      result(nil)
    case "encryptAES256GCM":
      if let arguments = call.arguments as? Dictionary<String, Any> {
        let keyAlias = arguments["keyAlias"] as? String
        let plainData = arguments["plainData"] as? FlutterStandardTypedData
        let iv = arguments["iv"] as? FlutterStandardTypedData

        let aadFlutterDataType = arguments["aad"] as? FlutterStandardTypedData
        var aad: Data?

        if (aadFlutterDataType != nil) {
          aad = aadFlutterDataType!.data
        } else {
          aad = nil
        }
        
        if #available(iOS 13.0, *) {
          let ciphertext = try? Crypto().encryptAES256GCM(
            keyAlias: keyAlias!,
            plainData: plainData!.data,
            iv: iv!.data,
            aad: aad)
          result(ciphertext!)
        }
      } else {
        result(nil)
      }
    case "signData":
      if let arguments = call.arguments as? Dictionary<String, Any> {
        let keyAlias = arguments["keyAlias"] as? String
        let plainData = arguments["plainData"] as? FlutterStandardTypedData
        let signature = try? Crypto().signData(
          keyAlias: keyAlias!,
          plainData: plainData!.data)
        result(signature!)
      } else {
        result(nil)
      }
    case "importAES256GCMKey":
      if let arguments = call.arguments as? Dictionary<String, Any> {
        let importedKeyAlias = arguments["importedKeyAlias"] as? String
        let wrappedKey = arguments["wrappedKey"] as? FlutterStandardTypedData
        let allowOverwrite = arguments["allowOverwrite"] as? Bool
        if #available(iOS 13.0, *) {
          try? Crypto().importAES256GCMKey(
            keyAlias: importedKeyAlias!,
            wrappedKey: wrappedKey!.data,
            allowOverwrite: allowOverwrite!)
        }
      }
      result(nil)
    case "isSecureEnvironmentAvailable":
      if #available(iOS 13.0, *) {
        let isSecureEnvironmentAvailable = try? SecureEnclaveInspector().hasSecureEnclave()
        result(isSecureEnvironmentAvailable)
      } else {
        result(false)
      }
    case "deleteAES256GCMkey":
      if let arguments = call.arguments as? Dictionary<String, Any> {
        let keyAlias = arguments["keyAlias"] as? String
        if #available(iOS 13.0, *) {
          try? Crypto().deleteAES256GCMkey(
            keyAlias: keyAlias!)
        }
      }
      result(nil)
    case "deleteKeyPair":
      if let arguments = call.arguments as? Dictionary<String, Any> {
        let keyAlias = arguments["keyAlias"] as? String
        if #available(iOS 13.0, *) {
          try? Crypto().deleteKeyPair(
            keyAlias: keyAlias!)
        }
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
