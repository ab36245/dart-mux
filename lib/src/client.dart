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

  var _closing = false;

  final _output = StreamController<Uint8List>();
  
  final _readers = <int, StreamController<Uint8List>>{};

  final WebSocket _ws;

  void _init() async {
    _doInput();
    _doOutput();
  }

  void _doInput() async {
    final m = 'Client._doInput';
    print('$m: starting');
    await for (final msg in _ws.stream) {
      print('$m: read message ${msg.runtimeType}');
      if (msg is! Uint8List) {
        print('$m: can\'t handler ${m.runtimeType} msgs');
        break;
      }
      print('$m: read binary message ${msg.length} bytes');
      print('$m: reading channel id');
      int id;
      Uint8List bytes;
      try {
        (id, bytes) = readNumber(msg);
      } catch (e) {
        print('$m: invalid channel id: $e');
        break;
      }
      print('$m: channel id $id');
      print('$m: bytes remaining ${bytes.length}');
      if (id == 0) {
        print('$m: control channel');
        print('$m: ignoring control channel at the moment...');
      } else if (_readers.containsKey(id)) {
        print('$m: reader channel');
        _readers[id]!.sink.add(bytes);
      } else {
        print('$m: invalid channel');
        break;
      }
    }
    print('$m: shutting down connection');
    _closing = true;
    for (final entry in _readers.entries) {
      print('$m: closing channel ${entry.key} reader');
      await entry.value.close();
    }
  }

  void _doOutput() async {
    final m = 'Client._doOutput';
    print('$m: starting');
    await for (final bytes in _output.stream) {
      print('$m: output ${bytes.length} bytes');
      _ws.writeBinary(bytes);
    }
    print('$m: output stream is closed');
  }
}