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

  final _volumeController = StreamController<double>.broadcast();

  @override
  Stream<double> get volumeStream => _volumeController.stream;

  double _currentVolume = 1.0;
  @override
  double get currentVolume => _currentVolume;

  Timer? _pollingTimer;
  Timer? _volumePollTimer;
  Process? _pactlSubscribe;
  bool _isSystemPolling = false;
  bool _isFanPolling = false;
  bool _hasMsiEc = false;
  bool _isDspUpdating = false;

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _pollSystemInfo();
      _pollFanInfo();
    });
    _pollSystemInfo();
    _pollFanInfo();
    _startVolumeListener();
  }

  void _startVolumeListener() async {
    try {
      _pactlSubscribe?.kill();
      _pactlSubscribe = await Process.start('pactl', [
        'subscribe',
      ], runInShell: true);
      _pactlSubscribe!.stderr.transform(const SystemEncoding().decoder).listen((
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

  Future<void> _pollVolume() async {
    try {
      final result = await Process.run('pactl', [
        'get-volume',
        '@DEFAULT_SINK@',
      ], runInShell: true);
      final output = result.stdout.toString();
      final match = RegExp(r'(\d+)%').firstMatch(output);
      if (match != null) {
        final vol = int.parse(match.group(1)!) / 100.0;
        if (_lastVolume == null || (_lastVolume! - vol).abs() > 0.01) {
          _lastVolume = vol;
          _currentVolume = vol;
          _volumeController.add(vol);
        }
      }
    } catch (e) {
      // Ignore volume poll errors
    }
  }

  Future<void> _startDspService() async {
    try {
      final dspSocket = File('/tmp/msi_dsp.sock');
      if (await dspSocket.exists()) {
        debugPrint('DSP service already running');
        return;
      }

      debugPrint('Starting DSP service...');
      final dspPath =
          '/home/sandy/development/flutter/apps/msi_controller/msi_dsp_service/target/release/msi_dsp_service';

      await Process.start(dspPath, [], mode: ProcessStartMode.detached);

      await Future.delayed(const Duration(seconds: 2));
      debugPrint('DSP service started');
    } catch (e) {
      debugPrint('Failed to start DSP service: $e');
    }
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

  // Audio state for DSP
  String _soundProfileName = 'Default';
  List<double> _eqGains = List.filled(10, 0.0);
  double _bassGain = 0.0;
  double _trebleGain = 0.0;
  double _voiceGain = 0.0;
  bool _compressor = false;
  bool _surround = false;
  double _volume = 1.0;

  Future<void> _updateDsp() async {
    final profile = AudioProfile(
      name: _soundProfileName,
      bass: _bassGain,
      treble: _trebleGain,
      voice: _voiceGain,
      eqGains: _eqGains,
      compressor: _compressor,
      surround: _surround,
      volume: _volume,
    );
    await setDspProfile(profile);
  }

  Future<void> _updateDspRealtime() async {
    if (_isDspUpdating) {
      debugPrint('Repository: DSP update already in progress, skipping');
      return;
    }

    debugPrint('Repository: Starting DSP realtime update');
    _isDspUpdating = true;

    try {
      final socket = await Socket.connect(
        InternetAddress('/tmp/msi_dsp.sock', type: InternetAddressType.unix),
        0,
      );
      debugPrint('Repository: Connected to DSP socket');

      final profile = AudioProfile(
        name: _soundProfileName,
        bass: _bassGain,
        treble: _trebleGain,
        voice: _voiceGain,
        eqGains: _eqGains,
        compressor: _compressor,
        surround: _surround,
        volume: _volume,
      );
      final json = profile.toJson();
      debugPrint(
        'DSP update: profile=${profile.name}, bass=${profile.bass}, treble=${profile.treble}, voice=${profile.voice}',
      );

      final command = 'UPDATE:${jsonEncode(json)}';
      debugPrint('Repository: Sending command: $command');

      socket.write(command);
      await socket.flush();
      debugPrint('Repository: Command flushed, waiting for response');

      final response = await socket.first.timeout(const Duration(seconds: 5));
      final responseStr = utf8.decode(response).trim();
      debugPrint('Repository: Received response: $responseStr');

      if (responseStr == 'OK') {
        debugPrint('Real-time DSP update applied successfully');
      } else {
        debugPrint('Realtime DSP update unexpected response: $responseStr');
      }

      await socket.close();
      debugPrint('Repository: Socket closed');
    } catch (e) {
      debugPrint('Failed to send realtime update: $e');
    } finally {
      _isDspUpdating = false;
    }
  }

  int _getBufferSizeForMode(PerformanceMode mode) {
    if (mode == PerformanceMode.extreme ||
        mode == PerformanceMode.highPerformance) {
      return 128; // Gaming
    } else if (mode == PerformanceMode.silent ||
        mode == PerformanceMode.superBattery) {
      return 512; // Power-saving
    }
    return 256; // Balanced
  }

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
  Future<DeviceSettings> getDeviceSettings() async {
    try {
      final result = await _channel.invokeMethod<Map>(
        _hasMsiEc ? 'getDeviceSettingsDirect' : 'getDeviceSettingsFallback',
      );
      if (result != null) {
        return DeviceSettings(
          webcamEnabled: result['webcam'] as bool? ?? false,
          micEnabled: result['mic'] as bool? ?? false,
          usbPowerShare: result['usbPowerShare'] as bool? ?? false,
          coolerBoost: result['coolerBoost'] as bool? ?? false,
          shiftModeOverride: result['shiftModeOverride'] as int? ?? 0,
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

  @override
  Future<bool> setDeviceSetting(String key, dynamic value) async {
    if (!_hasMsiEc) return false;

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
    // Simulate disk cleanup
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }

  @override
  Future<bool> setFeatureEnabled(String featureId, bool enabled) async {
    debugPrint('Feature $featureId enabled: $enabled');
    return true;
  }

  @override
  Future<bool> openFeature(String featureId) async {
    debugPrint('Opening feature: $featureId');
    return true;
  }

  @override
  Future<bool> setSoundProfile(String profile) async {
    _soundProfileName = profile;
    try {
      debugPrint('Loading sound profile: $profile');

      const int maxConnectAttempts = 3;
      Socket? socket;
      for (var attempt = 1; attempt <= maxConnectAttempts; attempt++) {
        try {
          socket = await Socket.connect(
            InternetAddress(
              '/tmp/msi_dsp.sock',
              type: InternetAddressType.unix,
            ),
            0,
          ).timeout(const Duration(seconds: 3));
          break;
        } catch (e) {
          debugPrint('Socket connect attempt $attempt failed: $e');
          if (attempt == maxConnectAttempts) rethrow;
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (socket == null) {
        throw SocketException('Could not connect to DSP socket');
      }

      socket.write('LOAD:$profile');
      await socket.flush();

      final completer = Completer<List<int>>();
      final bytes = <int>[];

      socket.listen(
        (data) {
          bytes.addAll(data);
          try {
            final s = utf8.decode(bytes);
            if (s.trim().startsWith('{') && s.trim().endsWith('}')) {
              if (!completer.isCompleted) completer.complete(bytes);
            }
          } catch (_) {
            // ignore decode errors until we have a full payload
          }
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(bytes);
        },
        onError: (err) {
          if (!completer.isCompleted) completer.completeError(err);
        },
      );

      final response = await completer.future.timeout(
        const Duration(seconds: 8),
      );
      socket.close();

      if (response.isNotEmpty) {
        final jsonStr = utf8.decode(response);
        if (jsonStr.startsWith('{')) {
          final map = json.decode(jsonStr);
          // Only update internal tracking state; bloc owns the authoritative values.
          _compressor = map['compressor'] ?? false;
          _surround = map['surround'] ?? false;
          debugPrint(
            'Loaded profile $profile: bass=${map['bass']}, treble=${map['treble']}, voice=${map['voice']}',
          );
        }
      }
      // DSP already applied settings via LOAD command on its side — no _updateDsp() needed.
      return true;
    } catch (e) {
      debugPrint('Failed to load sound profile: $e');
      await _updateDsp();
      return false;
    }
  }

  @override
  Future<bool> setSoundEQ(List<double> gains) async {
    _eqGains = gains;
    await _updateDspRealtime();
    return true;
  }

  @override
  Future<bool> setAiLanPriority(bool enable) async {
    try {
      debugPrint('Setting AI LAN priority: $enable');
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
  Future<bool> setSoundEnhancement(String enhancement, bool enable) async {
    if (enhancement == 'smartVolume') _compressor = enable;
    if (enhancement == 'virtualSurround') _surround = enable;
    await _updateDsp();
    try {
      debugPrint('Setting sound enhancement $enhancement: $enable');
      final result = await _channel.invokeMethod<bool>('setSoundEnhancement', {
        'enhancement': enhancement,
        'enable': enable,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to set sound enhancement: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> setDspProfile(AudioProfile profile) async {
    try {
      final socket = await Socket.connect(
        InternetAddress('/tmp/msi_dsp.sock', type: InternetAddressType.unix),
        0,
      );

      // Override buffer size based on current system performance mode
      final bufferSize = _getBufferSizeForMode(_currentMode);
      final profileWithBuffer = AudioProfile(
        name: profile.name,
        bass: profile.bass,
        treble: profile.treble,
        voice: profile.voice,
        eqGains: profile.eqGains,
        compressor: profile.compressor,
        surround: profile.surround,
        volume: profile.volume,
        bufferSize: bufferSize,
      );

      final json = profileWithBuffer.toJson();
      socket.write(jsonEncode(json));
      await socket.flush();
      final response = await socket.first;
      socket.close();
      return utf8.decode(response) == 'OK';
    } catch (e) {
      debugPrint('Failed to set DSP profile via Unix socket: $e');
      return false;
    }
  }

  @override
  Future<bool> enableDsp() async {
    try {
      final socket = await Socket.connect(
        InternetAddress('/tmp/msi_dsp.sock', type: InternetAddressType.unix),
        0,
      );
      socket.write('ENABLE');
      await socket.flush();
      final response = await socket.first;
      socket.close();
      return utf8.decode(response) == 'OK';
    } catch (e) {
      debugPrint('Failed to enable DSP via Unix socket: $e');
      return false;
    }
  }

  @override
  Future<bool> disableDsp() async {
    try {
      final socket = await Socket.connect(
        InternetAddress('/tmp/msi_dsp.sock', type: InternetAddressType.unix),
        0,
      );
      socket.write('DISABLE');
      await socket.flush();
      final response = await socket.first;
      socket.close();
      return utf8.decode(response) == 'OK';
    } catch (e) {
      debugPrint('Failed to disable DSP via Unix socket: $e');
      return false;
    }
  }

  @override
  Future<bool> getDspStatus() async {
    try {
      final socket = await Socket.connect(
        InternetAddress('/tmp/msi_dsp.sock', type: InternetAddressType.unix),
        0,
      );
      socket.write('STATUS');
      await socket.flush();
      final response = await socket.first;
      socket.close();
      return utf8.decode(response).trim() == 'enabled';
    } catch (e) {
      debugPrint('Failed to get DSP status via Unix socket: $e');
      return false;
    }
  }

  @override
  Future<bool> setDspBass(double gain) async {
    return setSoundEffectGain('bass', gain);
  }

  @override
  Future<bool> setDspTreble(double gain) async {
    return setSoundEffectGain('treble', gain);
  }

  @override
  Future<bool> setDspCompressor(bool enable) async {
    return setSoundEnhancement('smartVolume', enable);
  }

  @override
  Future<void> setSoundSampleRate(int hertz) async {
    try {
      debugPrint('Setting sound sample rate: $hertz Hz');
      await _channel.invokeMethod('setSoundSampleRate', {'hertz': hertz});
    } on PlatformException catch (e) {
      debugPrint('Failed to set sound sample rate: ${e.message}');
    }
  }

  @override
  Future<void> setSoundStereoWidth(double width) async {
    try {
      debugPrint('Setting sound stereo width: $width');
      await _channel.invokeMethod('setSoundStereoWidth', {'width': width});
    } on PlatformException catch (e) {
      debugPrint('Failed to set sound stereo width: ${e.message}');
    }
  }

  @override
  Future<void> setSoundVolumeBoost(double boost) async {
    _volume = boost;
    try {
      final percent = (boost * 100).round();
      final result = await Process.run('pactl', [
        'set-volume',
        '@DEFAULT_SINK@',
        '$percent%',
      ], runInShell: true);
      debugPrint('Volume set to $percent%: ${result.stdout}');

      await _updateDspRealtime();
    } catch (e) {
      debugPrint('Failed to set volume: $e');
    }
  }

  Future<double> getSystemVolume() async {
    try {
      final result = await Process.run('pactl', [
        'get-volume',
        '@DEFAULT_SINK@',
      ], runInShell: true);
      final output = result.stdout.toString();
      final match = RegExp(r'(\d+)%').firstMatch(output);
      if (match != null) {
        return int.parse(match.group(1)!) / 100.0;
      }
    } catch (e) {
      debugPrint('Failed to get volume: $e');
    }
    return 1.0;
  }

  @override
  void setActiveProfileName(String profile) {
    _soundProfileName = profile;
  }

  @override
  Future<bool> setSoundEffectGain(String effect, double gain) async {
    if (effect == 'bass') _bassGain = gain;
    if (effect == 'treble') _trebleGain = gain;
    if (effect == 'voice') _voiceGain = gain;
    await _updateDspRealtime();
    return true;
  }

  @override
  Future<void> applyCurrentProfile() async {
    debugPrint('Repository: Applying current profile settings');
    await _updateDspRealtime();
  }

  @override
  Future<bool> setGpuMode(GpuMode mode) async {
    try {
      debugPrint('Setting GPU mode: ${mode.displayName}');
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
  void dispose() {
    _pollingTimer?.cancel();
  }
}
