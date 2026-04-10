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

class ErrorEntry {
  final DateTime timestamp;
  final String type;
  final String message;
  final String? stack;
  final String? service;
  final Map<String, dynamic>? meta;

  ErrorEntry({
    required this.timestamp,
    required this.type,
    required this.message,
    this.stack,
    this.service,
    this.meta,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'type': type,
    'message': message,
    if (stack != null) 'stack': stack,
    if (service != null) 'service': service,
    if (meta != null) 'meta': meta,
  };
}

class JobEntry {
  final String jobName;
  final String? queue;
  final int durationMs;
  final int waitTimeMs;
  final String status; // 'succeeded', 'failed', 'error'
  final String? error;
  final DateTime? timestamp;

  JobEntry({
    required this.jobName,
    this.queue,
    required this.durationMs,
    required this.waitTimeMs,
    required this.status,
    this.error,
    this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'job_name': jobName,
    if (queue != null) 'queue': queue,
    'duration_ms': durationMs,
    'wait_time_ms': waitTimeMs,
    'status': status,
    if (error != null) 'error': error,
    if (timestamp != null) 'ts': timestamp!.toIso8601String(),
  };
}

class AppMetricEntry {
  final String name;
  final double value;
  final Map<String, String>? tags;
  final DateTime? timestamp;
  final String? env;

  AppMetricEntry({
    required this.name,
    required this.value,
    this.tags,
    this.timestamp,
    this.env,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'value': value,
    if (tags != null) 'tags': tags,
    if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    if (env != null) 'env': env,
  };
}
