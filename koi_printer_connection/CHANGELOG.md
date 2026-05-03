## 0.1.0

* 初始发布 (Initial release)
* `KoiPrinterAdapter` 统一连接接口
* BLE 适配器: 基于 `flutter_blue_plus`, 支持 MTU 分块
* 经典蓝牙适配器: 基于 `flutter_bluetooth_serial`
* TCP/IP 网络适配器: Socket 长连接
* USB 适配器: `libusb` 通信
* `KoiConnectionPolicy` 重连策略: 线性/指数退避
* `KoiDiscoveredDevice` 设备发现模型
* 18 单元测试
