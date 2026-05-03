import 'package:flutter_test/flutter_test.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('KoiTemplateEngine', () {
    const engine = KoiTemplateEngine();

    test('expands ForEach element with data', () {
      const doc = KoiTicketDocument(
        elements: [
          KoiTextElement(text: '--- 订单 ---'),
          KoiTicketForEachElement(
            listKey: 'items',
            templates: [
              KoiTextRowElement(
                columns: [
                  KoiTextColumn(text: '{{name}}', ratio: 6),
                  KoiTextColumn(
                    text: '{{price}}',
                    ratio: 3,
                    align: KoiTextAlign.right,
                  ),
                  KoiTextColumn(
                    text: '{{qty}}',
                    ratio: 3,
                    align: KoiTextAlign.right,
                  ),
                ],
              ),
            ],
          ),
          const KoiDividerElement(),
        ],
      );

      final data = {
        'items': [
          {'name': '商品A', 'price': '10.00', 'qty': '2'},
          {'name': '商品B', 'price': '20.00', 'qty': '1'},
        ],
      };

      final expanded = engine.expandTicket(doc, data);

      // 原始: 3 elements (text + forEach + divider)
      // 展开: 4 elements (text + row*2 + divider)
      expect(expanded.elements.length, 4);
      expect(expanded.elements[0], isA<KoiTextElement>());
      expect(expanded.elements[1], isA<KoiTextRowElement>());
      expect(expanded.elements[2], isA<KoiTextRowElement>());
      expect(expanded.elements[3], isA<KoiDividerElement>());

      // 验证变量替换
      final row1 = expanded.elements[1] as KoiTextRowElement;
      expect(row1.columns[0].text, '商品A');
      expect(row1.columns[1].text, '10.00');

      final row2 = expanded.elements[2] as KoiTextRowElement;
      expect(row2.columns[0].text, '商品B');
    });

    test('handles empty collection gracefully', () {
      const doc = KoiTicketDocument(
        elements: [
          KoiTicketForEachElement(
            listKey: 'items',
            templates: [KoiTextElement(text: '{{name}}')],
          ),
        ],
      );

      final expanded = engine.expandTicket(doc, {'items': []});
      expect(expanded.elements, isEmpty);
    });

    test('handles missing collection key', () {
      const doc = KoiTicketDocument(
        elements: [
          KoiTicketForEachElement(
            listKey: 'missing',
            templates: [KoiTextElement(text: '{{name}}')],
          ),
        ],
      );

      final expanded = engine.expandTicket(doc, {});
      expect(expanded.elements, isEmpty);
    });

    test('substitutes text in KoiTextElement', () {
      const doc = KoiTicketDocument(
        elements: [
          KoiTicketForEachElement(
            listKey: 'data',
            templates: [KoiTextElement(text: '订单号: {{orderId}}', bold: true)],
          ),
        ],
      );

      final expanded = engine.expandTicket(doc, {
        'data': [
          {'orderId': 'ORD-001'},
        ],
      });

      final text = expanded.elements.first as KoiTextElement;
      expect(text.text, '订单号: ORD-001');
      expect(text.bold, true); // 样式保留
    });

    test('substitutes data in QR code element', () {
      const doc = KoiTicketDocument(
        elements: [
          KoiTicketForEachElement(
            listKey: 'data',
            templates: [KoiQrCodeElement(data: '{{url}}')],
          ),
        ],
      );

      final expanded = engine.expandTicket(doc, {
        'data': [
          {'url': 'https://example.com/order/123'},
        ],
      });

      final qr = expanded.elements.first as KoiQrCodeElement;
      expect(qr.data, 'https://example.com/order/123');
    });

    test('multiple templates per iteration', () {
      const doc = KoiTicketDocument(
        elements: [
          KoiTicketForEachElement(
            listKey: 'items',
            templates: [
              KoiTextElement(text: '{{name}}', bold: true),
              KoiTextRowElement(
                columns: [
                  KoiTextColumn(text: '  单价: {{price}}', ratio: 6),
                  KoiTextColumn(
                    text: '×{{qty}}',
                    ratio: 6,
                    align: KoiTextAlign.right,
                  ),
                ],
              ),
              KoiDividerElement(char: '.'),
            ],
          ),
        ],
      );

      final expanded = engine.expandTicket(doc, {
        'items': [
          {'name': 'A', 'price': '10', 'qty': '2'},
        ],
      });

      // 1 item × 3 templates = 3 elements
      expect(expanded.elements.length, 3);
      expect(expanded.elements[0], isA<KoiTextElement>());
      expect(expanded.elements[1], isA<KoiTextRowElement>());
      expect(expanded.elements[2], isA<KoiDividerElement>());

      final text = expanded.elements[0] as KoiTextElement;
      expect(text.text, 'A');
      expect(text.bold, true);
    });
  });

  group('KoiPrinterFactory', () {
    test('creates EscPosRenderer for escPos protocol', () {
      final renderer = KoiPrinterFactory.createRenderer(
        KoiCommandProtocol.escPos,
      );
      expect(renderer, isA<KoiEscPosRenderer>());
    });

    test('creates TsplRenderer for tspl protocol', () {
      final renderer = KoiPrinterFactory.createRenderer(
        KoiCommandProtocol.tspl,
      );
      expect(renderer, isA<KoiTsplRenderer>());
    });

    test('creates CpclRenderer for cpcl protocol', () {
      final renderer = KoiPrinterFactory.createRenderer(
        KoiCommandProtocol.cpcl,
      );
      expect(renderer, isA<KoiCpclRenderer>());
    });

    test('creates BleAdapter for ble connection', () {
      final adapter = KoiPrinterFactory.createAdapter(KoiConnectionType.ble);
      expect(adapter, isA<KoiBleAdapter>());
    });

    test('creates NetworkAdapter for network connection', () {
      final adapter = KoiPrinterFactory.createAdapter(
        KoiConnectionType.network,
      );
      expect(adapter, isA<KoiNetworkAdapter>());
    });

    test('creates ClassicBtAdapter for classic bluetooth', () {
      final adapter = KoiPrinterFactory.createAdapter(
        KoiConnectionType.classicBluetooth,
      );
      expect(adapter, isA<KoiClassicBtAdapter>());
    });

    test('creates UsbAdapter for usb connection', () {
      final adapter = KoiPrinterFactory.createAdapter(KoiConnectionType.usb);
      expect(adapter, isA<KoiUsbAdapter>());
    });
  });

  group('KoiPrinterService', () {
    test('creates with protocol and connection type', () {
      final service = KoiPrinterService(
        protocol: KoiCommandProtocol.escPos,
        connectionType: KoiConnectionType.ble,
      );

      expect(service.connectionState, KoiConnectionState.disconnected);
      expect(service.isReady, false);
    });

    test('returns failure when not connected', () async {
      final service = KoiPrinterService(
        protocol: KoiCommandProtocol.escPos,
        connectionType: KoiConnectionType.ble,
      );

      const doc = KoiTicketDocument(elements: [KoiTextElement(text: 'Hello')]);

      final result = await service.print(doc);

      expect(result, isA<KoiPrintFailure>());
      final failure = result as KoiPrintFailure;
      expect(failure.error, contains('未连接'));
      expect(failure.isRetryable, true);
    });
  });

  // ════════════════════════════════════════════════════════════
  //  KoiTemplateEngine 嵌套变量 (Gap 10 验证)
  // ════════════════════════════════════════════════════════════

  group('KoiTemplateEngine nested variables', () {
    const engine = KoiTemplateEngine();

    test('single-level dot-notation substitution', () {
      const doc = KoiTicketDocument(
        elements: [
          KoiTicketForEachElement(
            listKey: 'data',
            templates: [KoiTextElement(text: '发货人: {{sender.name}}')],
          ),
        ],
      );

      final expanded = engine.expandTicket(doc, {
        'data': [
          {
            'sender': {'name': '张三'},
          },
        ],
      });

      final text = expanded.elements.first as KoiTextElement;
      expect(text.text, '发货人: 张三');
    });

    test('multi-level dot-notation substitution', () {
      const doc = KoiTicketDocument(
        elements: [
          KoiTicketForEachElement(
            listKey: 'data',
            templates: [KoiTextElement(text: '城市: {{address.city.name}}')],
          ),
        ],
      );

      final expanded = engine.expandTicket(doc, {
        'data': [
          {
            'address': {
              'city': {'name': '深圳'},
            },
          },
        ],
      });

      final text = expanded.elements.first as KoiTextElement;
      expect(text.text, '城市: 深圳');
    });

    test('missing nested path preserves placeholder', () {
      const doc = KoiTicketDocument(
        elements: [
          KoiTicketForEachElement(
            listKey: 'data',
            templates: [KoiTextElement(text: '值: {{a.b.c}}')],
          ),
        ],
      );

      final expanded = engine.expandTicket(doc, {
        'data': [
          {'a': 'flat_value'}, // 'a' 不是 Map, 无法继续嵌套
        ],
      });

      final text = expanded.elements.first as KoiTextElement;
      expect(text.text, '值: {{a.b.c}}'); // 保留原始占位符
    });

    test('mixed flat and nested variables', () {
      const doc = KoiTicketDocument(
        elements: [
          KoiTicketForEachElement(
            listKey: 'data',
            templates: [KoiTextElement(text: '{{name}} - {{address.city}}')],
          ),
        ],
      );

      final expanded = engine.expandTicket(doc, {
        'data': [
          {
            'name': '快递A',
            'address': {'city': '广州'},
          },
        ],
      });

      final text = expanded.elements.first as KoiTextElement;
      expect(text.text, '快递A - 广州');
    });
  });

  // ════════════════════════════════════════════════════════════
  //  KoiPrintConfig & KoiRendererConfig
  // ════════════════════════════════════════════════════════════

  group('KoiRendererConfig', () {
    test('defaults to escPos + normal QR', () {
      const config = KoiRendererConfig();
      expect(config.protocol, KoiCommandProtocol.escPos);
      expect(config.qrStrategy, KoiQrRenderStrategy.normal);
    });

    test('copyWith overrides single field', () {
      const config = KoiRendererConfig();
      final copy = config.copyWith(protocol: KoiCommandProtocol.tspl);
      expect(copy.protocol, KoiCommandProtocol.tspl);
      expect(copy.qrStrategy, KoiQrRenderStrategy.normal); // 未变
    });
  });

  group('KoiPrintConfig', () {
    test('has sensible defaults', () {
      const config = KoiPrintConfig();
      expect(config.deviceRole, KoiDeviceRole.ticketDesktop);
      expect(config.paperSize, KoiPaperSize.mm80);
      expect(config.copies, 1);
      expect(config.headerEmptyLines, 0);
      expect(config.stubType, KoiStubType.withStub);
    });

    test('copyWith with no args returns same values', () {
      const original = KoiPrintConfig();
      final copy = original.copyWith();
      expect(copy.deviceRole, original.deviceRole);
      expect(copy.paperSize, original.paperSize);
      expect(copy.copies, original.copies);
    });

    test('copyWith with multiple fields', () {
      const original = KoiPrintConfig();
      final copy = original.copyWith(
        copies: 3,
        paperSize: KoiPaperSize.mm58,
        stubType: KoiStubType.none,
        headerEmptyLines: 5,
      );
      expect(copy.copies, 3);
      expect(copy.paperSize, KoiPaperSize.mm58);
      expect(copy.stubType, KoiStubType.none);
      expect(copy.headerEmptyLines, 5);
      // 未指定字段保持原值
      expect(copy.deviceRole, KoiDeviceRole.ticketDesktop);
    });
  });

  // ════════════════════════════════════════════════════════════
  //  KoiPrintJob & KoiPrintJobQueue
  // ════════════════════════════════════════════════════════════

  group('KoiPrintJob', () {
    test('creates with required fields', () {
      final job = KoiPrintJob(
        documents: [
          const KoiTicketDocument(elements: [KoiTextElement(text: 'Test')]),
        ],
        config: const KoiPrintConfig(),
      );
      expect(job.documents.length, 1);
      expect(job.copies, 1);
      expect(job.onComplete, isNull);
    });
  });

  group('KoiPrintJobQueue', () {
    test('initial state is not processing', () {
      final queue = KoiPrintJobQueue();
      expect(queue.isProcessing, false);
      expect(queue.length, 0);
    });

    test('enqueue without adapter returns failure', () async {
      final queue = KoiPrintJobQueue();
      final job = KoiPrintJob(
        documents: [
          const KoiTicketDocument(elements: [KoiTextElement(text: 'Test')]),
        ],
        config: const KoiPrintConfig(),
      );

      final result = await queue.enqueue(job);
      expect(result, isA<KoiPrintFailure>());
      final failure = result as KoiPrintFailure;
      expect(failure.error, contains('未连接'));
    });

    test('clear empties queue', () {
      final queue = KoiPrintJobQueue();
      queue.clear();
      expect(queue.length, 0);
    });
  });

  // ════════════════════════════════════════════════════════════
  //  KoiPrinterManager (无适配器状态测试)
  // ════════════════════════════════════════════════════════════

  group('KoiPrinterManager', () {
    test('initial state without adapters', () async {
      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();
      final manager = KoiPrinterManager(storage: KoiPrinterStorage(sp));
      expect(manager.ticketAdapter, isNull);
      expect(manager.labelAdapter, isNull);
      expect(manager.ticketState, KoiConnectionState.disconnected);
      expect(manager.labelState, KoiConnectionState.disconnected);
    });

    test('dispose without adapters does not throw', () async {
      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();
      final manager = KoiPrinterManager(storage: KoiPrinterStorage(sp));
      await expectLater(manager.dispose(), completes);
    });
  });
}
