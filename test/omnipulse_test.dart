import 'package:test/test.dart';
import 'package:omnipulse_dart/src/types.dart';

void main() {
  group('OmniPulseConfig', () {
    test('required fields are set', () {
      const config = OmniPulseConfig(
        apiUrl: 'http://localhost:8080',
        ingestKey: 'test-key',
        serviceName: 'my-service',
      );

      expect(config.apiUrl, equals('http://localhost:8080'));
      expect(config.ingestKey, equals('test-key'));
      expect(config.serviceName, equals('my-service'));
    });

    test('defaults are applied', () {
      const config = OmniPulseConfig(
        apiUrl: 'http://localhost',
        ingestKey: 'key',
        serviceName: 'svc',
      );

      expect(config.environment, equals('production'));
      expect(config.debug, isFalse);
      expect(config.batchSize, equals(50));
      expect(config.flushIntervalSeconds, equals(10));
      expect(config.version, isNull);
    });

    test('custom values override defaults', () {
      const config = OmniPulseConfig(
        apiUrl: 'http://localhost',
        ingestKey: 'key',
        serviceName: 'svc',
        version: '2.0.0',
        environment: 'staging',
        debug: true,
        batchSize: 20,
        flushIntervalSeconds: 5,
      );

      expect(config.environment, equals('staging'));
      expect(config.debug, isTrue);
      expect(config.batchSize, equals(20));
      expect(config.flushIntervalSeconds, equals(5));
      expect(config.version, equals('2.0.0'));
    });
  });

  group('LogLevel', () {
    test('all levels exist', () {
      expect(LogLevel.values.length, equals(5));
      expect(LogLevel.values, containsAll([
        LogLevel.debug,
        LogLevel.info,
        LogLevel.warn,
        LogLevel.error,
        LogLevel.fatal,
      ]));
    });

    test('level names', () {
      expect(LogLevel.debug.name, equals('debug'));
      expect(LogLevel.info.name, equals('info'));
      expect(LogLevel.warn.name, equals('warn'));
      expect(LogLevel.error.name, equals('error'));
      expect(LogLevel.fatal.name, equals('fatal'));
    });
  });

  group('LogEntry', () {
    test('creates with required fields', () {
      final entry = LogEntry(
        timestamp: DateTime(2025, 1, 1),
        level: LogLevel.info,
        message: 'test message',
      );

      expect(entry.message, equals('test message'));
      expect(entry.level, equals(LogLevel.info));
      expect(entry.timestamp.year, equals(2025));
    });

    test('creates with all fields', () {
      final entry = LogEntry(
        timestamp: DateTime(2025, 1, 1),
        level: LogLevel.error,
        message: 'error occurred',
        serviceName: 'my-service',
        tags: {'user_id': 123},
        traceId: 'trace-abc',
        spanId: 'span-def',
      );

      expect(entry.serviceName, equals('my-service'));
      expect(entry.tags?['user_id'], equals(123));
      expect(entry.traceId, equals('trace-abc'));
      expect(entry.spanId, equals('span-def'));
    });

    test('toJson includes required fields', () {
      final entry = LogEntry(
        timestamp: DateTime.utc(2025, 1, 15, 10, 30, 0),
        level: LogLevel.info,
        message: 'test',
      );

      final json = entry.toJson();

      expect(json['level'], equals('info'));
      expect(json['message'], equals('test'));
      expect(json['timestamp'], contains('2025-01-15'));
    });

    test('toJson excludes null fields', () {
      final entry = LogEntry(
        timestamp: DateTime.utc(2025),
        level: LogLevel.debug,
        message: 'test',
      );

      final json = entry.toJson();

      expect(json.containsKey('service_name'), isFalse);
      expect(json.containsKey('tags'), isFalse);
      expect(json.containsKey('trace_id'), isFalse);
      expect(json.containsKey('span_id'), isFalse);
    });

    test('toJson includes optional fields when present', () {
      final entry = LogEntry(
        timestamp: DateTime.utc(2025),
        level: LogLevel.error,
        message: 'err',
        serviceName: 'api',
        tags: {'code': 500},
        traceId: 'tr1',
        spanId: 'sp1',
      );

      final json = entry.toJson();

      expect(json['service_name'], equals('api'));
      expect(json['tags']['code'], equals(500));
      expect(json['trace_id'], equals('tr1'));
      expect(json['span_id'], equals('sp1'));
    });
  });
}
