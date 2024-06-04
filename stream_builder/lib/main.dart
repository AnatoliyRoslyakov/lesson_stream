import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CurrencyRateScreen(),
    );
  }
}

class CurrencyRateScreen extends StatefulWidget {
  const CurrencyRateScreen({super.key});

  @override
  State<CurrencyRateScreen> createState() => _CurrencyRateScreenState();
}

class _CurrencyRateScreenState extends State<CurrencyRateScreen> {
  // Создаем экземпляр WebSocketService
  final WebSocketService webSocketService = WebSocketService();
  Map<String, dynamic>? lastData;

  // Устанавливаем соединение WebSocket при инициализации
  @override
  void initState() {
    super.initState();
    webSocketService
        .connect(
      'wss://quote.pro.apex.exchange/realtime_public?v=2&timestamp=${DateTime.now().millisecondsSinceEpoch}',
    )
        .then((_) {
      // Отправляем сообщение подписки после подключения
      webSocketService.sendMessage(
        '{"op":"subscribe","args":["recentlyTrade.H.BTCUSDC"]}',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StreamBuilder'),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        // Поток данных из WebSocketService
        stream: webSocketService.stream,
        builder: (context, snapshot) {
          // Отображаем индикатор загрузки, пока ждем данные
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
            // Отображаем сообщение об ошибке, если произошла ошибка
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
            // Отображаем сообщение, если данные не получены
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Данные не получены'));
            // Отображаем текущую цену
          } else {
            if (snapshot.data?['data'] != null) {
              lastData = snapshot.data;
            }
            log(snapshot.data.toString());
            final data = lastData?['data'] ?? {};
            final price = data.isNotEmpty ? data[0]['p'] : 'Нет данных';
            final tick = data.isNotEmpty ? data[0]['L'] : '';

            return Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  switch (tick) {
                    'PlusTick' => RateWidget(
                        price: price,
                        color: Colors.green,
                        icon: Icons.arrow_upward),
                    'MinusTick' => RateWidget(
                        price: price,
                        color: Colors.redAccent,
                        icon: Icons.arrow_downward),
                    'ZeroMinusTick' => RateWidget(
                        price: price, color: Colors.blue, icon: Icons.remove),
                    'ZeroPlusTick' => RateWidget(
                        price: price, color: Colors.blue, icon: Icons.remove),
                    _ => const SizedBox.shrink()
                  }
                ],
              ),
            );
          }
        },
      ),
    );
  }

  // Закрываем соединение WebSocket
  @override
  void dispose() {
    webSocketService.close();
    super.dispose();
  }
}

class RateWidget extends StatelessWidget {
  const RateWidget({
    super.key,
    required this.price,
    required this.color,
    required this.icon,
  });

  final String price;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '1 BTC ≈ $price USDS',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w700, color: color),
        ),
        Icon(
          icon,
          color: color,
        ),
      ],
    );
  }
}

// Сервис для работы с WebSocket
class WebSocketService {
  late WebSocket webSocket;
  final controller = StreamController<Map<String, dynamic>>();
  // Поток для получения данных
  Stream<Map<String, dynamic>> get stream => controller.stream;

  // Метод для подключения к WebSocket
  Future<void> connect(String url) async {
    webSocket = await WebSocket.connect(url);

    // Слушаем сообщения от WebSocket
    webSocket.listen(
      (message) {
        final data = jsonDecode(message);
        controller.add(data);
      },
      onDone: () {
        controller.close();
      },
      onError: (error) {
        controller.addError(error);
      },
    );
  }

  // Метод для отправки сообщения через WebSocket
  void sendMessage(String message) {
    if (webSocket.readyState == WebSocket.open) {
      webSocket.add(message);
    } else {
      log('WebSocket не подключен');
    }
  }

  // Метод для закрытия соединения WebSocket
  void close() {
    webSocket.close();
  }
}
