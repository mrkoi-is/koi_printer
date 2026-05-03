/// koi_printer 中用到的常量 — 从旧 xii_papper_const.dart 迁移。
/// Constants used across koi_printer templates and layouts.
///
/// 来源: 旧 xii_papper_const.dart (48 LOC)
library;

// ── 业务字段标签 ──

/// 操作员。
const kKoiOriginator = '操作员';

/// 运单号。
const kKoiTicketNumber = '运单号';

/// 流水号。
const kKoiSerialNumber = '流水号';

/// 收货人。
const kKoiReceiver = '收货人';

/// 发货人。
const kKoiSender = '发货人';

/// 货物。
const kKoiCargo = '货物';

/// 合计。
const kKoiTotal = '合计';

/// 发货日期。
const kKoiDeliveryDate = '发货日期';

/// 提货方式。
const kKoiDeliveryMode = '提货方式';

// ── 费用字段标签 ──

/// 垫付费。
const kKoiExtFee = '垫付费';

/// 已收。
const kKoiReceivedFee = '已收';

/// 派送费。
const kKoiPsFee = '派送费';

/// 接货费。
const kKoiPickFee = '接货费';

/// 分拨费。
const kKoiTransFee = '分拨费';

/// 应收运费。
const kKoiPayable = '应收运费';

/// 现付运费。
const kKoiPrepaid = '现付运费';

/// 保额。
const kKoiCoverage = '保额';

/// 保费。
const kKoiPremiums = '保费';

/// 代收。
const kKoiBehalfFee = '代收';

// ── 联别标题 ──

/// 发货。
const kKoiShipments = '发货';

/// 客户联。
const kKoiClientStubTitle = '客户联';

/// 存根联。
const kKoiStubTitle = '存根联';

/// 提货客户联。
const kKoiDeliveryClientTitle = '---提货客户联---';

/// 提货存根联。
const kKoiDeliveryStubTitle = '---提货存根联---';

/// 到付运费。
const kKoiPickupFreight = '到付运费';

/// 现付运费 (到件场景)。
const kKoiSendPayFreight = '现付运费';

// ── 地址标签 ──

/// 发货地。
const kKoiSenderAddress = '发货地';

/// 收货地。
const kKoiReceiverAddress = '收货地';
