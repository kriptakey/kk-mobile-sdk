import 'dart:typed_data';

Uint8List intToUint8List(int number) {
  // Create a ByteData object
  ByteData byteData = ByteData(4); // Assuming a 32-bit integer (4 bytes)

  // Set the integer value in the ByteData object
  byteData.setInt32(0, number, Endian.little);

  // Convert the ByteData to a Uint8List
  return byteData.buffer.asUint8List();
}

int uint8ListToInt(Uint8List uint8List) {
  // Create a ByteData object
  ByteData byteData = ByteData.sublistView(uint8List);

  // Convert the ByteData to a Int32
  return byteData.getInt32(0, Endian.little);
}

Uint8List serializeListOfUint8Lists(List<Uint8List> list) {
  // Use the `expand` function to concatenate Uint8Lists
  return Uint8List.fromList(list.expand((uint8List) => uint8List).toList());
}
