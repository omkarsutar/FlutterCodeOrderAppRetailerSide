import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'web_utils_interface.dart';

class WebUtilsImpl implements WebUtils {
  @override
  void cleanUrlParameters() {
    final currentUrl = html.window.location.href;
    if (currentUrl.contains('?')) {
      final newUrl = currentUrl.split('?')[0] + html.window.location.hash;
      html.window.history.replaceState(null, '', newUrl);
      debugPrint('WebUtils: Cleaned up URL parameters');
    }
  }

  @override
  String? getUtmSource() {
    try {
      final uri = Uri.parse(html.window.location.href);
      final utmSource = uri.queryParameters['utm_source'];
      if (utmSource != null && utmSource.isNotEmpty) {
        return _translateUtmSource(utmSource);
      }
      return null;
    } catch (e) {
      debugPrint('WebUtils: Error getting UTM source: $e');
      return null;
    }
  }

  String _translateUtmSource(String utmSource) {
    final translationMap = {
      'a': '0',
      'b': '1',
      'c': '2',
      'd': '3',
      'e': '4',
      'f': '5',
      'g': '6',
      'h': '7',
      'i': '8',
      'j': '9',
    };

    return utmSource
        .split('')
        .map((char) {
          return translationMap[char] ?? char;
        })
        .join('');
  }

  @override
  void logMemoryDiagnostics() {
    try {
      // ignore: undefined_prefixed_name
      final memory = (html.window.performance as dynamic).memory;
      if (memory != null) {
        final used = (memory.usedJSHeapSize / 1024 / 1024).toStringAsFixed(2);
        final limit = (memory.jsHeapSizeLimit / 1024 / 1024).toStringAsFixed(2);
        debugPrint('--- MEMORY DIAGNOSTIC ---');
        debugPrint('JS Heap Used: $used MB / $limit MB');
        debugPrint('-------------------------');
      }
    } catch (e) {
      // Silent fail if performance.memory is not supported (e.g. Firefox)
    }
  }
}

WebUtils getWebUtils() => WebUtilsImpl();
