import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_config_model.dart';
import '../services/app_config_service.dart';

final appConfigServiceProvider = Provider<AppConfigService>((ref) {
  return AppConfigService(Supabase.instance.client);
});

final appConfigProvider = StreamProvider<AppConfig>((ref) {
  final service = ref.watch(appConfigServiceProvider);
  return service.watchConfig();
});
