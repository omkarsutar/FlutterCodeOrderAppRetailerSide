import 'web_utils_interface.dart';
import 'web_utils_mobile.dart' if (dart.library.html) 'web_utils_web.dart';

/// Access to web-only utilities that doesn't break mobile builds.
final webUtils = getWebUtils();
