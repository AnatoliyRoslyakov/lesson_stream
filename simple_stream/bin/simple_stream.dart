import 'dart:async';

void main() {
  simpleStream();
  simplePeriodicStream();
}

void simpleStream() {
  // Создаем StreamController
  final StreamController<int> controller = StreamController<int>();

  // Добавляем данные в поток
  controller.add(1);
  controller.add(2);
  controller.add(3);

  // Подписываемся на поток
  controller.stream.listen((data) {
    print('Получено: $data');
  });

  // Завершаем поток
  controller.close();
}

void simplePeriodicStream() {
  final controller = StreamController<int>();

  // Симулируем асинхронное событие
  Timer.periodic(Duration(seconds: 1), (Timer timer) {
    controller.add(timer.tick);
    if (timer.tick >= 5) {
      timer.cancel();
      controller.close();
    }
  });

  // Подписываемся на поток для получения данных
  controller.stream.listen((data) {
    print('Получено: $data');
  });
}
