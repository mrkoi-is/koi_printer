// 测试: KoiPrinterStorage, KoiDeviceInfo, KoiUserPreferences
import 'package:flutter_test/flutter_test.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // ════════════════════════════════════════════════════════════
  //  KoiDeviceInfo
  // ════════════════════════════════════════════════════════════

  group('KoiDeviceInfo', () {
    test('toMap returns correct map', () {
      const device = KoiDeviceInfo(
        name: 'Printer-1',
        address: 'AA:BB:CC:DD:EE:FF',
        connectionType: KoiConnectionType.ble,
      );
      final map = device.toMap();
      expect(map['name'], 'Printer-1');
      expect(map['address'], 'AA:BB:CC:DD:EE:FF');
      expect(map['connectionType'], KoiConnectionType.ble.index);
    });

    test('fromMap restores device', () {
      final map = {
        'name': 'Printer-2',
        'address': '192.168.1.1',
        'connectionType': KoiConnectionType.network.index,
      };
      final device = KoiDeviceInfo.fromMap(map);
      expect(device.name, 'Printer-2');
      expect(device.address, '192.168.1.1');
      expect(device.connectionType, KoiConnectionType.network);
    });

    test('fromMap handles null connectionType', () {
      final map = {'name': 'Printer', 'address': 'addr'};
      final device = KoiDeviceInfo.fromMap(map);
      expect(device.connectionType, KoiConnectionType.ble); // index 0
    });

    test('toJson and fromJson roundtrip', () {
      const original = KoiDeviceInfo(
        name: 'Label Printer',
        address: '11:22:33:44',
        connectionType: KoiConnectionType.classicBluetooth,
      );
      final json = original.toJson();
      final restored = KoiDeviceInfo.fromJson(json);
      expect(restored.name, original.name);
      expect(restored.address, original.address);
      expect(restored.connectionType, original.connectionType);
    });
  });

  // ════════════════════════════════════════════════════════════
  //  KoiPrinterStorage
  // ════════════════════════════════════════════════════════════

  group('KoiPrinterStorage', () {
    late SharedPreferences prefs;
    late KoiPrinterStorage storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = KoiPrinterStorage(prefs);
    });

    test('getTicketPrinter returns null when not saved', () {
      expect(storage.getTicketPrinter(), isNull);
    });

    test('saveTicketPrinter and getTicketPrinter roundtrip', () async {
      const device = KoiDeviceInfo(
        name: 'Ticket-1',
        address: 'AA:BB',
        connectionType: KoiConnectionType.ble,
      );
      await storage.saveTicketPrinter(device);
      final loaded = storage.getTicketPrinter();
      expect(loaded, isNotNull);
      expect(loaded!.name, 'Ticket-1');
      expect(loaded.connectionType, KoiConnectionType.ble);
    });

    test('saveTicketPrinter with null removes entry', () async {
      const device = KoiDeviceInfo(
        name: 'Ticket-1',
        address: 'AA:BB',
        connectionType: KoiConnectionType.ble,
      );
      await storage.saveTicketPrinter(device);
      expect(storage.getTicketPrinter(), isNotNull);
      await storage.saveTicketPrinter(null);
      expect(storage.getTicketPrinter(), isNull);
    });

    test('getTicketPrinter handles corrupt JSON', () async {
      await prefs.setString('koi_bind_ticket_printer', 'not-valid-json');
      final loaded = storage.getTicketPrinter();
      expect(loaded, isNull);
    });

    test('getLabelPrinter returns null when not saved', () {
      expect(storage.getLabelPrinter(), isNull);
    });

    test('saveLabelPrinter and getLabelPrinter roundtrip', () async {
      const device = KoiDeviceInfo(
        name: 'Label-1',
        address: '192.168.1.100',
        connectionType: KoiConnectionType.network,
      );
      await storage.saveLabelPrinter(device);
      final loaded = storage.getLabelPrinter();
      expect(loaded, isNotNull);
      expect(loaded!.name, 'Label-1');
      expect(loaded.connectionType, KoiConnectionType.network);
    });

    test('saveLabelPrinter with null removes entry', () async {
      const device = KoiDeviceInfo(
        name: 'Label-1',
        address: '192.168.1.100',
        connectionType: KoiConnectionType.network,
      );
      await storage.saveLabelPrinter(device);
      expect(storage.getLabelPrinter(), isNotNull);
      await storage.saveLabelPrinter(null);
      expect(storage.getLabelPrinter(), isNull);
    });

    test('getLabelPrinter handles corrupt JSON', () async {
      await prefs.setString('koi_bind_label_printer', '{bad json');
      final loaded = storage.getLabelPrinter();
      expect(loaded, isNull);
    });
  });

  // ════════════════════════════════════════════════════════════
  //  KoiUserPreferences
  // ════════════════════════════════════════════════════════════

  group('KoiUserPreferences', () {
    late SharedPreferences prefs;
    late KoiUserPreferences userPrefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      userPrefs = KoiUserPreferences(prefs);
    });

    // ── 切纸偏好 ──

    test('isCutEnabled returns defaults', () {
      expect(userPrefs.isCutEnabled(KoiCutBehavior.cutPerCopy), true);
      expect(userPrefs.isCutEnabled(KoiCutBehavior.cutAtEnd), true);
      expect(userPrefs.isCutEnabled(KoiCutBehavior.noCut), false);
    });

    test('setCutEnabled persists value', () async {
      await userPrefs.setCutEnabled(
        behavior: KoiCutBehavior.cutPerCopy,
        enabled: false,
      );
      expect(userPrefs.isCutEnabled(KoiCutBehavior.cutPerCopy), false);

      await userPrefs.setCutEnabled(
        behavior: KoiCutBehavior.noCut,
        enabled: true,
      );
      expect(userPrefs.isCutEnabled(KoiCutBehavior.noCut), true);
    });

    // ── 存根类型 ──

    test('stubType defaults to withStub', () {
      expect(userPrefs.stubType, KoiStubType.withStub);
    });

    test('setStubType persists value', () async {
      await userPrefs.setStubType(KoiStubType.none);
      expect(userPrefs.stubType, KoiStubType.none);
    });

    test('switchStubType cycles through enum values', () async {
      // withStub(index=1) → none(index=0)
      await userPrefs.switchStubType();
      expect(userPrefs.stubType, KoiStubType.none);
    });

    test('stubType returns default for out-of-range index', () async {
      await prefs.setInt('koi_stub_type', 999);
      expect(userPrefs.stubType, KoiStubType.withStub);
    });

    // ── 打印样式 ──

    test('printStyle defaults to normal', () {
      expect(userPrefs.printStyle, KoiPrintStyle.normal);
    });

    test('switchPrintStyle cycles through enum values', () async {
      await userPrefs.switchPrintStyle();
      expect(userPrefs.printStyle, KoiPrintStyle.values[1]);
    });

    test('printStyle returns default for out-of-range index', () async {
      await prefs.setInt('koi_print_style', 999);
      expect(userPrefs.printStyle, KoiPrintStyle.normal);
    });

    // ── 标签样式 ──

    test('labelStyle defaults to style1', () {
      expect(userPrefs.labelStyle, KoiLabelStyle.style1);
    });

    test('switchLabelStyle cycles through enum values', () async {
      await userPrefs.switchLabelStyle();
      expect(userPrefs.labelStyle, KoiLabelStyle.values[1]);
    });

    test('labelStyle returns default for out-of-range index', () async {
      await prefs.setInt('koi_label_style', 999);
      expect(userPrefs.labelStyle, KoiLabelStyle.style1);
    });

    // ── 收货联顶部空行 ──

    test('headerEmptyLines defaults to 0', () {
      expect(userPrefs.headerEmptyLines, 0);
    });

    test('setHeaderEmptyLines persists value', () async {
      await userPrefs.setHeaderEmptyLines(5);
      expect(userPrefs.headerEmptyLines, 5);
    });
  });
}
