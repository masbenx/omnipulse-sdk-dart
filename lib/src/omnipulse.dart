import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'types.dart';
import 'logger.dart';

/// Main OmniPulse client for Dart applications
class OmniPulse {
  static OmniPulse? _instance;
  
  final OmniPulseConfig config;
  final http.Client _httpClient;
  final Uuid _uuid = const Uuid();
  
  late final OmniPulseLogger logger;
  
  final List<LogEntry> _logBuffer = [];
  
  Timer? _flushTimer;
  bool _isInitialized = false;

  OmniPulse._internal(this.config, this._httpClient) {
    logger = OmniPulseLogger(this);
  }

  /// Initialize the OmniPulse SDK
  static Future<OmniPulse> init(OmniPulseConfig config) async {
    if (_instance != null) {
      return _instance!;
    }
    
    _instance = OmniPulse._internal(config, http.Client());
    await _instance!._initialize();
    return _instance!;
  }

  /// Get the singleton instance (must call init first)
  static OmniPulse get instance {
    if (_instance == null) {
      throw StateError('OmniPulse must be initialized first. Call OmniPulse.init()');
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    // Start flush timer
    _flushTimer = Timer.periodic(
      Duration(seconds: config.flushIntervalSeconds),
      (_) => flush(),
    );
    
    _isInitialized = true;
    
    if (config.debug) {
      print('[OmniPulse] Initialized with API: ${config.apiUrl}');
    }
  }

  /// Generate a unique ID
  String generateId() => _uuid.v4();

  /// Add a log entry to the buffer
  void addLog(LogEntry entry) {
    _logBuffer.add(entry);
    if (_logBuffer.length >= config.batchSize) {
      flush();
    }
  }

  /// Flush all buffered data immediately
  Future<void> flush() async {
    final logs = List<LogEntry>.from(_logBuffer);
    _logBuffer.clear();

    if (logs.isNotEmpty) {
      await _sendLogs(logs);
    }
  }

  Future<void> _sendLogs(List<LogEntry> logs) async {
    try {
      final payload = {
        'logs': logs.map((l) => l.toJson()).toList(),
      };
      await _send('/api/ingest/app-logs', payload);
    } catch (e) {
      if (config.debug) {
        print('[OmniPulse] Failed to send logs: $e');
      }
    }
  }

  Future<void> _send(String endpoint, Map<String, dynamic> payload) async {
    final uri = Uri.parse('${config.apiUrl}$endpoint');
    final body = jsonEncode(payload);
    
    final response = await _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-Ingest-Key': config.ingestKey,
        'User-Agent': 'omnipulse-dart-sdk/1.0.0',
      },
      body: body,
    ).timeout(const Duration(seconds: 5));
    
    if (config.debug) {
      print('[OmniPulse] Sent to $endpoint, status: ${response.statusCode}');
    }
  }

  /// Test connectivity to the OmniPulse backend
  Future<bool> test() async {
    try {
      logger.info('OmniPulse SDK test message', {
        'sdk_version': '1.0.0',
        'platform': Platform.operatingSystem,
        'service_name': config.serviceName,
      });
      await flush();
      return true;
    } catch (e) {
      if (config.debug) {
        print('[OmniPulse] Test failed: $e');
      }
      return false;
    }
  }

  /// Close the SDK and flush remaining data
  Future<void> close() async {
    _flushTimer?.cancel();
    await flush();
    _httpClient.close();
    _instance = null;
  }
}
