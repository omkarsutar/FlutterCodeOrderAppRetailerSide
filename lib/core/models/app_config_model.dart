class AppConfig {
  final bool vacationMode;
  final String vacationMessage;
  final DateTime? vacationUntil;

  AppConfig({
    required this.vacationMode,
    required this.vacationMessage,
    this.vacationUntil,
  });

  factory AppConfig.fromMap(Map<String, dynamic> map) {
    return AppConfig(
      vacationMode: map['vacation_mode'] ?? false,
      vacationMessage:
          map['vacation_message'] ?? 'We are currently on vacation.',
      vacationUntil: map['vacation_until'] != null
          ? DateTime.parse(map['vacation_until'])
          : null,
    );
  }

  factory AppConfig.initial() {
    return AppConfig(vacationMode: false, vacationMessage: 'Initial State');
  }
}
