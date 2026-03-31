import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';
import '../storage/user_storage.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;
  bool _initialized = false;

  // Stream controllers for different events
  final _visitorStream = StreamController<dynamic>.broadcast();
  final _sosStream = StreamController<dynamic>.broadcast();
  final _noticeStream = StreamController<dynamic>.broadcast();

  Stream<dynamic> get visitorStream => _visitorStream.stream;
  Stream<dynamic> get sosStream => _sosStream.stream;
  Stream<dynamic> get noticeStream => _noticeStream.stream;

  Future<void> init() async {
    if (_initialized) return;

    final token = await TokenStorage.getToken();
    if (token == null) return;

    final user = await UserStorage.getFullUser();
    final String? societyId = user?["societyId"] != null && user?["societyId"] is Map 
        ? (user?["societyId"] as Map)["_id"]?.toString()
        : user?["societyId"]?.toString();

    if (societyId == null) return;

    // The base URL is normally https://domain.com/api, socket needs https://domain.com
    final String socketUrl = ApiConstants.baseUrl.replaceAll('/api', '');

    socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'Authorization': 'Bearer $token'}
    });

    socket!.onConnect((_) {
      debugPrint('✅ Socket Connected');
      // Join society-specific room
      socket!.emit('join_society', societyId);
      // Join user-specific room for private notifications (Visitor approval etc)
      socket!.emit('join_user', user?["_id"]);
    });

    socket!.onDisconnect((_) => debugPrint('❌ Socket Disconnected'));

    // --- Event Listeners ---
    
    // Visitor Events (Arrived, Approved, Rejected, Entered, Exited)
    socket!.on('VISITOR_UPDATE', (data) {
      debugPrint('🔔 Socket: Visitor Update Received');
      _visitorStream.add(data);
    });

    // Emergency SOS Events
    socket!.on('SOS_ALERT', (data) {
      debugPrint('🚨 Socket: SOS ALERT RECEIVED!');
      _sosStream.add(data);
    });

    // New Notice Events
    socket!.on('NEW_NOTICE', (data) {
      debugPrint('📢 Socket: New Notice Received');
      _noticeStream.add(data);
    });

    // Global Notification (Standard)
    socket!.on('NOTIFICATION', (data) {
       debugPrint('📩 Socket: notification received');
    });

    socket!.connect();
    _initialized = true;
  }

  void disconnect() {
    socket?.disconnect();
    socket?.dispose();
    socket = null;
    _initialized = false;
  }

  void emit(String event, dynamic data) {
    socket?.emit(event, data);
  }
}
