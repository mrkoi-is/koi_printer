/// koi_printer — 打印机门面包。
///
/// 组合 koi_printer_command 和 koi_printer_connection, 提供:
/// - [KoiPrinterManager] — 双机管理 (小票 + 标签)
/// - [KoiPrinterService] — 简化版单机打印 API
/// - [KoiTemplateEngine] — ForEach 模板展开
/// - [KoiPrinterFactory] — 按协议/连接类型自动创建
/// - [KoiPrintConfig] — 完整业务配置
/// - [KoiTicketTemplate] / [KoiLabelTemplate] — 多联模板接口
///
/// 同时 re-export 子包的公开 API。
library;

import 'package:koi_printer/koi_printer.dart'
    show
        KoiLabelTemplate,
        KoiPrintConfig,
        KoiPrinterFactory,
        KoiPrinterManager,
        KoiPrinterService,
        KoiTemplateEngine,
        KoiTicketTemplate;

// Re-export 子包
export 'package:koi_printer_command/koi_printer_command.dart';
export 'package:koi_printer_connection/koi_printer_connection.dart';

// 配置
export 'src/config/koi_print_config.dart';
export 'src/config/koi_user_preferences.dart';
// 常量
export 'src/koi_printer_constants.dart';
// 服务
export 'src/koi_printer_factory.dart';
export 'src/koi_printer_service.dart';
export 'src/koi_template_engine.dart';
// 模型
export 'src/model/koi_printer_profile.dart';
// 预览
export 'src/preview/koi_preview_renderer.dart';
export 'src/service/koi_print_job_queue.dart';
export 'src/service/koi_printer_manager.dart';
// 存储
export 'src/storage/koi_printer_storage.dart';
// 模板
export 'src/template/koi_print_template.dart';
