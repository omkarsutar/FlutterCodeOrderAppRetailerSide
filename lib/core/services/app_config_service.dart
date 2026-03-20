import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_config_model.dart';
import 'package:flutter/foundation.dart';

class AppConfigService {
  final SupabaseClient _supabase;

  AppConfigService(this._supabase);

  /// Fetches the global application configuration from the `app_config` table.
  /// This table stores simple key-value pairs for app-wide settings.
  Future<AppConfig> fetchConfig() async {
    try {
      final List<dynamic> data = await _supabase.from('app_config').select();
      
      final Map<String, dynamic> configMap = {};
      for (var row in data) {
        final key = row['config_key'] as String;
        if (row['config_value_bool'] != null) {
          configMap[key] = row['config_value_bool'];
        } else if (row['config_value_text'] != null) {
          configMap[key] = row['config_value_text'];
        } else if (row['config_value_date'] != null) {
          configMap[key] = row['config_value_date'];
        }
      }
      
      return AppConfig.fromMap(configMap);
    } catch (e) {
      debugPrint('AppConfigService: Error fetching app config: $e');
      // Return default config if fetch fails to avoid blocking the app completely unless intended
      return AppConfig.initial();
    }
  }

  /// Streams the configuration for real-time updates
  Stream<AppConfig> watchConfig() {
    return _supabase
        .from('app_config')
        .stream(primaryKey: ['config_id'])
        .map((data) {
          final Map<String, dynamic> configMap = {};
          for (var row in data) {
            final key = row['config_key'] as String;
            if (row['config_value_bool'] != null) {
              configMap[key] = row['config_value_bool'];
            } else if (row['config_value_text'] != null) {
              configMap[key] = row['config_value_text'];
            } else if (row['config_value_date'] != null) {
              configMap[key] = row['config_value_date'];
            }
          }
          return AppConfig.fromMap(configMap);
        });
  }
}
