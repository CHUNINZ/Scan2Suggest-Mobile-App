import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Performance monitoring utility for tracking app performance metrics
class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};
  static final Map<String, List<Duration>> _metrics = {};
  static final List<PerformanceEvent> _events = [];
  
  /// Start timing an operation
  static void startTimer(String operation) {
    if (kDebugMode) {
      _timers[operation] = Stopwatch()..start();
      developer.log('⏱️ Started timer: $operation', name: 'Performance');
    }
  }
  
  /// End timing an operation and record the duration
  static Duration? endTimer(String operation) {
    if (kDebugMode) {
      final timer = _timers.remove(operation);
      if (timer != null) {
        timer.stop();
        final duration = timer.elapsed;
        
        // Record the metric
        _metrics.putIfAbsent(operation, () => []).add(duration);
        
        // Log the result
        developer.log('⏱️ Completed: $operation in ${duration.inMilliseconds}ms', name: 'Performance');
        
        // Add to events for analysis
        _events.add(PerformanceEvent(
          operation: operation,
          duration: duration,
          timestamp: DateTime.now(),
        ));
        
        return duration;
      }
    }
    return null;
  }
  
  /// Time an operation and return the result
  static Future<T> timeOperation<T>(String operation, Future<T> Function() fn) async {
    startTimer(operation);
    try {
      final result = await fn();
      endTimer(operation);
      return result;
    } catch (e) {
      endTimer(operation);
      rethrow;
    }
  }
  
  /// Time a synchronous operation and return the result
  static T timeSyncOperation<T>(String operation, T Function() fn) {
    startTimer(operation);
    try {
      final result = fn();
      endTimer(operation);
      return result;
    } catch (e) {
      endTimer(operation);
      rethrow;
    }
  }
  
  /// Get performance metrics for an operation
  static List<Duration> getMetrics(String operation) {
    return _metrics[operation] ?? [];
  }
  
  /// Get average duration for an operation
  static Duration? getAverageDuration(String operation) {
    final metrics = getMetrics(operation);
    if (metrics.isEmpty) return null;
    
    final totalMs = metrics.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
    return Duration(milliseconds: totalMs ~/ metrics.length);
  }
  
  /// Get all performance events
  static List<PerformanceEvent> getEvents() {
    return List.unmodifiable(_events);
  }
  
  /// Get performance summary
  static Map<String, dynamic> getPerformanceSummary() {
    final summary = <String, dynamic>{};
    
    for (final operation in _metrics.keys) {
      final metrics = _metrics[operation]!;
      final average = getAverageDuration(operation);
      
      summary[operation] = {
        'count': metrics.length,
        'average_ms': average?.inMilliseconds,
        'min_ms': metrics.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b),
        'max_ms': metrics.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b),
        'total_ms': metrics.fold<int>(0, (sum, d) => sum + d.inMilliseconds),
      };
    }
    
    return summary;
  }
  
  /// Clear all performance data
  static void clearData() {
    _timers.clear();
    _metrics.clear();
    _events.clear();
  }
  
  /// Log performance summary
  static void logSummary() {
    if (kDebugMode) {
      final summary = getPerformanceSummary();
      developer.log('📊 Performance Summary:', name: 'Performance');
      
      for (final entry in summary.entries) {
        final operation = entry.key;
        final data = entry.value as Map<String, dynamic>;
        developer.log(
          '  $operation: ${data['count']} calls, avg: ${data['average_ms']}ms, '
          'min: ${data['min_ms']}ms, max: ${data['max_ms']}ms',
          name: 'Performance'
        );
      }
    }
  }
  
  /// Check if an operation is taking too long
  static bool isSlowOperation(String operation, {Duration threshold = const Duration(seconds: 2)}) {
    final average = getAverageDuration(operation);
    return average != null && average > threshold;
  }
  
  /// Get slow operations
  static List<String> getSlowOperations({Duration threshold = const Duration(seconds: 2)}) {
    return _metrics.keys.where((operation) => isSlowOperation(operation, threshold: threshold)).toList();
  }
}

