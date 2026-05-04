import 'package:flutter_test/flutter_test.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_example/src/template/ticket/koi_sender_ticket_template.dart';
import 'dart:io';

void main() {
  test('Generate JSON template', () {
    final d = {
      'fromNodeInfo': '{{fromNodeInfo}}',
      'toNodeInfo': '{{toNodeInfo}}',
      'operatorId': '{{operatorId}}',
      'operatorName': '{{operatorName}}',
      'ticketSn': '{{ticketSn}}',
      'sequnceId': '{{sequnceId}}',
      'startDate': '{{startDate}}',
      'recieverName': '{{recieverName}}',
      'recieverPhone': '{{recieverPhone}}',
      'pickMethod': '{{pickMethod}}',
      'senderInfo': '{{senderInfo}}',
      'senderPhone': '{{senderPhone}}',
      'weight': '{{weight}}',
      'volume': '{{volume}}',
      'cargoInfo': '{{cargoInfo}}',
      'cargoCount': '{{cargoCount}}',
      'nodeRoleInfo': '{{nodeRoleInfo}}',
      'amount': '{{amount}}',
      'method': '{{method}}',
      'orderNo': '{{orderNo}}',
      'remark': '{{remark}}',
      'waybillNo': '{{waybillNo}}',
    };

    final tpl = const KoiSenderTicketTemplate();
    final docs = tpl.build(d, const KoiPrintConfig());
    final doc = docs.first;

    final jsonStr = (doc as KoiPrintDocument).toJsonString();
    File('sender_ticket_template.json').writeAsStringSync(jsonStr);
  });
}
