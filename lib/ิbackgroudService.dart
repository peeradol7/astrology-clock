import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // ตรวจสอบเวลาและสลับ
  Timer.periodic(Duration(minutes: 15), (timer) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    if (now.hour == 23 && now.minute == 56) {
      int currentIndex = prefs.getInt('currentIndex') ?? 0;
      int numberRotationIndex = prefs.getInt('numberRotationIndex') ?? 0;

      currentIndex = (currentIndex + 1) % 20;
      numberRotationIndex = (numberRotationIndex + 1) % 21;

      await prefs.setInt('currentIndex', currentIndex);
      await prefs.setInt('numberRotationIndex', numberRotationIndex);
    }
  });
}

@override
void initState() {
  initState();
  initializeService();
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
    ),
  );
}
