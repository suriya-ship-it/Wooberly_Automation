import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:app_name/utils/globals.dart' as globals;

class SocketConnection{
  void onsendMessage(String eventName , List<String> jsonMessage){
    globals.socket?.emit(eventName, jsonMessage);
  }

  void disconnectListen(String eventName){
    globals.socket?.off(eventName);
  }

}