import 'web_utils_interface.dart';

class WebUtilsImpl implements WebUtils {
  @override
  void cleanUrlParameters() {
    // No-op on mobile
  }

  @override
  String? getUtmSource() {
    // Mobile doesn't use URL parameters this way
    return null;
  }

  @override
  void logMemoryDiagnostics() {
    // No-op on mobile (use other profiling tools)
  }
}

WebUtils getWebUtils() => WebUtilsImpl();
