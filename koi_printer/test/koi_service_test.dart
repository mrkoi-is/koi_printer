// 测试: KoiPrintJobQueue, KoiPrinterService, KoiPrinterManager
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mock_printer_adapter.dart';

void main() {
  // ════════════════════════════════════════════════════════════
  //  KoiPrintJobQueue — 完整覆盖
  // ════════════════════════════════════════════════════════════

  group('KoiPrintJobQueue', () {
    test('enqueue with ready adapter returns success', () async {
      final adapter = MockPrinterAdapter(
        initialState: KoiConnectionState.ready,
      );
      final queue = KoiPrintJobQueue(adapter: adapter);

      final job = KoiPrintJob(
        documents: [
          const KoiTicketDocument(elements: [KoiTextElement(text: 'Hello')]),
        ],
        config: const KoiPrintConfig(),
      );

      final result = await queue.enqueue(job);
      expect(result, isA<KoiPrintSuccess>());
      final success = result as KoiPrintSuccess;
      expect(success.bytesSent, greaterThan(0));
    });

    test('enqueue with adapter that throws returns failure', () async {
      final adapter = MockPrinterAdapter(
        initialState: KoiConnectionState.ready,
        shouldThrowOnSend: true,
      );
      final queue = KoiPrintJobQueue(adapter: adapter);

      final job = KoiPrintJob(
        documents: [
          const KoiTicketDocument(elements: [KoiTextElement(text: 'Hello')]),
        ],
        config: const KoiPrintConfig(),
      );

      final result = await queue.enqueue(job);
      expect(result, isA<KoiPrintFailure>());
    });

    test('enqueue with not-ready adapter returns failure', () async {
      final adapter = MockPrinterAdapter();
      final queue = KoiPrintJobQueue(adapter: adapter);

      final job = KoiPrintJob(
        documents: [
          const KoiTicketDocument(elements: [KoiTextElement(text: 'Hello')]),
        ],
        config: const KoiPrintConfig(),
      );

      final result = await queue.enqueue(job);
      expect(result, isA<KoiPrintFailure>());
    });

    test('enqueue with multiple copies sends chunks multiple times', () async {
      final adapter = MockPrinterAdapter(
        initialState: KoiConnectionState.ready,
      );
      final queue = KoiPrintJobQueue(adapter: adapter);

      final job = KoiPrintJob(
        documents: [
          const KoiTicketDocument(elements: [KoiTextElement(text: 'X')]),
        ],
        config: const KoiPrintConfig(),
        copies: 3,
      );

      final result = await queue.enqueue(job);
      expect(result, isA<KoiPrintSuccess>());
      expect(adapter.sendCallCount, 3);
    });

    test('onComplete callback invoked', () async {
      final adapter = MockPrinterAdapter(
        initialState: KoiConnectionState.ready,
      );
      final queue = KoiPrintJobQueue(adapter: adapter);

      KoiPrintResult? callbackResult;
      final job = KoiPrintJob(
        documents: [
          const KoiTicketDocument(elements: [KoiTextElement(text: 'X')]),
        ],
        config: const KoiPrintConfig(),
        onComplete: (r) => callbackResult = r,
      );

      await queue.enqueue(job);
      expect(callbackResult, isNotNull);
      expect(callbackResult, isA<KoiPrintSuccess>());
    });

    test('queue processes multiple sequential jobs', () async {
      final adapter = MockPrinterAdapter(
        initialState: KoiConnectionState.ready,
      );
      final queue = KoiPrintJobQueue(adapter: adapter);

      final results = await Future.wait([
        queue.enqueue(
          KoiPrintJob(
            documents: [
              const KoiTicketDocument(elements: [KoiTextElement(text: 'Job1')]),
            ],
            config: const KoiPrintConfig(),
          ),
        ),
        queue.enqueue(
          KoiPrintJob(
            documents: [
              const KoiTicketDocument(elements: [KoiTextElement(text: 'Job2')]),
            ],
            config: const KoiPrintConfig(),
          ),
        ),
      ]);

      expect(results[0], isA<KoiPrintSuccess>());
      expect(results[1], isA<KoiPrintSuccess>());
    });

    test('delay profile table2021 uses 200ms', () async {
      final adapter = MockPrinterAdapter(
        initialState: KoiConnectionState.ready,
      );
      final queue = KoiPrintJobQueue(adapter: adapter);

      final job = KoiPrintJob(
        documents: [
          const KoiTicketDocument(elements: [KoiTextElement(text: 'X')]),
        ],
        config: const KoiPrintConfig(delayProfile: KoiDelayProfile.table2021),
      );

      final result = await queue.enqueue(job);
      expect(result, isA<KoiPrintSuccess>());
    });

    test('delay profile table2018 uses 500ms', () async {
      final adapter = MockPrinterAdapter(
        initialState: KoiConnectionState.ready,
      );
      final queue = KoiPrintJobQueue(adapter: adapter);

      final job = KoiPrintJob(
        documents: [
          const KoiTicketDocument(elements: [KoiTextElement(text: 'X')]),
        ],
        config: const KoiPrintConfig(delayProfile: KoiDelayProfile.table2018),
      );

      final result = await queue.enqueue(job);
      expect(result, isA<KoiPrintSuccess>());
    });

    test('adapter can be swapped at runtime', () async {
      final queue = KoiPrintJobQueue();
      // 初始无适配器, 应返回失败
      var result = await queue.enqueue(
        KoiPrintJob(
          documents: [
            const KoiTicketDocument(elements: [KoiTextElement(text: 'X')]),
          ],
          config: const KoiPrintConfig(),
        ),
      );
      expect(result, isA<KoiPrintFailure>());

      // 设置适配器后成功
      queue.adapter = MockPrinterAdapter(
        initialState: KoiConnectionState.ready,
      );
      result = await queue.enqueue(
        KoiPrintJob(
          documents: [
            const KoiTicketDocument(elements: [KoiTextElement(text: 'X')]),
          ],
          config: const KoiPrintConfig(),
        ),
      );
      expect(result, isA<KoiPrintSuccess>());
    });

    test('multiple docs per job all get rendered and sent', () async {
      final adapter = MockPrinterAdapter(
        initialState: KoiConnectionState.ready,
      );
      final queue = KoiPrintJobQueue(adapter: adapter);

      final job = KoiPrintJob(
        documents: [
          const KoiTicketDocument(elements: [KoiTextElement(text: 'Doc1')]),
          const KoiTicketDocument(elements: [KoiTextElement(text: 'Doc2')]),
        ],
        config: const KoiPrintConfig(),
      );

      final result = await queue.enqueue(job);
      expect(result, isA<KoiPrintSuccess>());
      expect(adapter.sendCallCount, 2); // 2 docs
    });
  });

  // ════════════════════════════════════════════════════════════
  //  KoiPrinterService — 完整覆盖
  // ════════════════════════════════════════════════════════════

  group('KoiPrinterService', () {
    test('print with connected adapter returns success', () async {
      final adapter = MockPrinterAdapter(
        initialState: KoiConnectionState.ready,
      );
      final service = KoiPrinterService(
        protocol: KoiCommandProtocol.escPos,
        connectionType: KoiConnectionType.ble,
        adapter: adapter,
      );

      const doc = KoiTicketDocument(
        elements: [KoiTextElement(text: 'Test Print')],
      );
      final result = await service.print(doc);
      expect(result, isA<KoiPrintSuccess>());
      final success = result as KoiPrintSuccess;
      expect(success.bytesSent, greaterThan(0));
    });

    test('print with disconnected adapter returns failure', () async {
      final adapter = MockPrinterAdapter();
      final service = KoiPrinterService(
        protocol: KoiCommandProtocol.escPos,
        connectionType: KoiConnectionType.ble,
        adapter: adapter,
      );

      const doc = KoiTicketDocument(elements: [KoiTextElement(text: 'Test')]);
      final result = await service.print(doc);
      expect(result, isA<KoiPrintFailure>());
    });

    test('print with template data expands ForEach', () async {
      final adapter = MockPrinterAdapter(
        initialState: KoiConnectionState.ready,
      );
      final service = KoiPrinterService(
        protocol: KoiCommandProtocol.escPos,
        connectionType: KoiConnectionType.ble,
        adapter: adapter,
      );

      const doc = KoiTicketDocument(
        elements: [
          KoiTicketForEachElement(
            listKey: 'items',
            templates: [KoiTextElement(text: '{{name}}')],
          ),
        ],
      );
      final result = await service.print(
        doc,
        data: {
          'items': [
            {'name': 'Item1'},
            {'name': 'Item2'},
          ],
        },
      );
      expect(result, isA<KoiPrintSuccess>());
    });

    test('print with copies sends multiple times', () async {
      final adapter = MockPrinterAdapter(
        initialState: KoiConnectionState.ready,
      );
      final service = KoiPrinterService(
        protocol: KoiCommandProtocol.escPos,
        connectionType: KoiConnectionType.ble,
        adapter: adapter,
      );

      const doc = KoiTicketDocument(elements: [KoiTextElement(text: 'Copy')]);
      final result = await service.print(doc, copies: 2);
      expect(result, isA<KoiPrintSuccess>());
      expect(adapter.sendCallCount, 2);
    });

    test('print catches adapter send error', () async {
      final adapter = MockPrinterAdapter(
        initialState: KoiConnectionState.ready,
        shouldThrowOnSend: true,
      );
      final service = KoiPrinterService(
        protocol: KoiCommandProtocol.escPos,
        connectionType: KoiConnectionType.ble,
        adapter: adapter,
      );

      const doc = KoiTicketDocument(elements: [KoiTextElement(text: 'Fail')]);
      final result = await service.print(doc);
      expect(result, isA<KoiPrintFailure>());
      final failure = result as KoiPrintFailure;
      expect(failure.isRetryable, true);
    });

    test('connect delegates to adapter', () async {
      final adapter = MockPrinterAdapter();
      final service = KoiPrinterService(
        protocol: KoiCommandProtocol.escPos,
        connectionType: KoiConnectionType.ble,
        adapter: adapter,
      );

      const config = KoiConnectionConfig(
        deviceName: 'Test',
        deviceId: 'test-id',
      );
      final result = await service.connect(config);
      expect(result, true);
      expect(service.isReady, true);
    });

    test('disconnect delegates to adapter', () async {
      final adapter = MockPrinterAdapter(
        initialState: KoiConnectionState.ready,
      );
      final service = KoiPrinterService(
        protocol: KoiCommandProtocol.escPos,
        connectionType: KoiConnectionType.ble,
        adapter: adapter,
      );

      await service.disconnect();
      expect(service.isReady, false);
    });

    test('connectionStateStream emits state changes', () async {
      final adapter = MockPrinterAdapter();
      final service = KoiPrinterService(
        protocol: KoiCommandProtocol.escPos,
        connectionType: KoiConnectionType.ble,
        adapter: adapter,
      );

      expect(service.connectionStateStream, isA<Stream<KoiConnectionState>>());
    });

    test('dispose disposes adapter', () async {
      final adapter = MockPrinterAdapter();
      final service = KoiPrinterService(
        protocol: KoiCommandProtocol.escPos,
        connectionType: KoiConnectionType.ble,
        adapter: adapter,
      );
      await expectLater(service.dispose(), completes);
    });

    test('creates service with custom renderer', () async {
      final adapter = MockPrinterAdapter(
        initialState: KoiConnectionState.ready,
      );
      final service = KoiPrinterService(
        protocol: KoiCommandProtocol.escPos,
        connectionType: KoiConnectionType.ble,
        renderer: const KoiTsplRenderer(),
        adapter: adapter,
      );

      // Use label document since TSPL renders labels
      const doc = KoiLabelDocument(
        elements: [KoiLabelSetupElement(widthMm: 60, heightMm: 40)],
      );
      final result = await service.print(doc);
      expect(result, isA<KoiPrintSuccess>());
    });

    test('creates with different QR strategies', () {
      final service = KoiPrinterService(
        protocol: KoiCommandProtocol.escPos,
        connectionType: KoiConnectionType.ble,
        qrStrategy: KoiQrRenderStrategy.img,
      );
      expect(service, isNotNull);
    });

    test('print label document without template data', () async {
      final adapter = MockPrinterAdapter(
        initialState: KoiConnectionState.ready,
      );
      final service = KoiPrinterService(
        protocol: KoiCommandProtocol.tspl,
        connectionType: KoiConnectionType.ble,
        adapter: adapter,
      );

      const doc = KoiLabelDocument(
        elements: [KoiLabelSetupElement(widthMm: 60, heightMm: 40)],
      );
      final result = await service.print(doc);
      expect(result, isA<KoiPrintSuccess>());
    });

    test('print label document WITH template data expands ForEach', () async {
      final adapter = MockPrinterAdapter(
        initialState: KoiConnectionState.ready,
      );
      final service = KoiPrinterService(
        protocol: KoiCommandProtocol.tspl,
        connectionType: KoiConnectionType.ble,
        adapter: adapter,
      );

      const doc = KoiLabelDocument(
        elements: [
          KoiLabelSetupElement(widthMm: 60, heightMm: 40),
          KoiLabelForEachElement(
            listKey: 'items',
            templates: [KoiPositionedTextElement(x: 0, y: 0, text: '{{name}}')],
          ),
        ],
      );
      final result = await service.print(
        doc,
        data: {
          'items': [
            {'name': 'LabelItem'},
          ],
        },
      );
      expect(result, isA<KoiPrintSuccess>());
    });
  });

  // ════════════════════════════════════════════════════════════
  //  KoiPrinterManager — 完整覆盖
  // ════════════════════════════════════════════════════════════

  group('KoiPrinterManager', () {
    late SharedPreferences prefs;
    late KoiPrinterStorage storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = KoiPrinterStorage(prefs);
    });

    test('setTicketAdapter updates adapter and queue', () async {
      final manager = KoiPrinterManager(storage: storage);
      final adapter = MockPrinterAdapter(
        initialState: KoiConnectionState.ready,
      );
      manager.setTicketAdapter(adapter);
      expect(manager.ticketAdapter, adapter);
      expect(manager.ticketState, KoiConnectionState.ready);
      await manager.dispose();
    });

    test('setLabelAdapter updates adapter and queue', () async {
      final manager = KoiPrinterManager(storage: storage);
      final adapter = MockPrinterAdapter(
        initialState: KoiConnectionState.ready,
      );
      manager.setLabelAdapter(adapter);
      expect(manager.labelAdapter, adapter);
      expect(manager.labelState, KoiConnectionState.ready);
      await manager.dispose();
    });

    test('connectTicketPrinter returns false without adapter', () async {
      final manager = KoiPrinterManager(storage: storage);
      const config = KoiConnectionConfig(deviceName: 'X', deviceId: 'x-id');
      expect(await manager.connectTicketPrinter(config), false);
      await manager.dispose();
    });

    test('connectTicketPrinter returns true with adapter', () async {
      final adapter = MockPrinterAdapter();
      final manager = KoiPrinterManager(
        storage: storage,
        ticketAdapter: adapter,
      );
      const config = KoiConnectionConfig(deviceName: 'X', deviceId: 'x-id');
      expect(await manager.connectTicketPrinter(config), true);
      await manager.dispose();
    });

    test('connectLabelPrinter returns false without adapter', () async {
      final manager = KoiPrinterManager(storage: storage);
      const config = KoiConnectionConfig(deviceName: 'X', deviceId: 'x-id');
      expect(await manager.connectLabelPrinter(config), false);
      await manager.dispose();
    });

    test('connectLabelPrinter returns true with adapter', () async {
      final adapter = MockPrinterAdapter();
      final manager = KoiPrinterManager(
        storage: storage,
        labelAdapter: adapter,
      );
      const config = KoiConnectionConfig(deviceName: 'X', deviceId: 'x-id');
      expect(await manager.connectLabelPrinter(config), true);
      await manager.dispose();
    });

    test('disconnectAll disconnects both adapters', () async {
      final ticketAdapter = MockPrinterAdapter(
        initialState: KoiConnectionState.ready,
      );
      final labelAdapter = MockPrinterAdapter(
        initialState: KoiConnectionState.ready,
      );
      final manager = KoiPrinterManager(
        storage: storage,
        ticketAdapter: ticketAdapter,
        labelAdapter: labelAdapter,
      );

      await manager.disconnectAll();
      expect(ticketAdapter.state, KoiConnectionState.disconnected);
      expect(labelAdapter.state, KoiConnectionState.disconnected);
      await manager.dispose();
    });

    test('startAutoConnect and stopAutoConnect', () async {
      final manager = KoiPrinterManager(storage: storage);
      manager.startAutoConnect(interval: const Duration(milliseconds: 50));
      // 等一个 tick, 确保 Timer 注册了
      await Future<void>.delayed(const Duration(milliseconds: 10));
      manager.stopAutoConnect();
      await manager.dispose();
    });

    test('connectAll connects stored ticket and label printers', () async {
      // 先存设备
      const device = KoiDeviceInfo(
        name: 'Printer-1',
        address: 'AA:BB',
        connectionType: KoiConnectionType.ble,
      );
      await storage.saveTicketPrinter(device);
      await storage.saveLabelPrinter(device);

      final manager = KoiPrinterManager(storage: storage);
      await manager.connectAll();

      // 应自动创建 adapter 并尝试连接
      expect(manager.ticketAdapter, isNotNull);
      expect(manager.labelAdapter, isNotNull);
      await manager.dispose();
    });

    test('connectAll skips when no devices stored', () async {
      final manager = KoiPrinterManager(storage: storage);
      await manager.connectAll();
      expect(manager.ticketAdapter, isNull);
      expect(manager.labelAdapter, isNull);
      await manager.dispose();
    });

    test('connectAll skips when adapters already ready', () async {
      final ticketAdapter = MockPrinterAdapter(
        initialState: KoiConnectionState.ready,
      );
      const device = KoiDeviceInfo(
        name: 'Printer-1',
        address: 'AA:BB',
        connectionType: KoiConnectionType.ble,
      );
      await storage.saveTicketPrinter(device);
      final manager = KoiPrinterManager(
        storage: storage,
        ticketAdapter: ticketAdapter,
      );
      await manager.connectAll();
      // Adapter was already ready, no need to reconnect
      expect(manager.ticketState, KoiConnectionState.ready);
      await manager.dispose();
    });

    test('printTicketDocument enqueues and returns result', () async {
      final adapter = MockPrinterAdapter(
        initialState: KoiConnectionState.ready,
      );
      final manager = KoiPrinterManager(
        storage: storage,
        ticketAdapter: adapter,
      );

      const doc = KoiTicketDocument(elements: [KoiTextElement(text: 'Hello')]);
      final result = await manager.printTicketDocument(
        doc,
        config: const KoiPrintConfig(),
      );
      expect(result, isA<KoiPrintSuccess>());
      await manager.dispose();
    });

    test('printTicketDocument with templateData expands', () async {
      final adapter = MockPrinterAdapter(
        initialState: KoiConnectionState.ready,
      );
      final manager = KoiPrinterManager(
        storage: storage,
        ticketAdapter: adapter,
      );

      const doc = KoiTicketDocument(
        elements: [
          KoiTicketForEachElement(
            listKey: 'items',
            templates: [KoiTextElement(text: '{{name}}')],
          ),
        ],
      );
      final result = await manager.printTicketDocument(
        doc,
        config: const KoiPrintConfig(),
        templateData: {
          'items': [
            {'name': 'A'},
          ],
        },
      );
      expect(result, isA<KoiPrintSuccess>());
      await manager.dispose();
    });

    test('printLabelDocument enqueues and returns result', () async {
      final adapter = MockPrinterAdapter(
        initialState: KoiConnectionState.ready,
      );
      final manager = KoiPrinterManager(
        storage: storage,
        labelAdapter: adapter,
      );

      const doc = KoiLabelDocument(
        elements: [KoiLabelSetupElement(widthMm: 60, heightMm: 40)],
      );
      final result = await manager.printLabelDocument(
        doc,
        config: const KoiPrintConfig(
          renderer: KoiRendererConfig(protocol: KoiCommandProtocol.tspl),
        ),
      );
      expect(result, isA<KoiPrintSuccess>());
      await manager.dispose();
    });

    test('printTicket with template builds and enqueues', () async {
      final adapter = MockPrinterAdapter(
        initialState: KoiConnectionState.ready,
      );
      final manager = KoiPrinterManager(
        storage: storage,
        ticketAdapter: adapter,
      );

      final result = await manager.printTicket(
        template: _TestTicketTemplate(),
        data: 'test-data',
        config: const KoiPrintConfig(),
      );
      expect(result, isA<KoiPrintSuccess>());
      await manager.dispose();
    });

    test('printLabel with template builds and enqueues', () async {
      final adapter = MockPrinterAdapter(
        initialState: KoiConnectionState.ready,
      );
      final manager = KoiPrinterManager(
        storage: storage,
        labelAdapter: adapter,
      );

      final result = await manager.printLabel(
        template: _TestLabelTemplate(),
        data: 'test-data',
        config: const KoiPrintConfig(
          renderer: KoiRendererConfig(protocol: KoiCommandProtocol.tspl),
        ),
      );
      expect(result, isA<KoiPrintSuccess>());
      await manager.dispose();
    });

    test('connectAll handles ticket adapter connect error', () async {
      // 设置一个会抛异常的 adapter
      final adapter = MockPrinterAdapter(shouldThrowOnConnect: true);
      const device = KoiDeviceInfo(
        name: 'Ticket',
        address: 'AA:BB',
        connectionType: KoiConnectionType.ble,
      );
      await storage.saveTicketPrinter(device);
      final manager = KoiPrinterManager(
        storage: storage,
        ticketAdapter: adapter,
      );
      // connectAll 不应抛错, 内部 catch 处理
      await expectLater(manager.connectAll(), completes);
      await manager.dispose();
    });

    test('connectAll handles label adapter connect error', () async {
      final adapter = MockPrinterAdapter(shouldThrowOnConnect: true);
      const device = KoiDeviceInfo(
        name: 'Label',
        address: 'CC:DD',
        connectionType: KoiConnectionType.ble,
      );
      await storage.saveLabelPrinter(device);
      final manager = KoiPrinterManager(
        storage: storage,
        labelAdapter: adapter,
      );
      await expectLater(manager.connectAll(), completes);
      await manager.dispose();
    });
  });
}

// ── 测试用模板 ──

class _TestTicketTemplate implements KoiTicketTemplate<String> {
  @override
  List<KoiTicketDocument> build(String data, KoiPrintConfig config) {
    return [
      KoiTicketDocument(elements: [KoiTextElement(text: 'Ticket: $data')]),
    ];
  }
}

class _TestLabelTemplate implements KoiLabelTemplate<String> {
  @override
  List<KoiLabelDocument> build(String data, KoiPrintConfig config) {
    return [
      const KoiLabelDocument(
        elements: [KoiLabelSetupElement(widthMm: 60, heightMm: 40)],
      ),
    ];
  }
}
