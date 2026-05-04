// 测试: KoiPrinterProfile, KoiPrinterProfileDb, KoiTemplateEngine 标签展开
import 'package:flutter_test/flutter_test.dart';
import 'package:koi_printer/koi_printer.dart';

void main() {
  // ════════════════════════════════════════════════════════════
  //  KoiPrinterProfile
  // ════════════════════════════════════════════════════════════

  group('KoiPrinterProfile', () {
    test('fromJson parses full profile', () {
      final json = {
        'id': 'xp-423',
        'name': '芯烨 XT-423',
        'vendor': 'Xprinter',
        'protocols': ['escPos', 'tspl'],
        'connections': ['ble', 'classicBluetooth'],
        'paperWidthMm': 80,
        'dotsPerLine': 576,
        'dpi': 203,
        'supportsCut': true,
        'supportsQrCode': true,
        'bestQrStrategy': 'img',
        'supportsChinese': true,
        'characteristicFilter': '49535343-8841',
        'maxMtu': 512,
        'delayProfile': 'table2021',
      };
      final profile = KoiPrinterProfile.fromJson(json);
      expect(profile.id, 'xp-423');
      expect(profile.name, '芯烨 XT-423');
      expect(profile.vendor, 'Xprinter');
      expect(profile.protocols.length, 2);
      expect(profile.protocols[0], KoiCommandProtocol.escPos);
      expect(profile.protocols[1], KoiCommandProtocol.tspl);
      expect(profile.connections[0], KoiConnectionType.ble);
      expect(profile.bestQrStrategy, KoiQrRenderStrategy.img);
      expect(profile.characteristicFilter, '49535343-8841');
      expect(profile.maxMtu, 512);
      expect(profile.delayProfile, KoiDelayProfile.table2021);
    });

    test('fromJson with missing optional fields uses defaults', () {
      final json = {'id': 'simple', 'name': 'Simple Printer'};
      final profile = KoiPrinterProfile.fromJson(json);
      expect(profile.vendor, '');
      expect(profile.protocols, isEmpty);
      expect(profile.connections, isEmpty);
      expect(profile.paperWidthMm, 80);
      expect(profile.dotsPerLine, 576);
      expect(profile.dpi, 203);
      expect(profile.supportsCut, true);
      expect(profile.supportsQrCode, true);
      expect(profile.bestQrStrategy, KoiQrRenderStrategy.normal);
      expect(profile.supportsChinese, true);
      expect(profile.characteristicFilter, isNull);
      expect(profile.maxMtu, isNull);
      expect(profile.delayProfile, KoiDelayProfile.normal);
    });

    test('fromJson with unknown strategy/delay falls back to defaults', () {
      final json = {
        'id': 'x',
        'name': 'X',
        'bestQrStrategy': 'unknownStrategy',
        'delayProfile': 'unknownDelay',
      };
      final profile = KoiPrinterProfile.fromJson(json);
      expect(profile.bestQrStrategy, KoiQrRenderStrategy.normal);
      expect(profile.delayProfile, KoiDelayProfile.normal);
    });

    test('fromJson with null strategy/delay falls back to defaults', () {
      final json = {
        'id': 'x',
        'name': 'X',
        'bestQrStrategy': null,
        'delayProfile': null,
      };
      final profile = KoiPrinterProfile.fromJson(json);
      expect(profile.bestQrStrategy, KoiQrRenderStrategy.normal);
      expect(profile.delayProfile, KoiDelayProfile.normal);
    });

    test('toJson serializes all fields', () {
      const profile = KoiPrinterProfile(
        id: 'test-1',
        name: 'Test Printer',
        vendor: 'TestVendor',
        protocols: [KoiCommandProtocol.escPos],
        connections: [KoiConnectionType.ble],
        paperWidthMm: 58,
        dotsPerLine: 384,
        dpi: 180,
        supportsCut: false,
        supportsQrCode: false,
        bestQrStrategy: KoiQrRenderStrategy.img,
        supportsChinese: false,
        characteristicFilter: 'abc-123',
        maxMtu: 256,
        delayProfile: KoiDelayProfile.table2018,
      );
      final json = profile.toJson();
      expect(json['id'], 'test-1');
      expect(json['vendor'], 'TestVendor');
      expect(json['protocols'], ['escPos']);
      expect(json['connections'], ['ble']);
      expect(json['paperWidthMm'], 58);
      expect(json['supportsCut'], false);
      expect(json['bestQrStrategy'], 'img');
      expect(json['characteristicFilter'], 'abc-123');
      expect(json['maxMtu'], 256);
      expect(json['delayProfile'], 'table2018');
    });

    test('toJson omits null characteristicFilter and maxMtu', () {
      const profile = KoiPrinterProfile(
        id: 'x',
        name: 'X',
        vendor: '',
        protocols: [],
        connections: [],
      );
      final json = profile.toJson();
      expect(json.containsKey('characteristicFilter'), false);
      expect(json.containsKey('maxMtu'), false);
    });

    test('toJson and fromJson roundtrip', () {
      const original = KoiPrinterProfile(
        id: 'round',
        name: 'Roundtrip',
        vendor: 'V',
        protocols: [KoiCommandProtocol.cpcl],
        connections: [KoiConnectionType.network],
        bestQrStrategy: KoiQrRenderStrategy.img,
        maxMtu: 100,
        characteristicFilter: 'aaa',
      );
      final restored = KoiPrinterProfile.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.protocols, original.protocols);
      expect(restored.connections, original.connections);
      expect(restored.bestQrStrategy, original.bestQrStrategy);
      expect(restored.maxMtu, original.maxMtu);
      expect(restored.characteristicFilter, original.characteristicFilter);
    });
  });

  // ════════════════════════════════════════════════════════════
  //  KoiPrinterProfileDb
  // ════════════════════════════════════════════════════════════

  group('KoiPrinterProfileDb', () {
    test('loadFromJsonString populates profiles', () {
      final db =
          KoiPrinterProfileDb()..loadFromJsonString('''
      [
        {"id": "p1", "name": "Printer One", "vendor": "V1", "protocols": ["escPos"], "connections": ["ble"]},
        {"id": "p2", "name": "Printer Two", "vendor": "V2", "protocols": ["tspl"], "connections": ["network"]}
      ]
      ''');
      expect(db.profiles.length, 2);
    });

    test('loadFromJsonString replaces previous data', () {
      final db =
          KoiPrinterProfileDb()
            ..loadFromJsonString('[{"id": "p1", "name": "First"}]');
      expect(db.profiles.length, 1);

      db.loadFromJsonString(
        '[{"id": "p2", "name": "Second"}, {"id": "p3", "name": "Third"}]',
      );
      expect(db.profiles.length, 2);
      expect(db.profiles[0].id, 'p2');
    });

    test('addProfile appends to list', () {
      final db =
          KoiPrinterProfileDb()..addProfile(
            const KoiPrinterProfile(
              id: 'custom-1',
              name: 'Custom',
              vendor: 'Me',
              protocols: [KoiCommandProtocol.escPos],
              connections: [KoiConnectionType.network],
            ),
          );
      expect(db.profiles.length, 1);
      expect(db.profiles.first.id, 'custom-1');
    });

    test('findById returns matching profile', () {
      final db =
          KoiPrinterProfileDb()
            ..loadFromJsonString('[{"id": "abc", "name": "ABC Printer"}]');
      expect(db.findById('abc'), isNotNull);
      expect(db.findById('abc')!.name, 'ABC Printer');
    });

    test('findById returns null for non-existent id', () {
      final db =
          KoiPrinterProfileDb()
            ..loadFromJsonString('[{"id": "abc", "name": "ABC"}]');
      expect(db.findById('xyz'), isNull);
    });

    test('findByName matches case-insensitively', () {
      final db =
          KoiPrinterProfileDb()
            ..loadFromJsonString('[{"id": "xp", "name": "芯烨 XT-423"}]');
      expect(db.findByName('xt-423'), isNotNull);
      expect(db.findByName('芯烨'), isNotNull);
    });

    test('findByName returns null for no match', () {
      final db =
          KoiPrinterProfileDb()
            ..loadFromJsonString('[{"id": "xp", "name": "ABC"}]');
      expect(db.findByName('XYZ'), isNull);
    });

    test('findByCharacteristic matches filter UUID', () {
      final db =
          KoiPrinterProfileDb()..addProfile(
            const KoiPrinterProfile(
              id: 'ble-1',
              name: 'BLE Printer',
              vendor: 'V',
              protocols: [KoiCommandProtocol.escPos],
              connections: [KoiConnectionType.ble],
              characteristicFilter: '49535343-8841',
            ),
          );
      expect(db.findByCharacteristic('SERVICE-49535343-8841-CHAR'), isNotNull);
    });

    test('findByCharacteristic returns null when no filter', () {
      final db =
          KoiPrinterProfileDb()..addProfile(
            const KoiPrinterProfile(
              id: 'no-filter',
              name: 'No Filter',
              vendor: 'V',
              protocols: [],
              connections: [],
            ),
          );
      expect(db.findByCharacteristic('any-uuid'), isNull);
    });

    test('findByCharacteristic returns null for no match', () {
      final db =
          KoiPrinterProfileDb()..addProfile(
            const KoiPrinterProfile(
              id: 'ble-1',
              name: 'BLE',
              vendor: 'V',
              protocols: [],
              connections: [],
              characteristicFilter: 'AAAA',
            ),
          );
      expect(db.findByCharacteristic('BBBB'), isNull);
    });
  });

  // ════════════════════════════════════════════════════════════
  //  KoiTemplateEngine — 标签展开 + barcode 替换
  // ════════════════════════════════════════════════════════════

  group('KoiTemplateEngine label expansion', () {
    const engine = KoiTemplateEngine();

    test('expandLabel with ForEach element', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelForEachElement(
            listKey: 'items',
            templates: [KoiPositionedTextElement(x: 0, y: 0, text: '{{name}}')],
          ),
        ],
      );

      final result = engine.expandLabel(doc, {
        'items': [
          {'name': 'Product-A'},
          {'name': 'Product-B'},
        ],
      });

      expect(result.elements.length, 2);
      final t1 = result.elements[0] as KoiPositionedTextElement;
      expect(t1.text, 'Product-A');
      final t2 = result.elements[1] as KoiPositionedTextElement;
      expect(t2.text, 'Product-B');
    });

    test('expandLabel with barcode substitution', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelForEachElement(
            listKey: 'items',
            templates: [
              KoiPositionedBarcodeElement(
                x: 10,
                y: 10,
                data: '{{barcode}}',
                height: 50,
              ),
            ],
          ),
        ],
      );

      final result = engine.expandLabel(doc, {
        'items': [
          {'barcode': 'BC-001'},
        ],
      });

      expect(result.elements.length, 1);
      final barcode = result.elements[0] as KoiPositionedBarcodeElement;
      expect(barcode.data, 'BC-001');
    });

    test('expandLabel with QR code substitution', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelForEachElement(
            listKey: 'items',
            templates: [
              KoiPositionedQrCodeElement(
                x: 0,
                y: 0,
                data: '{{url}}',
                cellSize: 4,
              ),
            ],
          ),
        ],
      );

      final result = engine.expandLabel(doc, {
        'items': [
          {'url': 'https://example.com'},
        ],
      });

      expect(result.elements.length, 1);
      final qr = result.elements[0] as KoiPositionedQrCodeElement;
      expect(qr.data, 'https://example.com');
    });

    test('expandLabel preserves non-ForEach elements', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelSetupElement(widthMm: 60, heightMm: 40),
          KoiLabelForEachElement(
            listKey: 'items',
            templates: [KoiPositionedTextElement(x: 0, y: 0, text: '{{name}}')],
          ),
        ],
      );

      final result = engine.expandLabel(doc, {
        'items': [
          {'name': 'X'},
        ],
      });

      expect(result.elements.length, 2);
      expect(result.elements[0], isA<KoiLabelSetupElement>());
      expect(result.elements[1], isA<KoiPositionedTextElement>());
    });

    test('expandLabel with empty collection returns empty', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelForEachElement(
            listKey: 'items',
            templates: [KoiPositionedTextElement(x: 0, y: 0, text: '{{name}}')],
          ),
        ],
      );

      final result = engine.expandLabel(doc, {'items': <dynamic>[]});
      expect(result.elements, isEmpty);
    });

    test('expandLabel with missing key returns empty', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelForEachElement(
            listKey: 'missing',
            templates: [KoiPositionedTextElement(x: 0, y: 0, text: '{{name}}')],
          ),
        ],
      );

      final result = engine.expandLabel(doc, {});
      expect(result.elements, isEmpty);
    });

    test('expandLabel non-text elements pass through ForEach unchanged', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelForEachElement(
            listKey: 'items',
            templates: [
              KoiLabelBoxElement(
                x: 0,
                y: 0,
                width: 10,
                height: 10,
                thickness: 1,
              ),
            ],
          ),
        ],
      );

      final result = engine.expandLabel(doc, {
        'items': [
          {'name': 'X'},
        ],
      });

      expect(result.elements.length, 1);
      expect(result.elements[0], isA<KoiLabelBoxElement>());
    });
  });

  // ════════════════════════════════════════════════════════════
  //  KoiTemplateEngine ticket — barcode substitution
  // ════════════════════════════════════════════════════════════

  group('KoiTemplateEngine ticket barcode/non-text', () {
    const engine = KoiTemplateEngine();

    test('substitutes barcode data in ticket forEach', () {
      const doc = KoiTicketDocument(
        elements: [
          KoiTicketForEachElement(
            listKey: 'items',
            templates: [
              KoiBarcodeElement(data: '{{code}}'),
            ],
          ),
        ],
      );

      final result = engine.expandTicket(doc, {
        'items': [
          {'code': 'BARCODE-123'},
        ],
      });

      final barcode = result.elements[0] as KoiBarcodeElement;
      expect(barcode.data, 'BARCODE-123');
    });

    test('non-text elements pass through unchanged in ticket forEach', () {
      const doc = KoiTicketDocument(
        elements: [
          KoiTicketForEachElement(
            listKey: 'items',
            templates: [
              KoiDividerElement(char: '='),
              KoiSpacerElement(lines: 2),
              KoiCutElement(),
            ],
          ),
        ],
      );

      final result = engine.expandTicket(doc, {
        'items': [
          {'name': 'X'},
        ],
      });

      // 3 non-text elements should pass through unchanged
      expect(result.elements.length, 3);
      expect(result.elements[0], isA<KoiDividerElement>());
      expect(result.elements[1], isA<KoiSpacerElement>());
      expect(result.elements[2], isA<KoiCutElement>());
    });
  });

  // ════════════════════════════════════════════════════════════
  //  KoiPrintConfig — copyWith 所有字段
  // ════════════════════════════════════════════════════════════

  group('KoiPrintConfig copyWith all fields', () {
    test('copyWith overrides all fields', () {
      const original = KoiPrintConfig();
      final copy = original.copyWith(
        deviceRole: KoiDeviceRole.labelDesktop,
        paperSize: KoiPaperSize.mm58,
        renderer: const KoiRendererConfig(protocol: KoiCommandProtocol.tspl),
        cutBehavior: KoiCutBehavior.noCut,
        printStyle: KoiPrintStyle.large,
        labelStyle: KoiLabelStyle.style3,
        delayProfile: KoiDelayProfile.table2018,
        stubType: KoiStubType.none,
        headerEmptyLines: 10,
        copies: 5,
      );
      expect(copy.deviceRole, KoiDeviceRole.labelDesktop);
      expect(copy.paperSize, KoiPaperSize.mm58);
      expect(copy.renderer.protocol, KoiCommandProtocol.tspl);
      expect(copy.cutBehavior, KoiCutBehavior.noCut);
      expect(copy.printStyle, KoiPrintStyle.large);
      expect(copy.labelStyle, KoiLabelStyle.style3);
      expect(copy.delayProfile, KoiDelayProfile.table2018);
      expect(copy.stubType, KoiStubType.none);
      expect(copy.headerEmptyLines, 10);
      expect(copy.copies, 5);
    });

    test('KoiRendererConfig copyWith qrStrategy only', () {
      const config = KoiRendererConfig();
      final copy = config.copyWith(qrStrategy: KoiQrRenderStrategy.img);
      expect(copy.protocol, KoiCommandProtocol.escPos); // 不变
      expect(copy.qrStrategy, KoiQrRenderStrategy.img);
    });
  });

  // ════════════════════════════════════════════════════════════
  //  KoiPrinterFactory — QR strategy 传参
  // ════════════════════════════════════════════════════════════

  group('KoiPrinterFactory qrStrategy', () {
    test('createRenderer passes qrStrategy to EscPosRenderer', () {
      final renderer = KoiPrinterFactory.createRenderer(
        KoiCommandProtocol.escPos,
        qrStrategy: KoiQrRenderStrategy.img,
      );
      expect(renderer, isA<KoiEscPosRenderer>());
    });
  });
}
