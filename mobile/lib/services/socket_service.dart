import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class SocketService {
  static IO.Socket? _socket;
  static bool _isConnected = false;
  static String? _currentUserId;
  static final StreamController<Map<String, dynamic>> _notificationController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // Stream for notifications
  static Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;
  
  // Connection status
  static bool get isConnected => _isConnected;
  
  // Initialize Socket.IO connection
  static Future<void> initialize() async {
    try {
      // Get user ID from storage
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('user_id');
      
      if (_currentUserId == null) {
        print('❌ SocketService: No user ID found, cannot connect');
        return;
      }
      
      // Get server URL
      final serverUrl = ApiConfig.safeBaseUrl.replaceAll('/api', '');
      print('🔌 SocketService: Connecting to $serverUrl');
      
      // Create socket connection
      _socket = IO.io(serverUrl, IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setTimeout(5000)
          .build());
      
      // Connection event handlers
      _socket!.onConnect((_) {
        print('✅ SocketService: Connected to server');
        _isConnected = true;
        
        // Join user's room for notifications
        _socket!.emit('join_user_room', _currentUserId);
        print('🏠 SocketService: Joined user room: user_$_currentUserId');
      });
      
      _socket!.onDisconnect((_) {
        print('❌ SocketService: Disconnected from server');
        _isConnected = false;
      });
      
      _socket!.onConnectError((error) {
        print('❌ SocketService: Connection error: $error');
        _isConnected = false;
      });
      
      // Notification event handler
      _socket!.on('notification', (data) {
        print('🔔 SocketService: Received notification: $data');
        _notificationController.add(Map<String, dynamic>.from(data));
      });
      
      // Error handler
      _socket!.onError((error) {
        print('❌ SocketService: Socket error: $error');
      });
      
    } catch (e) {
      print('❌ SocketService: Initialization error: $e');
    }
  }
  
  // Connect to server
  static Future<void> connect() async {
    if (_socket != null && !_isConnected) {
      _socket!.connect();
    }
  }
  
  // Disconnect from server
  static Future<void> disconnect() async {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
    }
  }
  
  // Update user ID and reconnect
  static Future<void> updateUserId(String userId) async {
    _currentUserId = userId;
    
    // Save to storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    
    // Reconnect with new user ID
    await disconnect();
    await initialize();
  }
  
  // Send a custom event
  static void emit(String event, dynamic data) {
    if (_socket != null && _isConnected) {
      _socket!.emit(event, data);
    } else {
      print('❌ SocketService: Cannot emit - not connected');
    }
  }
  
  // Listen to a custom event
  static void on(String event, Function(dynamic) handler) {
    if (_socket != null) {
      _socket!.on(event, handler);
    }
  }
  
  // Remove event listener
  static void off(String event, [Function(dynamic)? handler]) {
    if (_socket != null) {
      _socket!.off(event, handler);
    }
  }
  
  // Cleanup
  static void dispose() {
    _notificationController.close();
    disconnect();
  }
}
