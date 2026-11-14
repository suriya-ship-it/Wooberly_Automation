import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;

import '../app/app.dart';

class SocketConnection {
  socketConnect() {
    App().initSocket();
    globals.socket?.onConnect((data) {
      if (data is Map) {
        data = json.encode(data);
      }
    });
    globals.socket?.onConnectError((data) {
      if (data is Map) {
        data = json.encode(data);
      }
    });
    globals.socket?.onError((data) {
      if (data is Map) {
        data = json.encode(data);
      }
    });

    App().reconnectSocket();
  }


  void onsendMessage(String eventName, List<String> jsonMessage) {
    globals.socket?.emit(eventName, jsonMessage);
  }

  void disconnectListen(String eventName) {
    globals.socket?.off(eventName);
  }
}