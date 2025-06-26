import 'dart:async';
import 'dart:typed_data';

import 'util.dart';

class MuxChannel {
  MuxChannel(this.id, this.reader, this.writer);

  final int id;

  final Stream<Uint8List> reader;

  final Sink<Uint8List> writer;

  void write(Uint8List bytes) {
    final pkt = BytesBuilder();
    pkt.add(writeNumber(id));
    pkt.add(bytes);
    writer.add(pkt.takeBytes());
  }
}

