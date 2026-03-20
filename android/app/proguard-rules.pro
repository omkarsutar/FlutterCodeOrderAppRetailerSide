# ProGuard rules for Flutter
# Add project specific ProGuard rules here.
# By default, the rules in this file are appended to the default ProGuard rules from the Android Gradle plugin.
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Flutter-specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
-ignorewarnings
