import 'dart:typed_data';
import 'package:flutter/services.dart';

import 'package:e2ee_sdk_flutter/core/error_code.dart';
import 'package:e2ee_sdk_flutter/core/exceptions.dart';

Uint8List intToUint8List(int number) {
  try {
    // Create a ByteData object
    ByteData byteData = ByteData(4); // Assuming a 32-bit integer (4 bytes)

    // Set the integer value in the ByteData object
    byteData.setInt32(0, number, Endian.little);

    // Convert the ByteData to a Uint8List
    return byteData.buffer.asUint8List();
  } on PlatformException catch (e) {
    throw KKException(
        "Error: Int to Uint8List conversion failed.\r\nStack trace: ${e.stacktrace}",
        ErrorCode.INT_TO_UINT8LIST_CONVERSION_FAILED,
        e.details,
        e.stacktrace);
  } catch (e, s) {
    throw KKException("Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
        ErrorCode.ERROR_IN_FUNCTION_INT_TO_UINT8LIST_CONVERSION, null, null);
  }
}

int uint8ListToInt(Uint8List uint8List) {
  try {
    // Create a ByteData object
    ByteData byteData = ByteData.sublistView(uint8List);

    // Convert the ByteData to a Int32
    return byteData.getInt32(0, Endian.little);
  } on PlatformException catch (e) {
    throw KKException(
        "Error: Uint8List to Int conversion failed.\r\nStack trace: ${e.stacktrace}",
        ErrorCode.UINT8LIST_TO_INT_CONVERSION_FAILED,
        e.details,
        e.stacktrace);
  } catch (e, s) {
    throw KKException("Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
        ErrorCode.ERROR_IN_FUNCTION_UINT8LIST_TO_INT, null, null);
  }
}

Uint8List serializeListOfUint8Lists(List<Uint8List> list) {
  // Use the `expand` function to concatenate Uint8Lists
  try {
    return Uint8List.fromList(list.expand((uint8List) => uint8List).toList());
  } on PlatformException catch (e) {
    throw KKException(
        "Error: List of Uint8List serialization failed.\r\nStack trace: ${e.stacktrace}",
        ErrorCode.SERIALIZE_LIST_OF_UINT8LIST_FAILED,
        e.details,
        e.stacktrace);
  } catch (e, s) {
    throw KKException("Error: ${e.toString()}.\r\nStack trace: ${s.toString()}",
        ErrorCode.ERROR_IN_FUNCTION_SERIALIZE_LIST_OF_UINT8LIST, null, null);
  }
}
