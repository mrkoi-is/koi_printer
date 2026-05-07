/// koi_printer_command — 打印文档模型 + 指令渲染器。
///
/// 小票文档 ([KoiTicketDocument]) → [KoiEscPosRenderer]
/// 标签文档 ([KoiLabelDocument]) → [KoiTsplRenderer] / [KoiCpclRenderer]
library;

import 'package:koi_printer_command/koi_printer_command.dart'
    show
        KoiCpclRenderer,
        KoiEscPosRenderer,
        KoiLabelDocument,
        KoiTicketDocument,
        KoiTsplRenderer;

// 模型
export 'src/model/koi_print_document.dart';
export 'src/model/koi_print_element.dart';
export 'src/model/koi_print_result.dart';
export 'src/model/koi_types.dart';

// 渲染器
export 'src/renderer/koi_command_renderer.dart';
export 'src/renderer/koi_cpcl_renderer.dart';
export 'src/renderer/koi_esc_pos_renderer.dart';
export 'src/renderer/koi_tspl_renderer.dart';
export 'src/serialization/koi_json_serialization.dart';

// 状态查询
export 'src/status/koi_escpos_status_query.dart';
