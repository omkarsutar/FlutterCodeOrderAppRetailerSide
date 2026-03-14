import 'web_utils_interface.dart';
export 'web_utils_interface.dart';

abstract class WebUtils {
  /// Cleans up URL query parameters (code, state, etc.) after Google login redirect on web.
  void cleanUrlParameters();

  /// Gets the current URL's UTM source parameter on web.
  String? getUtmSource();

  /// Logs memory diagnostics on web.
  void logMemoryDiagnostics();
}
