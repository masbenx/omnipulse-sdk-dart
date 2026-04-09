/// Log level enumeration
enum LogLevel { debug, info, warn, error, fatal }

/// Configuration for the OmniPulse SDK
class OmniPulseConfig {
  /// The OmniPulse API URL
  final String apiUrl;
  
  /// Your X-Ingest-Key for authentication
  final String ingestKey;
  
  /// Name of your application/service
  final String serviceName;
  
  /// Application version
  final String? version;
  
  /// Environment (production, staging, development)
  final String environment;
  
  /// Enable debug logging
  final bool debug;
  
  /// Batch size before sending
  final int batchSize;
  
  /// Flush interval in seconds
  final int flushIntervalSeconds;

  const OmniPulseConfig({
    required this.apiUrl,
    required this.ingestKey,
    required this.serviceName,
    this.version,
    this.environment = 'production',
    this.debug = false,
    this.batchSize = 50,
    this.flushIntervalSeconds = 10,
  });
}

/// Log entry data
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? serviceName;
  final Map<String, dynamic>? tags;
  final String? traceId;
  final String? spanId;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.serviceName,
    this.tags,
    this.traceId,
    this.spanId,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'level': level.name,
    'message': message,
    if (serviceName != null) 'service': serviceName,
    if (tags != null) 'meta': tags,
    if (traceId != null) 'trace_id': traceId,
    if (spanId != null) 'span_id': spanId,
  };
}

/// Request entry data for APM
class RequestEntry {
  final DateTime timestamp;
  final String method;
  final String route;
  final int status;
  final int durationMs;
  final String? env;
  final String? traceId;

  RequestEntry({
    required this.timestamp,
    required this.method,
    required this.route,
    required this.status,
    required this.durationMs,
    this.env,
    this.traceId,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toUtc().toIso8601String(),
    'method': method,
    'route': route,
    'status': status,
    'duration_ms': durationMs,
    if (env != null) 'env': env,
    if (traceId != null) 'trace_id': traceId,
  };
}
