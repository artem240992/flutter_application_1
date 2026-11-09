import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class LanRoleScreen extends StatefulWidget {
  const LanRoleScreen({super.key});

  @override
  State<LanRoleScreen> createState() => _LanRoleScreenState();
}

class _LanRoleScreenState extends State<LanRoleScreen> {
  // --- Переменные для Хоста ---
  HttpServer? _server;
  String _hostIp = 'Загрузка...';
  bool _isServerRunning = false;
  final List<WebSocket> _connectedClients = [];

  // --- Переменные для Клиента ---
  final TextEditingController _ipController = TextEditingController();
  WebSocketChannel? _channel;
  String _myRole = 'Ожидание раздачи...';

  @override
  void initState() {
    super.initState();
    _getHostIp();
  }

  @override
  void dispose() {
    _server?.close();
    _channel?.sink.close(status.goingAway);
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _getHostIp() async {
    final info = NetworkInfo();
    final ip = await info.getWifiIP();
    setState(() {
      _hostIp = ip ?? 'Нет Wi-Fi';
    });
  }

  // --- ЛОГИКА ХОСТА ---
  Future<void> _startServer() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
      setState(() => _isServerRunning = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сервер запущен! Ждем игроков...')),
      );

      _server!.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final socket = await WebSocketTransformer.upgrade(request);
          _connectedClients.add(socket);
          setState(() {});

          socket.listen((data) {}, onDone: () {
            _connectedClients.remove(socket);
            setState(() {});
          });
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сервера: $e')),
      );
    }
  }

  void _distributeRoles() {
    if (_connectedClients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет подключенных игроков!')),
      );
      return;
    }

    final roles = ['Человек', 'Человек', 'Гибрид', 'Культист'];
    roles.shuffle();

    for (int i = 0; i < _connectedClients.length; i++) {
      final role = i < roles.length ? roles[i] : 'Человек';
      _connectedClients[i].add(jsonEncode({'role': role}));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Роли отправлены!')),
    );
  }

  // --- ЛОГИКА КЛИЕНТА ---
  void _connectToHost(String ipString) {
    final ip = ipString.trim();
    if (ip.isEmpty) return;

    try {
      // Если отсканировали QR, там будет полный URL (ws://...)
      final url = ip.startsWith('ws://') ? ip : 'ws://$ip:8080';
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _channel!.stream.listen((message) {
        final data = jsonDecode(message);
        setState(() {
          _myRole = data['role'];
        });
        _showRoleDialog(_myRole);
      }, onDone: () {
        setState(() {
          _myRole = 'Соединение закрыто';
        });
      });

      setState(() {
        _myRole = 'Подключено. Ждем раздачи...';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Успешно подключено!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка подключения: $e')),
      );
    }
  }

  Future<void> _scanQrCode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );

    if (result != null) {
      _ipController.text = result;
      _connectToHost(result); // Автоматически подключаемся
    }
  }

  void _showRoleDialog(String role) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ваша тайная роль'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(role, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Запомнил'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Раздача ролей (LAN)'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Я Хост', icon: Icon(Icons.wifi_tethering)),
              Tab(text: 'Я Клиент', icon: Icon(Icons.phone_android)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- ВКЛАДКА ХОСТА ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Text('Включите Wi-Fi на всех устройствах.'),
                    const SizedBox(height: 8),
                    SelectableText(
                      'Ваш IP: $_hostIp',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const SizedBox(height: 16),

                    if (!_isServerRunning)
                      ElevatedButton(
                        onPressed: _startServer,
                        child: const Text('Запустить сервер'),
                      ),

                    if (_isServerRunning && _hostIp != 'Нет Wi-Fi') ...[
                      const Text('Отсканируйте этот QR-код на других телефонах:'),
                      const SizedBox(height: 16),
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(12),
                        child: QrImageView(
                          data: 'ws://$_hostIp:8080',
                          version: QrVersions.auto,
                          size: 200.0,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    Text('Подключено игроков: ${_connectedClients.length}', style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _connectedClients.isEmpty ? null : _distributeRoles,
                      icon: const Icon(Icons.shuffle),
                      label: const Text('Раздать роли'),
                    ),
                  ],
                ),
              ),
            ),

            // --- ВКЛАДКА КЛИЕНТА ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('Подключитесь к Хосту:'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _scanQrCode,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Сканировать QR-код'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('ИЛИ введите IP вручную:'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '192.168.1.5'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => _connectToHost(_ipController.text),
                    child: const Text('Подключиться по IP'),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _myRole,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- ОТДЕЛЬНЫЙ ЭКРАН ДЛЯ СКАНЕРА ---
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Наведите камеру на QR-код')),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          if (_isScanned) return; // Защита от двойного срабатывания

          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final String? code = barcode.rawValue;
            if (code != null) {
              _isScanned = true;
              controller.stop();
              Navigator.pop(context, code); // Возвращаем результат
              break;
            }
          }
        },
      ),
    );
  }
}