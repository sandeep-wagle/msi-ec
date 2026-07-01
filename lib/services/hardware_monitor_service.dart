import 'dart:async';
import 'package:msi_controller/domain/entities/system_info.dart';

class HardwareMonitorService {
  static final HardwareMonitorService _instance =
      HardwareMonitorService._internal();
  factory HardwareMonitorService() => _instance;
  HardwareMonitorService._internal();

  final StreamController<SystemInfo> _systemInfoController =
      StreamController<SystemInfo>.broadcast();
  final StreamController<List<FanInfo>> _fanInfoController =
      StreamController<List<FanInfo>>.broadcast();

  Stream<SystemInfo> get systemInfoStream => _systemInfoController.stream;
  Stream<List<FanInfo>> get fanInfoStream => _fanInfoController.stream;

  SystemInfo? _lastSystemInfo;
  List<FanInfo>? _lastFanInfo;

  SystemInfo? get lastSystemInfo => _lastSystemInfo;
  List<FanInfo>? get lastFanInfo => _lastFanInfo;

  void updateSystemInfo(SystemInfo info) {
    if (_lastSystemInfo == null || !_systemInfoEqual(_lastSystemInfo!, info)) {
      _lastSystemInfo = info;
      _systemInfoController.add(info);
    }
  }

  void updateFanInfo(List<FanInfo> fans) {
    if (_lastFanInfo == null || !_fanInfoEqual(_lastFanInfo!, fans)) {
      _lastFanInfo = fans;
      _fanInfoController.add(fans);
    }
  }

  bool _systemInfoEqual(SystemInfo a, SystemInfo b) {
    return a.cpuTemperature == b.cpuTemperature &&
        a.gpuTemperature == b.gpuTemperature &&
        a.batteryLevel == b.batteryLevel &&
        a.currentMode == b.currentMode;
  }

  bool _fanInfoEqual(List<FanInfo> a, List<FanInfo> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].currentRpm != b[i].currentRpm ||
          a[i].targetRpm != b[i].targetRpm ||
          a[i].autoMode != b[i].autoMode) {
        return false;
      }
    }
    return true;
  }
}
