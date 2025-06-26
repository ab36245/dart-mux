import 'dart:async';
import 'dart:typed_data';

import 'package:dart_websocket/dart_websocket.dart';

import 'channel.dart';
import 'util.dart';

class MuxClient {
  MuxClient(this._ws) {
    _init();
  }

  MuxChannel addChannel(int id) {
    if (id <= 0) {
      throw 'invalid channel id $id';
    }
    final pkt = BytesBuilder();
    pkt.addByte(0); // control channel id
    pkt.addByte(0); // add channel id command
    pkt.add(writeNumber(id));
    final bytes = pkt.takeBytes();
    _ws.writeBinary(bytes);

    final reader = StreamController<Uint8List>();
    _readers[id] = reader;
    return MuxChannel(id, reader.stream, _output.sink);
  }
  
  final _readers = <int, StreamController<Uint8List>>{};

  final _output = StreamController<Uint8List>();

  final WebSocket _ws;

  void _init() async {
    _read();
    _write();
  }

  void _read() async {
    print('Client: reading input');
    await for (final bytes in _ws.stream) {
      print('Client: input ${bytes.length} bytes');
      int id;
      Uint8List rest;
      try {
        (id, rest) = readNumber(bytes);
      } catch (e) {
        print('Client: invalid channel id: $e');
        break;
      }
      print('Client: channel id $id');
      print('Client: bytes remaining ${rest.length}');
      if (id == 0) {
        print('Client: control channel');
      } else if (_readers.containsKey(id)) {
        print('Client: reader channel');
        _readers[id]!.sink.add(rest);
      } else {
        print('Client: invalid channel');
        break;
      }
    }
    print('Client: shuttng down connection');
  }

  void _write() async {
    print('Client: reading output');
    await for (final bytes in _output.stream) {
      print('Client: output ${bytes.length} bytes');
      _ws.writeBinary(bytes);
    }
    print('Client: output stream is closed');
  }
}