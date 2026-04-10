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
  final List<RequestEntry> _requestBuffer = [];
  final List<ErrorEntry> _errorBuffer = [];
  final List<JobEntry> _jobBuffer = [];
  final List<AppMetricEntry> _metricBuffer = [];
  
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

  /// Add a request entry to the buffer
  void logRequest(RequestEntry entry) {
    _requestBuffer.add(entry);
    if (_requestBuffer.length >= config.batchSize) flush();
  }

  void captureError(ErrorEntry entry) {
    _errorBuffer.add(entry);
    if (_errorBuffer.length >= config.batchSize) flush();
  }

  void captureJob(JobEntry entry) {
    _jobBuffer.add(entry);
    if (_jobBuffer.length >= config.batchSize) flush();
  }

  void captureMetric(AppMetricEntry entry) {
    _metricBuffer.add(entry);
    if (_metricBuffer.length >= config.batchSize) flush();
  }

  /// Flush all buffered data immediately
  Future<void> flush() async {
    final logs = List<LogEntry>.from(_logBuffer);
    final requests = List<RequestEntry>.from(_requestBuffer);
    final errors = List<ErrorEntry>.from(_errorBuffer);
    final jobs = List<JobEntry>.from(_jobBuffer);
    final metrics = List<AppMetricEntry>.from(_metricBuffer);

    _logBuffer.clear();
    _requestBuffer.clear();
    _errorBuffer.clear();
    _jobBuffer.clear();
    _metricBuffer.clear();

    if (logs.isNotEmpty) await _sendLogs(logs);
    if (errors.isNotEmpty) await _sendErrors(errors);
    if (jobs.isNotEmpty) await _sendJobs(jobs);
    if (metrics.isNotEmpty) await _sendMetrics(metrics);
    
    if (requests.isNotEmpty) {
      for (final req in requests) {
        await _sendRequest(req);
      }
    }
  }

  Future<void> _sendLogs(List<LogEntry> logs) async {
    try {
      final payload = {
        'entries': logs.map((l) => l.toJson()).toList(),
      };
      await _send('/api/ingest/app-logs', payload);
    } catch (e) {
      if (config.debug) print('[OmniPulse] Failed to send logs: $e');
    }
  }

  Future<void> _sendErrors(List<ErrorEntry> errors) async {
    try {
      for (final error in errors) {
        await _send('/api/ingest/app-errors', error.toJson());
      }
    } catch (e) {
      if (config.debug) print('[OmniPulse] Failed to send errors: $e');
    }
  }

  Future<void> _sendJobs(List<JobEntry> jobs) async {
    try {
      for (final job in jobs) {
        await _send('/api/ingest/app-job', job.toJson());
      }
    } catch (e) {
      if (config.debug) print('[OmniPulse] Failed to send jobs: $e');
    }
  }

  Future<void> _sendMetrics(List<AppMetricEntry> metrics) async {
    try {
      final payload = {
        'service_name': config.serviceName,
        'environment': config.environment,
        'metrics': metrics.map((m) => m.toJson()).toList(),
      };
      await _send('/api/ingest/app-metrics', payload);
    } catch (e) {
      if (config.debug) print('[OmniPulse] Failed to send metrics: $e');
    }
  }

  Future<void> _sendRequest(RequestEntry req) async {
    try {
      await _send('/api/ingest/app-request', req.toJson());
    } catch (e) {
      if (config.debug) {
        print('[OmniPulse] Failed to send request: $e');
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
