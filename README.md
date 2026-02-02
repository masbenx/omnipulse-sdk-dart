# OmniPulse Dart SDK

The official OmniPulse SDK for pure Dart applications. Provides logging functionality for backend Dart services.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  omnipulse_dart: ^1.0.0
```

## Quick Start

```dart
import 'package:omnipulse_dart/omnipulse_dart.dart';

void main() async {
  // Initialize OmniPulse
  await OmniPulse.init(OmniPulseConfig(
    apiUrl: 'https://api.omnipulse.cloud',
    ingestKey: 'your-ingest-key',
    serviceName: 'my-dart-service',
    version: '1.0.0',
    environment: 'production',
  ));

  // Test connectivity
  final success = await OmniPulse.instance.test();
  print('OmniPulse test: ${success ? "OK" : "FAILED"}');

  // Use logger
  OmniPulse.instance.logger.info('Service started');
  
  // Clean shutdown
  await OmniPulse.instance.close();
}
```

## Features

### Logging

```dart
final logger = OmniPulse.instance.logger;

logger.debug('Debug message');
logger.info('Request received', {'path': '/api/users', 'method': 'GET'});
logger.warn('Rate limit approaching', {'current': 95, 'max': 100});
logger.error('Failed to connect', {'error': e.toString()});
logger.fatal('Critical system failure');
```

## Configuration

| Option | Description | Default |
|--------|-------------|---------|
| `apiUrl` | OmniPulse API URL | Required |
| `ingestKey` | Your ingest key | Required |
| `serviceName` | Your service name | Required |
| `version` | Service version | null |
| `environment` | Deployment environment | `production` |
| `debug` | Enable debug logging | `false` |
| `batchSize` | Buffer size before sending | `50` |
| `flushIntervalSeconds` | Flush interval | `10` |

## Best Practices

1. **Initialize early** - Call `OmniPulse.init()` at startup
2. **Close gracefully** - Call `close()` before exit to flush remaining logs
3. **Add context** - Include relevant data in log tags

## License

MIT
