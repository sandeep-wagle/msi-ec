import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import 'package:msi_controller/domain/entities/system_info.dart';
import 'package:msi_controller/domain/entities/audio_profile.dart';
import 'package:msi_controller/domain/repositories/msi_repository.dart';
import 'package:msi_controller/services/hardware_monitor_service.dart';

@LazySingleton(as: MsiRepository)
class MsiRepositoryImpl implements MsiRepository {
  static const MethodChannel _channel = MethodChannel('msi_controller/channel');

  final HardwareMonitorService _hardwareMonitor = HardwareMonitorService();

  @override
  Stream<SystemInfo> get systemInfoStream => _hardwareMonitor.systemInfoStream;

  @override
  Stream<List<FanInfo>> get fanInfoStream => _hardwareMonitor.fanInfoStream;

  @override
  SystemInfo? get lastSystemInfo => _hardwareMonitor.lastSystemInfo;

  @override
  List<FanInfo>? get lastFanInfo => _hardwareMonitor.lastFanInfo;

  final _volumeController = StreamController<double>.broadcast();

  @override
  Stream<double> get volumeStream => _volumeController.stream;

  double _currentVolume = 1.0;
  @override
  double get currentVolume => _currentVolume;

  Timer? _pollingTimer;
  Timer? _fanPollingTimer;
  Process? _pactlSubscribe;
  bool _isSystemPolling = false;
  bool _isFanPolling = false;
  bool _hasMsiEc = false;
  bool _isDspUpdating = false;
  Timer? _dspUpdateTimer;
  Socket? _dspSocket;