/// Performance event data class
class PerformanceEvent {
  final String operation;
  final Duration duration;
  final DateTime timestamp;
  
  PerformanceEvent({
    required this.operation,
    required this.duration,
    required this.timestamp,
  });
  
  @override
  String toString() {
    return 'PerformanceEvent(operation: $operation, duration: ${duration.inMilliseconds}ms, timestamp: $timestamp)';
  }
}

/// Performance monitoring mixin for widgets
mixin PerformanceMonitoringMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    PerformanceMonitor.startTimer('${T.toString()}_initState');
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    PerformanceMonitor.startTimer('${T.toString()}_didChangeDependencies');
  }
  
  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    PerformanceMonitor.startTimer('${T.toString()}_didUpdateWidget');
  }
  
  @override
  void dispose() {
    PerformanceMonitor.endTimer('${T.toString()}_initState');
    PerformanceMonitor.endTimer('${T.toString()}_didChangeDependencies');
    PerformanceMonitor.endTimer('${T.toString()}_didUpdateWidget');
    super.dispose();
  }
}

/// API performance monitoring
class ApiPerformanceMonitor {
  static const String _apiCallPrefix = 'api_call_';
  
  /// Monitor an API call
  static Future<T> monitorApiCall<T>(
    String endpoint,
    String method,
    Future<T> Function() apiCall,
  ) async {
    final operation = '${_apiCallPrefix}${method.toUpperCase()}_$endpoint';
    return PerformanceMonitor.timeOperation(operation, apiCall);
  }
  
  /// Get API performance summary
  static Map<String, dynamic> getApiPerformanceSummary() {
    final summary = <String, dynamic>{};
    final allMetrics = PerformanceMonitor.getPerformanceSummary();
    
    for (final entry in allMetrics.entries) {
      if (entry.key.startsWith(_apiCallPrefix)) {
        final endpoint = entry.key.substring(_apiCallPrefix.length);
        summary[endpoint] = entry.value;
      }
    }
    
    return summary;
  }
  
  /// Get slow API calls
  static List<String> getSlowApiCalls({Duration threshold = const Duration(seconds: 3)}) {
    final slowOperations = PerformanceMonitor.getSlowOperations(threshold: threshold);
    return slowOperations
        .where((op) => op.startsWith(_apiCallPrefix))
        .map((op) => op.substring(_apiCallPrefix.length))
        .toList();
  }
}

/// Memory usage monitoring
class MemoryMonitor {
  static void logMemoryUsage(String context) {
    if (kDebugMode) {
      // In a real implementation, you would use platform-specific memory monitoring
      // For now, we'll just log the context
      developer.log('🧠 Memory check: $context', name: 'Memory');
    }
  }
  
  /// Monitor memory usage during an operation
  static Future<T> monitorMemoryUsage<T>(String operation, Future<T> Function() fn) async {
    logMemoryUsage('Before: $operation');
    final result = await fn();
    logMemoryUsage('After: $operation');
    return result;
  }
}

/// Network performance monitoring
class NetworkPerformanceMonitor {
  static const String _networkPrefix = 'network_';
  
  /// Monitor network operation
  static Future<T> monitorNetworkOperation<T>(
    String operation,
    Future<T> Function() networkCall,
  ) async {
    final fullOperation = '${_networkPrefix}$operation';
    return PerformanceMonitor.timeOperation(fullOperation, networkCall);
  }
  
  /// Get network performance summary
  static Map<String, dynamic> getNetworkPerformanceSummary() {
    final summary = <String, dynamic>{};
    final allMetrics = PerformanceMonitor.getPerformanceSummary();
    
    for (final entry in allMetrics.entries) {
      if (entry.key.startsWith(_networkPrefix)) {
        final operation = entry.key.substring(_networkPrefix.length);
        summary[operation] = entry.value;
      }
    }
    
    return summary;
  }
}
