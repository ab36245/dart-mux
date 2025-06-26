import 'dart:typed_data';

(int, Uint8List) readNumber(Uint8List bytes) {
  var n = 0;
  var s = 0;
  for (var i = 0; i < bytes.length; i++) {
    final b = bytes[i];
    n |= (b & 0x7f) << s;
    s += 7;
    if (b & 0x80 == 0x00) {
      return (n, bytes.sublist(i + 1));
    }
  }
  throw 'incomplete number';
}

Uint8List writeNumber(int n) {
  final list = <int>[];
  for (;;) {
    var b = n & 0x7f;
    n >>= 7;
    if (n > 0) {
      b |= 0x80;
    }
    list.add(b);
    if (n == 0) {
      break;
    }
  }
  return Uint8List.fromList(list);
}