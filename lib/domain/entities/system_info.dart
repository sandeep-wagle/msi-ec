enum PerformanceMode {
  extreme,
  highPerformance,
  balanced,
  silent,
  superBattery,
  user,
  unknown;

  String get displayName {
    switch (this) {
      case PerformanceMode.extreme:
        return 'Extreme';
      case PerformanceMode.highPerformance:
        return 'High Performance';
      case PerformanceMode.balanced:
        return 'Balanced';
      case PerformanceMode.silent:
        return 'Silent';
      case PerformanceMode.superBattery:
        return 'Super Battery';
      case PerformanceMode.user:
        return 'User';
      case PerformanceMode.unknown:
        return 'Unknown';
    }
  }

  static PerformanceMode fromString(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll('-', '')
        .replaceAll(' ', '');

    switch (normalized) {
      case 'extreme':
        return PerformanceMode.extreme;
      case 'highperformance':
      case 'performance':
      case 'high':
        return PerformanceMode.highPerformance;
      case 'balanced':
        return PerformanceMode.balanced;
      case 'silent':
        return PerformanceMode.silent;
      case 'superbattery':
        return PerformanceMode.superBattery;
      case 'user':
      case 'custom':
      case 'customize':
        return PerformanceMode.user;
      default:
        return PerformanceMode.unknown;
    }
  }
}

enum GpuMode {
  dynamic,
  discrete,
  integrated,
  hybrid,
  unknown;

  String get displayName {
    switch (this) {
      case GpuMode.dynamic:
        return 'Dynamic';
      case GpuMode.discrete:
        return 'Discrete';
      case GpuMode.integrated:
        return 'Integrated';
      case GpuMode.hybrid:
        return 'Hybrid';
      case GpuMode.unknown:
        return 'Unknown';
    }
  }

  static GpuMode fromString(String value) {
    switch (value.toLowerCase()) {
      case 'dynamic':
      case 'on-demand':
        return GpuMode.dynamic;
      case 'discrete':
      case 'performance':
        return GpuMode.discrete;
      case 'integrated':
      case 'eco':
        return GpuMode.integrated;
      case 'hybrid':
      case 'smart':
        return GpuMode.hybrid;
      default:
        return GpuMode.unknown;
    }
  }
}

enum FanMode {
  auto,
  coolerBoost,
  advanced;

  String get displayName {
    switch (this) {
      case FanMode.auto:
        return 'Auto';
      case FanMode.coolerBoost:
        return 'Cooler Boost';
      case FanMode.advanced:
        return 'Advanced';
    }
  }

  static FanMode fromString(String value) {
    switch (value.toLowerCase()) {
      case 'auto':
        return FanMode.auto;
      case 'coolerboost':
      case 'cooler_boost':
      case 'cooler boost':
        return FanMode.coolerBoost;
      case 'manual':
      case 'basic':
      case 'advanced':
        return FanMode.advanced;
      default:
        return FanMode.auto;
    }
  }
}

enum PerformanceLevel {
  low,
  medium,
  high,
  turbo;

  String get displayName {
    switch (this) {
      case PerformanceLevel.low:
        return 'Low';
      case PerformanceLevel.medium:
        return 'Medium';
      case PerformanceLevel.high:
        return 'High';
      case PerformanceLevel.turbo:
        return 'Turbo';
    }
  }

  static PerformanceLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return PerformanceLevel.low;
      case 'medium':
        return PerformanceLevel.medium;
      case 'high':
        return PerformanceLevel.high;
      case 'turbo':
      case 'extreme':
        return PerformanceLevel.turbo;
      default:
        return PerformanceLevel.medium;
    }
  }
}