  // Sound Settings State
  String _soundProfileName = 'Music';
  double _bass = 0.0;
  double _treble = 0.0;
  double _voice = 0.0;
  List<double> _eqGains = List.filled(10, 0.0);
  bool _compressor = false;
  bool _surround = false;
  double _stereoWidth = 0.0;
  double _noiseLevel = 0.0;
  bool _limiterEnabled = false;
  double _compressorRatio = 4.0;
  String _surroundVariation = 'Surround';
  bool _nightMode = false;
  bool _effectsEnabled = true;
  bool _micEnabled = true;
  double _micGain = 1.0;
  bool _micNoiseSuppression = false;
  bool _bassBoost = false;
  bool _trebleEnhancer = false;
  bool _voiceClarity = false;
  bool _echoCancellation = false;
  bool _trackerEnabled = false;
  bool _sharingEnabled = false;

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _pollSystemInfo();
    });

    _fanPollingTimer?.cancel();
    _fanPollingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _pollFanInfo();
    });

    _pollSystemInfo();
    _pollFanInfo();
    _startVolumeListener();
    _connectDspSocket();
  }

  Future<void>? _connectionFuture;
  DateTime _lastConnectAttempt = DateTime(2000);
  static const Duration _connectCooldown = Duration(seconds: 2);

  Future<void> _connectDspSocket() async {
    if (_dspSocket != null) return;
    if (_connectionFuture != null) return _connectionFuture;
    if (DateTime.now().difference(_lastConnectAttempt) < _connectCooldown) {
      return;
    }

    _lastConnectAttempt = DateTime.now();
    _connectionFuture = _doConnect();
    try {
      await _connectionFuture;
    } finally {
      _connectionFuture = null;
    }
  }

  Future<void> _doConnect() async {
    try {
      debugPrint('Repository: Attempting to connect to DSP socket...');
      _dspSocket = await Socket.connect(
        InternetAddress('/tmp/msi_dsp.sock', type: InternetAddressType.unix),
        0,
      ).timeout(const Duration(seconds: 2));

      debugPrint('Repository: Persistent DSP socket connected');

      _dspSocket!.listen(
        (data) {
          final msg = utf8.decode(data).trim();
          debugPrint('Repository: DSP response: $msg');

          // Handle volume response from GET_VOLUME command (REAL sink
          // level -> convert to DISPLAY units before emitting).
          if (msg.isNotEmpty &&
              !msg.startsWith('OK') &&
              !msg.startsWith('ERROR')) {
            final vol = double.tryParse(msg);
            if (vol != null) {
              _emitVolumeDisplay(_toDisplayVolume(vol));
            }
          }
        },
        onDone: () {
          debugPrint('Repository: DSP socket closed');
          _dspSocket = null;
          Timer(const Duration(seconds: 5), _connectDspSocket);
        },
        onError: (e) {
          debugPrint('Repository: DSP socket error: $e');
          _dspSocket = null;
        },
      );

      // Restore volume from saved state (raw 0..1; the service tempers it).
      final savedVolume = _currentVolume.clamp(0.0, 1.0);
      _sendDspCommand('VOLUME:${savedVolume.toStringAsFixed(4)}');
    } catch (e) {
      debugPrint('Repository: Failed to connect to DSP socket: $e');
      _dspSocket = null;
    }
  }

  bool _isSendingDspCommand = false;
  final List<String> _dspCommandQueue = [];

  Future<void> _sendDspCommand(String command) async {
    _dspCommandQueue.add(command);
    _processDspQueue();
  }

  Future<void> _processDspQueue() async {
    if (_isSendingDspCommand || _dspCommandQueue.isEmpty) return;
    _isSendingDspCommand = true;

    try {
      while (_dspCommandQueue.isNotEmpty) {
        final command = _dspCommandQueue.removeAt(0);

        if (_dspSocket == null) {
          await _connectDspSocket();
          // Still null? Try restarting the DSP service
          if (_dspSocket == null) {
            await _startDspService();
            // Try connecting again after service start
            await _connectDspSocket();
          }
        }

        final socket = _dspSocket;
        if (socket != null) {
          socket.write('$command\n');
          await socket.flush();
        } else {
          debugPrint('Repository: Cannot send command, socket null: $command');
        }
      }
    } catch (e) {
      debugPrint('Repository: Error sending DSP command: $e');
      _dspSocket = null;
    } finally {
      _isSendingDspCommand = false;
    }
  }

  void _startVolumeListener() async {
    try {
      _pactlSubscribe?.kill();
      _pactlSubscribe = await Process.start('pactl', [
        'subscribe',
      ], runInShell: true);
      _pactlSubscribe!.stdout.transform(const SystemEncoding().decoder).listen((
        data,
      ) {
        if (data.contains('sink') || data.contains('volume')) {
          _pollVolume();
        }
      });
    } catch (e) {
      debugPrint('Volume listener error: $e');
    }
  }

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final result = await _channel.invokeMethod<bool>('initialize');
      _hasMsiEc = result ?? false;
      _isInitialized = true;

      _startPolling();

      // Start DSP service and wait for it to be ready
      try {
        await _startDspService();
        debugPrint('DSP service initialization successful');
      } catch (e) {
        debugPrint('DSP service initialization failed: $e');
        // Continue without DSP service - app can still function for system controls
      }

      return true;
    } on PlatformException {
      _hasMsiEc = false;
      _isInitialized = true;
      _startPolling();

      // Try to start DSP service even on platform exception
      try {
        await _startDspService();
        debugPrint('DSP service initialization successful (fallback)');
      } catch (e) {
        debugPrint('DSP service initialization failed (fallback): $e');
      }

      return true;
    }
  }

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get hasMsiEcSupport => _hasMsiEc;

  double? _lastVolume;
  DateTime _lastPollRequest = DateTime.fromMillisecondsSinceEpoch(0);
  static const _pollMinInterval = Duration(milliseconds: 120);

  /// Inverse of the service temper (real 0.4-1.4 -> display 0-1). The
  /// service reports REAL sink levels; the UI speaks DISPLAY units. Without
  /// this conversion the slider shows tempered values and visibly fights
  /// the user's drag (30 -> 44 -> 20 flicker). Read-only: polls never
  /// write back, so the two UIs can't fight each other.
  double _toDisplayVolume(double real) {
    if (real <= 0.01) return 0.0;
    return ((real - 0.4) / 1.0).clamp(0.0, 1.0);
  }

  void _emitVolumeDisplay(double display) {
    if (_lastVolume == null || (_lastVolume! - display).abs() > 0.005) {
      _lastVolume = display;
      _currentVolume = display;
      _volumeController.add(display);
    }
  }

  Future<void> _pollVolume() async {
    // Coalesce key-hold storms: only the latest level matters, and the
    // socket roundtrip (~30ms) can't usefully run faster than this.
    final now = DateTime.now();
    if (now.difference(_lastPollRequest) < _pollMinInterval) return;
    _lastPollRequest = now;

    // Prefer getting volume from DSP service if connected
    if (_dspSocket != null) {
      await _sendDspCommand('GET_VOLUME');
      return;
    }

    try {
      final result = await Process.run('pactl', [
        'get-volume',
        '@DEFAULT_SINK@',
      ], runInShell: true);
      final output = result.stdout.toString();
      final match = RegExp(r'(\d+)%').firstMatch(output);
      if (match != null) {
        final vol = int.parse(match.group(1)!) / 100.0;
        _emitVolumeDisplay(_toDisplayVolume(vol));
      }
    } catch (e) {
      // Ignore volume poll errors
    }
  }

  Future<void> _startDspService() async {
    try {
      final dspSocket = File('/tmp/msi_dsp.sock');
      if (await dspSocket.exists()) {
        // Verify socket is alive by trying a quick connect
        try {
          final testSocket = await Socket.connect(
            InternetAddress(
              '/tmp/msi_dsp.sock',
              type: InternetAddressType.unix,
            ),
            0,
          ).timeout(const Duration(milliseconds: 500));
          testSocket.destroy();
          debugPrint('DSP service already running');
          return;
        } catch (_) {
          debugPrint('Stale DSP socket found, removing...');
          await dspSocket.delete();
        }
      }

      debugPrint('Starting DSP service...');
      // Resolve the binary relative to the current user's home instead of a
      // hardcoded (and stale, wrong-case) absolute path, so this works on any
      // machine / checkout location. Falls back to PATH lookup.
      final home = Platform.environment['HOME'] ?? '';
      final candidates = [
        if (home.isNotEmpty)
          '$home/Development/apps/flutter/apps/msi_controller/msi_dsp_service/target/release/msi_dsp_service',
        '/home/sandy/development/flutter/apps/msi_controller/msi_dsp_service/target/release/msi_dsp_service',
      ];
      String? dspPath;
      for (final c in candidates) {
        if (await File(c).exists()) {
          dspPath = c;
          break;
        }
      }
      dspPath ??= await _findOnPath('msi_dsp_service');
      if (dspPath == null) {
        debugPrint('DSP service binary not found; audio DSP disabled.');
        return;
      }

      await Process.start(dspPath, [], mode: ProcessStartMode.detached);

      await Future.delayed(const Duration(seconds: 2));
      debugPrint('DSP service started');
    } catch (e) {
      debugPrint('Failed to start DSP service: $e');
    }
  }

  Future<String?> _findOnPath(String binary) async {
    try {
      final result = await Process.run('which', [binary]);
      if (result.exitCode == 0) {
        final path = result.stdout.toString().trim().split('\n').first.trim();
        if (path.isNotEmpty && await File(path).exists()) return path;
      }
    } catch (_) {}
    return null;
  }

  bool _isInitialized = false;

  SystemInfo? _lastSystemInfo;
  List<FanInfo>? _lastFanInfo;

  bool _hasMeaningfulChange(SystemInfo? a, SystemInfo? b) {
    if (a == null || b == null) return true;
    return a.cpuUsage != b.cpuUsage ||
        a.gpuUsage != b.gpuUsage ||
        a.cpuTemperature != b.cpuTemperature ||
        a.gpuTemperature != b.gpuTemperature ||
        a.ramUsage != b.ramUsage;
  }

  bool _hasFanChange(List<FanInfo>? a, List<FanInfo>? b) {
    if (a == null || b == null) return true;
    if (a.length != b.length) return true;
    for (int i = 0; i < a.length; i++) {
      if (a[i].currentRpm != b[i].currentRpm ||
          a[i].targetRpm != b[i].targetRpm ||
          a[i].autoMode != b[i].autoMode) {
        return true;
      }
    }
    return false;
  }

  Future<void> _pollSystemInfo() async {
    if (_isSystemPolling) return;
    _isSystemPolling = true;
    try {
      Map<dynamic, dynamic>? result;

      if (_hasMsiEc) {
        result = await _channel.invokeMethod<Map>('getSystemInfoDirect');
      } else {
        result = await _channel.invokeMethod<Map>('getSystemInfoFallback');
      }

      if (result != null) {
        final info = SystemInfo(
          cpuTemperature: result['cpuTemp'] as int?,
          gpuTemperature: result['gpuTemp'] as int?,
          cpuFrequency: result['cpuFreq'] as int?,
          gpuCoreClock:
              result['gpuClock']
                  as int?, // Assuming 'gpuClock' from native side eventually
          batteryLevel: result['batteryLevel'] as int?,
          isCharging: result['isCharging'] as bool? ?? false,
          currentMode: _currentMode = PerformanceMode.fromString(
            result['mode'] as String? ?? '',
          ),
          batteryLimit: result['batteryLimit'] as int? ?? 100,
          ramTotal: result['ramTotal'] as int?,
          ramUsage: result['ramUsage'] as int?,
          resizableBar: result['resizableBar'] as bool? ?? false,
          voltages: Map<String, double>.from(
            (result['voltages'] as Map? ?? {}).map(
              (key, value) =>
                  MapEntry(key.toString(), (value as num).toDouble()),
            ),
          ),
          currentGpuMode: GpuMode.fromString(
            result['gpuMode'] as String? ?? 'dynamic',
          ),
          cpuModel: result['cpuModel'] as String?,
          gpuModel: result['gpuModel'] as String?,
          lanSpeed: result['lanSpeed'] as String?,
          wifiSpeed: result['wifiSpeed'] as String?,
          powerPlan: result['powerPlan'] as String?,
          diskUsage: (result['diskUsage'] as num?)?.toDouble() ?? 0.0,
          diskTotalGb: (result['diskTotalGb'] as num?)?.toDouble(),
          diskUsedGb: (result['diskUsedGb'] as num?)?.toDouble(),
          ssdHealth: (result['ssdHealth'] as num?)?.toDouble() ?? 95.0,
          ssdTemp: (result['ssdTemp'] as num?)?.toDouble() ?? 35.0,
          cpuUsage: result['cpuUsage'] as int?,
          gpuUsage: result['gpuUsage'] as int?,
          vramUsage: result['vramUsage'] as int?,
          vramTotal: result['vramTotal'] as int? ?? 8192,
        );
        if (_hasMeaningfulChange(_lastSystemInfo, info)) {
          _lastSystemInfo = info;
          _hardwareMonitor.updateSystemInfo(info);
        }
      }
    } on PlatformException catch (e) {
      debugPrint('Failed to get system info: ${e.message}');
    } finally {
      _isSystemPolling = false;
    }
  }

  Future<void> _pollFanInfo() async {
    if (_isFanPolling) return;
    _isFanPolling = true;
    try {
      List<dynamic>? result;

      if (_hasMsiEc) {
        result = await _channel.invokeMethod<List>('getFanInfoDirect');
      } else {
        result = await _channel.invokeMethod<List>('getFanInfoFallback');
      }

      if (result != null) {
        final fans = result.map((f) {
          final map = Map<String, dynamic>.from(f as Map);
          return FanInfo(
            fanIndex: map['index'] as int? ?? 0,
            currentRpm: map['currentRpm'] as int? ?? 0,
            minRpm: map['minRpm'] as int?,
            maxRpm: map['maxRpm'] as int?,
            targetRpm: map['targetRpm'] as int? ?? 0,
            autoMode: map['autoMode'] as bool? ?? true,
          );
        }).toList();
        if (_hasFanChange(_lastFanInfo, fans)) {
          _lastFanInfo = fans;
          _hardwareMonitor.updateFanInfo(fans);
        }
      }
    } on PlatformException catch (e) {
      debugPrint('Failed to get fan info: ${e.message}');
    } finally {
      _isFanPolling = false;
    }
  }

  PerformanceMode _currentMode = PerformanceMode.balanced;

  // Internal helper for buffer size based on mode
  int _getBufferSizeForMode(PerformanceMode mode) {
    if (mode == PerformanceMode.extreme ||
        mode == PerformanceMode.highPerformance) {
      return 256; // Low latency
    } else if (mode == PerformanceMode.silent ||
        mode == PerformanceMode.superBattery) {
      return 512; // Power-saving
    }
    return 256; // Balanced
  }

  // Removed duplicate _updateDspRealtime

  // Consolidated into _getBufferSizeForMode above

  @override
  Future<bool> setPerformanceMode(PerformanceMode mode) async {
    _currentMode = mode;
    if (!_hasMsiEc) return false;

    try {
      String modeStr;
      switch (mode) {
        case PerformanceMode.extreme:
          modeStr = 'turbo';
          break;
        case PerformanceMode.highPerformance:
          modeStr = 'sport';
          break;
        case PerformanceMode.balanced:
          modeStr = 'comfort';
          break;
        case PerformanceMode.silent:
          modeStr = 'eco';
          break;
        case PerformanceMode.superBattery:
          return setSuperBattery(true);
        default:
          return false;
      }

      final result = await _channel.invokeMethod<bool>('setMode', {
        'mode': modeStr,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to set mode: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> setSuperBattery(bool enable) async {
    if (!_hasMsiEc) return false;

    try {
      final result = await _channel.invokeMethod<bool>('setSuperBattery', {
        'enable': enable,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to set super battery: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> setBatteryLimit(int limit) async {
    if (limit < 30 || limit > 100) return false;

    try {
      final result = await _channel.invokeMethod<bool>('setBatteryLimit', {
        'limit': limit,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to set battery limit: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> setFanSpeed(int fanIndex, int rpm) async {
    if (fanIndex < 0 || rpm < 0) return false;
    if (!_hasMsiEc) return false;

    try {
      final result = await _channel.invokeMethod<bool>('setFanSpeed', {
        'index': fanIndex,
        'rpm': rpm,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to set fan speed: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> setPerformanceLevel(String level) async {
    if (!_hasMsiEc) return false;

    try {
      final result = await _channel.invokeMethod<bool>('setPerformanceLevel', {
        'level': level,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to set performance level: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> setFanAutoMode(int fanIndex, bool autoMode) async {
    if (!_hasMsiEc) return false;

    try {
      String mode;
      if (autoMode) {
        mode = 'auto';
      } else {
        mode = 'basic';
      }
      final result = await _channel.invokeMethod<bool>('setFanMode', {
        'mode': mode,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to set fan mode: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> setFanMode(FanMode mode) async {
    try {
      debugPrint('Setting unified Fan Mode: ${mode.displayName}');
      final result = await _channel.invokeMethod<bool>('setFanModeUnified', {
        'mode': mode.name,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to set unified fan mode: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> setKeyboardBacklight(KeyboardBacklightInfo info) async {
    if (info.brightness < 0 || info.brightness > 3) return false;
    if (!_hasMsiEc) return false;

    try {
      final result = await _channel.invokeMethod<bool>('setKeyboardBacklight', {
        'mode': info.mode,
        'brightness': info.brightness,
        'color1': info.color1,
        'color2': info.color2,
        'color3': info.color3,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to set keyboard backlight: ${e.message}');
      return false;
    }
  }

  @override
  Future<int> getKeyboardBacklight() async {
    try {
      final result = await _channel.invokeMethod<Map>('getKeyboardBacklight');
      if (result != null) {
        return result['brightness'] as int? ?? 0;
      }
    } on PlatformException catch (e) {
      debugPrint('Failed to get keyboard backlight: ${e.message}');
    }
    return -1;
  }

  @override
  Future<DeviceSettings> getDeviceSettings() async {
    // Always try the direct channel first: it probes each key independently,
    // so user-space settings (mic via pactl) resolve correctly even on
    // machines without msi-ec, where sysfs-backed keys simply read false.
    try {
      final result =
          await _channel.invokeMethod<Map>('getDeviceSettingsDirect');
      if (result != null) {
        return DeviceSettings(
          webcamEnabled: result['webcam'] as bool? ?? false,
          micEnabled: result['mic'] as bool? ?? false,
          usbPowerShare: result['usbPowerShare'] as bool? ?? false,
          coolerBoost: result['coolerBoost'] as bool? ?? false,
          shiftModeOverride: result['shiftModeOverride'] as int? ?? 0,
          keyboardBrightness: result['keyboardBrightness'] as int? ?? -1,
        );
      }
    } on PlatformException catch (e) {
      debugPrint('Direct device settings failed, using fallback: ${e.message}');
    }
    try {
      final result =
          await _channel.invokeMethod<Map>('getDeviceSettingsFallback');
      if (result != null) {
        return DeviceSettings(
          webcamEnabled: result['webcam'] as bool? ?? false,
          micEnabled: result['mic'] as bool? ?? false,
          usbPowerShare: result['usbPowerShare'] as bool? ?? false,
          coolerBoost: result['coolerBoost'] as bool? ?? false,
          shiftModeOverride: result['shiftModeOverride'] as int? ?? 0,
          keyboardBrightness: result['keyboardBrightness'] as int? ?? -1,
        );
      }
    } on PlatformException catch (e) {
      debugPrint('Failed to get device settings: ${e.message}');
    }
    return DeviceSettings();
  }

  @override
  Future<bool> setCoolerBoost(bool enable) async {
    return setDeviceSetting('coolerBoost', enable);
  }

  /// Settings applied in user space (no sysfs needed). These must work on
  /// every Linux machine, not just msi-ec hardware.
  static const _userSpaceKeys = {'mic'};

  @override
  Future<bool> setDeviceSetting(String key, dynamic value) async {
    if (!_hasMsiEc && !_userSpaceKeys.contains(key)) return false;

    try {
      final result = await _channel.invokeMethod<bool>('setDeviceSetting', {
        'key': key,
        'value': value,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to set device setting: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> freeUpMemory() async {
    try {
      final result = await _channel.invokeMethod<bool>('freeUpMemory');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to free up memory: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> setGamingMode(
    bool enable, {
    bool perf = true,
    bool audio = true,
    bool cooler = true,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('setGamingMode', {
        'enable': enable,
        'perf': perf,
        'audio': audio,
        'cooler': cooler,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to set gaming mode: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> cleanUpDisk() async {
    try {
      final result = await _channel.invokeMethod<bool>('cleanUpDisk');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to clean up disk: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> setSmartPriority(List<String> apps) async {
    try {
      final result = await _channel.invokeMethod<bool>('setSmartPriority', {
        'apps': apps,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to set smart priority: ${e.message}');
      return false;
    }
  }

  @override
  Future<void> refreshSystemInfo() async {
    await _pollSystemInfo();
  }

  @override
  Future<void> refreshFanInfo() async {
    await _pollFanInfo();
  }

  @override
  Future<bool> setFeatureEnabled(String featureId, bool enabled) async {
    try {
      debugPrint('Feature $featureId enabled: $enabled');
      final result = await _channel.invokeMethod<bool>('setDeviceSetting', {
        'key': featureId,
        'value': enabled ? 'on' : 'off',
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to set feature $featureId: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> openFeature(String featureId) async {
    debugPrint('Opening feature: $featureId');
    return true;
  }

  @override
  Future<void> openFile(String path) async {
    try {
      await _channel.invokeMethod('openFile', {'path': path});
    } on PlatformException catch (e) {
      debugPrint('Failed to open file: ${e.message}');
    }
  }

  @override
  void setActiveProfileName(String profile) {
    _soundProfileName = profile;
  }

  @override
  Future<bool> setSoundProfile(String profile) async {
    _soundProfileName = profile;
    try {
      debugPrint('Loading sound profile: $profile');
      await _sendDspCommand('LOAD:$profile');
      return true;
    } catch (e) {
      debugPrint('Failed to load sound profile: $e');
      await _updateDspRealtime();
      return false;
    }
  }

  @override
  Future<bool> setSoundEQ(List<double> gains) async {
    _eqGains = gains;
    await _commitDspChanges();
    return true;
  }

  @override
  Future<bool> setSoundEnhancement(String enhancement, bool enable) async {
    if (enhancement == 'smartVolume' || enhancement == 'compressor') {
      _compressor = enable;
      _limiterEnabled = enable; // Sync for Rust logic
    }
    if (enhancement == 'virtualSurround' || enhancement == 'surround') {
      _surround = enable;
    }
    if (enhancement == 'bassBoost') _bassBoost = enable;
    if (enhancement == 'trebleEnhancer') _trebleEnhancer = enable;
    if (enhancement == 'voiceClarity') _voiceClarity = enable;
    if (enhancement == 'tracker') _trackerEnabled = enable;
    if (enhancement == 'sharing') _sharingEnabled = enable;
    await _updateDspRealtime();
    return true;
  }

  @override
  Future<void> setSoundSampleRate(int hertz) async {
    debugPrint('Repository: Sample rate change requested: $hertz Hz');
  }

  @override
  Future<void> setSoundStereoWidth(double width) async {
    _stereoWidth = width;
    await _commitDspChanges();
  }

  @override
  Future<void> setSoundVolumeBoost(double boost) async {
    await setSoundVolume(boost);
  }

  @override
  Future<bool> setSoundEffectGain(String effect, double gain) async {
    if (effect == 'bass') _bass = gain;
    if (effect == 'treble') _treble = gain;
    if (effect == 'voice') _voice = gain;
    await _commitDspChanges();
    return true;
  }

  @override
  Future<void> setSoundNoiseLevel(double level) async {
    _noiseLevel = level;
    await _commitDspChanges();
  }

  @override
  Future<void> setSoundLimiterEnabled(bool enabled) async {
    _limiterEnabled = enabled;
    await _updateDspRealtime();
  }

  @override
  Future<void> setSoundCompressorRatio(double ratio) async {
    _compressorRatio = ratio;
    await _commitDspChanges();
  }

  @override
  Future<void> setSoundSurroundVariation(String variation) async {
    _surroundVariation = variation;
    await _updateDspRealtime();
  }

  @override
  Future<void> setSoundNightMode(bool enabled) async {
    _nightMode = enabled;
    await _updateDspRealtime();
  }

  @override
  Future<void> setSoundEffectsEnabled(bool enabled) async {
    _effectsEnabled = enabled;
    if (enabled) {
      await _sendDspCommand('ENABLE');
    } else {
      await _sendDspCommand('DISABLE');
    }
    await _updateDspRealtime();
  }

  @override
  Future<void> setSoundMicEnabled(bool enabled) async {
    _micEnabled = enabled;
    await _updateDspRealtime();
  }

  @override
  Future<void> setSoundMicGain(double gain) async {
    _micGain = gain;
    await _commitDspChanges();
  }

  @override
  Future<void> setSoundMicNoiseSuppression(bool enabled) async {
    _micNoiseSuppression = enabled;
    await _updateDspRealtime();
  }

  @override
  Future<void> setSoundEchoCancellation(bool enabled) async {
    _echoCancellation = enabled;
    await _updateDspRealtime();
  }

  @override
  Future<void> updateDsp(AudioProfile profile) async {
    final jsonStr = json.encode(profile.toJson());
    await _sendDspCommand('UPDATE:$jsonStr');
  }

  Future<void> setSoundVolume(double volume) async {
    // Negative = mute sentinel from the mute button: forward it, but keep
    // UI state on 0..1 (the service tempers display values to real ones).
    if (volume < 0) {
      await _sendDspCommand('VOLUME:${volume.toStringAsFixed(4)}');
      return;
    }
    _currentVolume = volume;
    _volumeController.add(volume);

    // Pass volume directly — slider range matches system volume range
    await _sendDspCommand('VOLUME:${volume.toStringAsFixed(4)}');
  }

  @override
  Future<void> applyCurrentProfile() async {
    await _updateDspRealtime();
  }

  @override
  Future<bool> setAiLanPriority(bool enable) async {
    try {
      final result = await _channel.invokeMethod<bool>('setAiLanPriority', {
        'enable': enable,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to set AI LAN priority: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> setGpuMode(GpuMode mode) async {
    try {
      final result = await _channel.invokeMethod<bool>('setGpuMode', {
        'mode': mode.name,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to set GPU mode: ${e.message}');
      return false;
    }
  }

  @override
  Future<void> ensureDspSocketConnected() async {
    if (_dspSocket == null) {
      await _connectDspSocket();
    }
  }

  @override
  Socket? get dspSocket => _dspSocket;

  // DSP Control methods (mapping to unified sound methods)
  @override
  Future<bool> setDspProfile(AudioProfile profile) async {
    _soundProfileName = profile.name;
    _bass = profile.bass;
    _treble = profile.treble;
    _voice = profile.voice;
    _eqGains = profile.eqGains;
    _compressor = profile.compressor;
    _surround = profile.surround;
    _stereoWidth = profile.stereoWidth;
    _noiseLevel = profile.noiseLevel;
    _limiterEnabled = profile.limiterEnabled;
    _compressorRatio = profile.compressorRatio;
    _surroundVariation = profile.surroundVariation;
    _nightMode = profile.nightMode;
    _effectsEnabled = profile.effectsEnabled;
    _micEnabled = profile.micEnabled;
    _micGain = profile.micGain;
    _micNoiseSuppression = profile.micNoiseSuppression;
    _echoCancellation = profile.echoCancellation;

    await _updateDspRealtime();
    return true;
  }

  @override
  Future<bool> setDspBass(double gain) async {
    _bass = gain;
    await _updateDspRealtime();
    return true;
  }

  @override
  Future<bool> setDspTreble(double gain) async {
    _treble = gain;
    await _updateDspRealtime();
    return true;
  }

  @override
  Future<bool> setDspCompressor(bool enable) async {
    _compressor = enable;
    await _updateDspRealtime();
    return true;
  }

  @override
  Future<bool> enableDsp() async {
    await setSoundEffectsEnabled(true);
    return true;
  }

  @override
  Future<bool> disableDsp() async {
    await setSoundEffectsEnabled(false);
    return true;
  }

  @override
  Future<bool> getDspStatus() async {
    await _sendDspCommand('STATUS');
    return true;
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _fanPollingTimer?.cancel();
    _dspUpdateTimer?.cancel();
    _pactlSubscribe?.kill();
    _dspSocket?.close();
    _dspSocket = null;
  }

  Future<void> _sendDspUpdate() async {
    if (_isDspUpdating) return;
    _isDspUpdating = true;
    try {
      final profile = AudioProfile(
        name: _soundProfileName,
        bass: _bass,
        treble: _treble,
        voice: _voice,
        eqGains: _eqGains,
        compressor: _compressor,
        surround: _surround,
        volume: _currentVolume,
        surroundVariation: _surroundVariation,
        nightMode: _nightMode,
        effectsEnabled: _effectsEnabled,
        micEnabled: _micEnabled,
        micGain: _micGain,
        micNoiseSuppression: _micNoiseSuppression,
        echoCancellation: _echoCancellation,
        voiceClarity: _voiceClarity,
        trebleEnhancer: _trebleEnhancer,
        bassBoost: _bassBoost,
        trackerEnabled: _trackerEnabled,
        sharingEnabled: _sharingEnabled,
        stereoWidth: _stereoWidth,
        noiseLevel: _noiseLevel,
        limiterEnabled: _limiterEnabled,
        compressorRatio: _compressorRatio,
        bufferSize: _getBufferSizeForMode(_currentMode),
      );

      final jsonStr = json.encode(profile.toJson());
      await _sendDspCommand('UPDATE:$jsonStr');
    } catch (e) {
      debugPrint('Failed to update DSP: $e');
    } finally {
      _isDspUpdating = false;
    }
  }

  Future<void> _commitDspChanges() async {
    _dspUpdateTimer?.cancel();
    await _sendDspUpdate();
  }

  Future<void> _updateDspRealtime() async {
    _dspUpdateTimer?.cancel();
    _dspUpdateTimer = Timer(const Duration(milliseconds: 400), _sendDspUpdate);
  }
}
