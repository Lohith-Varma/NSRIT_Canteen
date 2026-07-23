class AppSettingsModel {
  final String collegeName;
  final String canteenName;
  final String currency;
  final List<String> measurementUnits;
  final bool darkMode;
  final bool lowStockNotifications;
  final bool salesNotifications;
  final bool preparationNotifications;
  final String appVersion;

  const AppSettingsModel({
    required this.collegeName,
    required this.canteenName,
    required this.currency,
    required this.measurementUnits,
    required this.darkMode,
    required this.lowStockNotifications,
    required this.salesNotifications,
    required this.preparationNotifications,
    required this.appVersion,
  });

  factory AppSettingsModel.defaults() {
    return const AppSettingsModel(
      collegeName: 'NSRIT',
      canteenName: 'Smart Canteen',
      currency: 'INR',
      measurementUnits: [
        'kg',
        'g',
        'litre',
        'ml',
        'pieces',
        'packets',
        'boxes',
      ],
      darkMode: false,
      lowStockNotifications: true,
      salesNotifications: true,
      preparationNotifications: true,
      appVersion: '1.0.0',
    );
  }

  AppSettingsModel copyWith({
    String? collegeName,
    String? canteenName,
    String? currency,
    List<String>? measurementUnits,
    bool? darkMode,
    bool? lowStockNotifications,
    bool? salesNotifications,
    bool? preparationNotifications,
    String? appVersion,
  }) {
    return AppSettingsModel(
      collegeName: collegeName ?? this.collegeName,
      canteenName: canteenName ?? this.canteenName,
      currency: currency ?? this.currency,
      measurementUnits: measurementUnits ?? this.measurementUnits,
      darkMode: darkMode ?? this.darkMode,
      lowStockNotifications:
          lowStockNotifications ?? this.lowStockNotifications,
      salesNotifications: salesNotifications ?? this.salesNotifications,
      preparationNotifications:
          preparationNotifications ?? this.preparationNotifications,
      appVersion: appVersion ?? this.appVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'collegeName': collegeName,
      'canteenName': canteenName,
      'currency': currency,
      'measurementUnits': measurementUnits,
      'darkMode': darkMode,
      'lowStockNotifications': lowStockNotifications,
      'salesNotifications': salesNotifications,
      'preparationNotifications': preparationNotifications,
      'appVersion': appVersion,
    };
  }

  factory AppSettingsModel.fromMap(Map<String, dynamic> map) {
    return AppSettingsModel(
      collegeName: map['collegeName'] ?? 'NSRIT',
      canteenName: map['canteenName'] ?? 'Smart Canteen',
      currency: map['currency'] ?? 'INR',
      measurementUnits: map['measurementUnits'] is List
          ? List<String>.from(map['measurementUnits'])
          : AppSettingsModel.defaults().measurementUnits,
      darkMode: map['darkMode'] ?? false,
      lowStockNotifications: map['lowStockNotifications'] ?? true,
      salesNotifications: map['salesNotifications'] ?? true,
      preparationNotifications: map['preparationNotifications'] ?? true,
      appVersion: map['appVersion'] ?? '1.0.0',
    );
  }
}