class SystemInfo {
  final int? cpuTemperature;
  final int? gpuTemperature;
  final int? cpuFrequency; // in MHz
  final int? gpuCoreClock; // in MHz
  final int? batteryLevel;
  final bool isCharging;
  final PerformanceMode currentMode;
  final int batteryLimit;
  final int fanSpeed; // 0-100%
  final String performanceLevel; // low, medium, high, turbo
  final int? ramUsage; // in MB
  final int? ramTotal; // in MB
  final Map<String, double> voltages; // e.g. {"3.3V": 3.28, "5V": 4.88}
  final bool resizableBar;
  final int? gpuUsage;
  final int? cpuUsage;
  final int? vramUsage; // in MB
  final int? vramTotal; // in MB
  final double diskUsage;
  final double? diskTotalGb;
  final double? diskUsedGb;
  final double ssdHealth;
  final double ssdTemp;
  final bool smartPriorityEnabled;
  final GpuMode currentGpuMode;
  final String? cpuModel;
  final String? gpuModel;
  final String? lanSpeed;
  final String? wifiSpeed;
  final String? powerPlan;
  final DateTime timestamp;

  SystemInfo({
    this.cpuTemperature,
    this.gpuTemperature,
    this.cpuFrequency,
    this.gpuCoreClock,
    this.batteryLevel,
    this.isCharging = false,
    this.currentMode = PerformanceMode.unknown,
    this.batteryLimit = 100,
    this.fanSpeed = 50,
    this.performanceLevel = 'medium',
    this.ramUsage,
    this.ramTotal,
    this.voltages = const {},
    this.resizableBar = false,
    this.gpuUsage,
    this.cpuUsage,
    this.vramUsage,
    this.vramTotal = 8192, // Default to 8GB for RTX 3080 fallback
    this.diskUsage = 0.0,
    this.diskTotalGb,
    this.diskUsedGb,
    this.ssdHealth = 95.0,
    this.ssdTemp = 35.0,
    this.smartPriorityEnabled = false,
    this.currentGpuMode = GpuMode.dynamic,
    this.cpuModel,
    this.gpuModel,
    this.lanSpeed,
    this.wifiSpeed,
    this.powerPlan,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  SystemInfo copyWith({
    int? cpuTemperature,
    int? gpuTemperature,
    int? cpuFrequency,
    int? gpuCoreClock,
    int? batteryLevel,
    bool? isCharging,
    PerformanceMode? currentMode,
    int? batteryLimit,
    int? fanSpeed,
    String? performanceLevel,
    int? ramUsage,
    int? ramTotal,
    Map<String, double>? voltages,
    bool? resizableBar,
    int? gpuUsage,
    int? cpuUsage,
    int? vramUsage,
    int? vramTotal,
    double? diskUsage,
    double? diskTotalGb,
    double? diskUsedGb,
    double? ssdHealth,
    double? ssdTemp,
    bool? smartPriorityEnabled,
    GpuMode? currentGpuMode,
    String? cpuModel,
    String? gpuModel,
    String? lanSpeed,
    String? wifiSpeed,
    String? powerPlan,
  }) {
    return SystemInfo(
      cpuTemperature: cpuTemperature ?? this.cpuTemperature,
      gpuTemperature: gpuTemperature ?? this.gpuTemperature,
      cpuFrequency: cpuFrequency ?? this.cpuFrequency,
      gpuCoreClock: gpuCoreClock ?? this.gpuCoreClock,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isCharging: isCharging ?? this.isCharging,
      currentMode: currentMode ?? this.currentMode,
      batteryLimit: batteryLimit ?? this.batteryLimit,
      fanSpeed: fanSpeed ?? this.fanSpeed,
      performanceLevel: performanceLevel ?? this.performanceLevel,
      ramUsage: ramUsage ?? this.ramUsage,
      ramTotal: ramTotal ?? this.ramTotal,
      voltages: voltages ?? this.voltages,
      resizableBar: resizableBar ?? this.resizableBar,
      gpuUsage: gpuUsage ?? this.gpuUsage,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      vramUsage: vramUsage ?? this.vramUsage,
      vramTotal: vramTotal ?? this.vramTotal,
      diskUsage: diskUsage ?? this.diskUsage,
      diskTotalGb: diskTotalGb ?? this.diskTotalGb,
      diskUsedGb: diskUsedGb ?? this.diskUsedGb,

      ssdHealth: ssdHealth ?? this.ssdHealth,
      ssdTemp: ssdTemp ?? this.ssdTemp,
      smartPriorityEnabled: smartPriorityEnabled ?? this.smartPriorityEnabled,
      currentGpuMode: currentGpuMode ?? this.currentGpuMode,
      cpuModel: cpuModel ?? this.cpuModel,
      gpuModel: gpuModel ?? this.gpuModel,
      lanSpeed: lanSpeed ?? this.lanSpeed,
      wifiSpeed: wifiSpeed ?? this.wifiSpeed,
      powerPlan: powerPlan ?? this.powerPlan,
      timestamp: timestamp,
    );
  }
}

class FanInfo {
  final int fanIndex;
  final int currentRpm;
  final int? minRpm;
  final int? maxRpm;
  final int targetRpm;
  final bool autoMode;

  FanInfo({
    required this.fanIndex,
    this.currentRpm = 0,
    this.minRpm,
    this.maxRpm,
    this.targetRpm = 0,
    this.autoMode = true,
  });

  FanInfo copyWith({
    int? currentRpm,
    int? minRpm,
    int? maxRpm,
    int? targetRpm,
    bool? autoMode,
  }) {
    return FanInfo(
      fanIndex: fanIndex,
      currentRpm: currentRpm ?? this.currentRpm,
      minRpm: minRpm ?? this.minRpm,
      maxRpm: maxRpm ?? this.maxRpm,
      targetRpm: targetRpm ?? this.targetRpm,
      autoMode: autoMode ?? this.autoMode,
    );
  }
}

class KeyboardBacklightInfo {
  final int mode;
  final int brightness;
  final int color1;
  final int color2;
  final int color3;

  KeyboardBacklightInfo({
    this.mode = 0,
    this.brightness = 3,
    this.color1 = 0xffffff,
    this.color2 = 0xff0000,
    this.color3 = 0x00ff00,
  });

  KeyboardBacklightInfo copyWith({
    int? mode,
    int? brightness,
    int? color1,
    int? color2,
    int? color3,
  }) {
    return KeyboardBacklightInfo(
      mode: mode ?? this.mode,
      brightness: brightness ?? this.brightness,
      color1: color1 ?? this.color1,
      color2: color2 ?? this.color2,
      color3: color3 ?? this.color3,
    );
  }
}

class DeviceSettings {
  final bool webcamEnabled;
  final bool micEnabled;
  final bool usbPowerShare;
  final bool coolerBoost;
  final int shiftModeOverride;
  final int keyboardBrightness;
  final int keyboardMode;

  DeviceSettings({
    this.webcamEnabled = false,
    this.micEnabled = false,
    this.usbPowerShare = false,
    this.coolerBoost = false,
    this.shiftModeOverride = 0,
    this.keyboardBrightness = -1,
    this.keyboardMode = 0,
  });

  DeviceSettings copyWith({
    bool? webcamEnabled,
    bool? micEnabled,
    bool? usbPowerShare,
    bool? coolerBoost,
    int? shiftModeOverride,
    int? keyboardBrightness,
    int? keyboardMode,
  }) {
    return DeviceSettings(
      webcamEnabled: webcamEnabled ?? this.webcamEnabled,
      micEnabled: micEnabled ?? this.micEnabled,
      usbPowerShare: usbPowerShare ?? this.usbPowerShare,
      coolerBoost: coolerBoost ?? this.coolerBoost,
      shiftModeOverride: shiftModeOverride ?? this.shiftModeOverride,
      keyboardBrightness: keyboardBrightness ?? this.keyboardBrightness,
      keyboardMode: keyboardMode ?? this.keyboardMode,
    );
  }
}
