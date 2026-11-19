import 'package:flutter_test/flutter_test.dart';
import 'package:msi_controller/services/persistence_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PersistenceService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = PersistenceService();
    await service.ensureInitialized();
  });

  group('Theme persistence', () {
    test('default theme is dark', () {
      expect(service.loadThemeMode(), 'dark');
    });

    test('save and load theme mode', () async {
      await service.saveThemeMode('light');
      expect(service.loadThemeMode(), 'light');

      await service.saveThemeMode('dark');
      expect(service.loadThemeMode(), 'dark');
    });
  });

  group('Smart Priority persistence', () {
    test('defaults are correct', () {
      expect(service.loadSmartPriorityMode(), 'smartPriority');
      expect(service.loadSmartPriorityEnabled(), true);
      expect(service.loadSmartPriorityList(), isEmpty);
    });

    test('save and load smart priority', () async {
      await service.saveSmartPriority(
        mode: 'gameBoost',
        enabled: false,
        priorityAppNames: ['Photoshop', 'Blender'],
      );
      expect(service.loadSmartPriorityMode(), 'gameBoost');
      expect(service.loadSmartPriorityEnabled(), false);
      expect(service.loadSmartPriorityList(), ['Photoshop', 'Blender']);
    });
  });

  group('Mystic Light persistence', () {
    test('defaults are correct', () {
      expect(service.loadMysticEffect(), 'static');
      expect(service.loadMysticColor(), 0xFFEB1D24);
      expect(service.loadMysticBrightness(), 1.0);
      expect(service.loadMysticZone(), 0);
    });

    test('save and load mystic light settings', () async {
      await service.saveMysticLight(
        effect: 'breathing',
        color: 0xFF00FF00,
        brightness: 0.5,
        zone: 2,
      );
      expect(service.loadMysticEffect(), 'breathing');
      expect(service.loadMysticColor(), 0xFF00FF00);
      expect(service.loadMysticBrightness(), 0.5);
      expect(service.loadMysticZone(), 2);
    });
  });

  group('LAN Manager persistence', () {
    test('default is false', () {
      expect(service.loadLanAiPriority(), false);
    });

    test('save and load LAN AI priority', () async {
      await service.saveLanAiPriority(true);
      expect(service.loadLanAiPriority(), true);
    });
  });

  group('Keyboard backlight persistence', () {
    test('defaults are correct', () {
      expect(service.loadKeyboardBrightness(), 3);
      expect(service.loadKeyboardMode(), 0);
    });

    test('save and load keyboard settings', () async {
      await service.saveKeyboardBacklight(brightness: 2, mode: 1);
      expect(service.loadKeyboardBrightness(), 2);
      expect(service.loadKeyboardMode(), 1);
    });
  });

  group('Notification read state', () {
    test('default is empty set', () {
      expect(service.loadReadIds(), isEmpty);
    });

    test('save and load read IDs', () async {
      await service.saveReadIds({'notif_1', 'notif_2'});
      final ids = service.loadReadIds();
      expect(ids, containsAll(['notif_1', 'notif_2']));
    });
  });
}
