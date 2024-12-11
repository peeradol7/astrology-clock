import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImageSlider extends StatefulWidget {
  @override
  _ImageSliderState createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  // รายการรูปภาพนาฬิกา
  final List<String> _images = List.generate(
    20,
    (index) => 'assets/Clock/clock${index + 1}-removebg-preview.png',
  );

  final List<String> innerNumbers = [
    "๔",
    "๗",
    "๑",
    "๒",
    "๔",
    "๗",
    "๗",
    "๑",
    "๖",
    "๕",
    "๕",
    "๕",
    "๓",
    "๒",
    "๔",
    "๑",
    "๖",
    "๓",
    "๖",
    "๓",
    "๒"
  ];
  late SharedPreferences _prefs;
  int _currentIndex = 1;
  int _numberRotationIndex = 0;
  DateTime _currentTime = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    _prefs = await SharedPreferences.getInstance();
    bool _hasRotatedToday = false;

    setState(() {
      _currentIndex = _prefs.getInt('currentIndex') ?? 0;
      _numberRotationIndex = _prefs.getInt('numberRotationIndex') ?? 0;
      // เพิ่มการดึง flag การสลับประจำวัน
      _hasRotatedToday = _prefs.getBool('hasRotatedToday') ?? false;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now().toLocal();
        if (_currentTime.hour == 23 &&
            _currentTime.minute == 56 &&
            !_hasRotatedToday) {
          _rotateImage();
          _rotateNumbers();

          _hasRotatedToday = true;
          _prefs.setBool('hasRotatedToday', true);
        }

        if (_currentTime.hour == 0 && _currentTime.minute == 0) {
          _hasRotatedToday = false;
          _prefs.setBool('hasRotatedToday', false);
        }
      });
    });
  }

  double _calculateHandAngle(int value, int max) {
    return (value / max) * 2 * pi - pi / 2;
  }

  int _findCurrentNumberForHand(double handAngle, List<String> numbers) {
    // คำนวณมุมเริ่มต้น (index แรก)
    // ปรับองศาให้เริ่มจากตำแหน่งบนสุดของวงกลม
    double startAngle = -pi / 1.5; // 12 นาฬิกา

    // คำนวณมุมต่อเซ็กชัน
    double anglePerSection = (2 * pi) / numbers.length;

    // ปรับมุมให้เป็นค่าบวก
    double normalizedAngle = (handAngle - startAngle + 2 * pi) % (2 * pi);

    // คำนวณ index
    int index = (normalizedAngle / anglePerSection).floor();

    return index % numbers.length;
  }
  // int _findCurrentNumberForHand(double handAngle, List<String> numbers) {
  //   // เพิ่ม print เพื่อดูค่ามุมและการคำนวณ
  //   print('Input Angle: $handAngle');
  //   print('Total Numbers: ${numbers.length}');

  //   // ปรับมุมให้อยู่ในช่วง 0 ถึง 2π
  //   double normalizedAngle = (handAngle + pi) % (2 * pi);
  //   print('Normalized Angle: $normalizedAngle');

  //   // คำนวณมุมต่อช่วง
  //   final anglePerSection = (2 * pi) / numbers.length;
  //   print('Angle Per Section: $anglePerSection');

  //   // คำนวณ index โดยละเอียด
  //   int index = ((normalizedAngle) / anglePerSection).floor();
  //   print('Calculated Index: $index');

  //   return index % numbers.length;
  // }

  void _rotateNumbers() {
    setState(() {
      _numberRotationIndex = (_numberRotationIndex + 1) % innerNumbers.length;
      _prefs.setInt('numberRotationIndex', _numberRotationIndex);
    });
  }

  void _rotateImage() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _images.length;

      _prefs.setInt('currentIndex', _currentIndex);
    });
  }

  Widget _buildArrowHand({
    required double angle,
    required Color color,
    required double length,
    required double thickness,
    Offset offset = Offset.zero,
  }) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: angle,
        child: CustomPaint(
          painter: ArrowHandPainter(
            color: color,
            length: length,
            thickness: thickness,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTime = DateTime.now();
    final isNightTime = currentTime.hour >= 18 || currentTime.hour < 6;

    final secondAngle = _calculateHandAngle(_currentTime.second, 60);
    final minuteAngle = _calculateHandAngle(_currentTime.minute, 60);
    final hourAngle = _calculateHandAngle(
        (_currentTime.hour % 12) * 60 + _currentTime.minute, 12 * 60);

    final hourHandIndex = _findCurrentNumberForHand(hourAngle, innerNumbers);
    final hourHandNumber = innerNumbers[hourHandIndex];

    final minuteHandIndex =
        _findCurrentNumberForHand(minuteAngle, innerNumbers);

    final minuteHandNumber = innerNumbers[minuteHandIndex];
    print('==== Hand Details ====');
    print('Current Time: ${_currentTime}');
    print('Second Angle: $secondAngle, Index: $hourHandIndex');
    print('Minute Angle: $minuteAngle, Index: $minuteHandIndex');
    print('Hour Angle: $hourAngle');
    print('=====================');
    _findCurrentNumberForHand(minuteAngle, innerNumbers);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(isNightTime ? 'assets/night.jpg' : 'assets/sky.jpg',
                    width: 520, height: 600, fit: BoxFit.cover),
                Positioned(
                  top: 150,
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    _images[_currentIndex],
                    width: 350,
                    height: 350,
                    fit: BoxFit.contain,
                  ),
                ),
                _buildArrowHand(
                  angle: secondAngle,
                  color: Colors.red,
                  length: 150, // ลดลงนิดหน่อย
                  thickness: 2,
                  // เพิ่มการชดเชยตำแหน่ง
                  offset: Offset(0, 10),
                ),
                _buildArrowHand(
                  angle: minuteAngle,
                  color: Colors.blue,
                  length: 130, // ลดลงนิดหน่อย
                  thickness: 4,
                  offset: Offset(0, 15),
                ),
                _buildArrowHand(
                  angle: hourAngle,
                  color: Colors.black,
                  length: 95, // ลดลงนิดหน่อย
                  thickness: 6,
                  offset: Offset(0, 20),
                ),
                Container(
                  width: 300,
                  height: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: Size(300, 300),
                        painter: DividerLinePainter(radius: 140),
                      ),
                      // วงกลางตรงกลาง
                      Positioned(
                        left: 140,
                        top: 158,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                      // ตัวเลข
                      ...List.generate(innerNumbers.length, (index) {
                        final adjustedIndex = (index + _numberRotationIndex) %
                            innerNumbers.length;
                        return Positioned(
                          left: 142 +
                              80 *
                                  cos(2 * pi * index / innerNumbers.length +
                                      (-97 * pi / 180)),
                          top: 155 +
                              80 *
                                  sin(2 * pi * index / innerNumbers.length +
                                      (-97 * pi / 180)),
                          child: Text(
                            innerNumbers[adjustedIndex],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            // Text(
            //   'เข็มชั่วโมง: $hourHandNumber',
            //   style: TextStyle(fontSize: 16),
            // ),
            // Text(
            //   'เข็มนาที: $minuteHandNumber',
            //   style: TextStyle(fontSize: 16),
            // ),
            Text(
              'เวลาปัจจุบัน: ${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}:${_currentTime.second.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class ArrowHandPainter extends CustomPainter {
  final Color color;
  final double length;
  final double thickness;

  ArrowHandPainter({
    required this.color,
    required this.length,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, 0),
      Offset(length, 0),
      paint,
    );

    // วาดหัวลูกศร
    Path path = Path();
    path.moveTo(length, 0);
    path.lineTo(length - 10, -5);
    path.lineTo(length - 10, 5);
    path.close();

    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DividerLinePainter extends CustomPainter {
  final double radius; // รัศมีของวงกลมที่จะวาดเส้นคั่น

  DividerLinePainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black // สีของเส้น
      ..strokeWidth = 2; // ความหนาของเส้น

    final center = Offset(
        size.width / 2, size.height / 1.75); // คำนวณจุดศูนย์กลางของ canvas

    final circlePaint = Paint()
      ..color = const Color.fromARGB(255, 0, 0, 0).withOpacity(1) // สีของวงกลม
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    // วาดวงกลมตรงกลางที่ตำแหน่งศูนย์กลาง
    canvas.drawCircle(center, 60, circlePaint);

    // เรียกฟังก์ชันเพื่อวาดเส้นแต่ละเส้นที่ตำแหน่งที่ต้องการ
    _drawTickMark(canvas, center, radius, paint, 1);
    _drawTickMark(canvas, center, radius, paint, 2);
    _drawTickMark(canvas, center, radius, paint, 3);
    _drawTickMark(canvas, center, radius, paint, 4);
    _drawTickMark(canvas, center, radius, paint, 5);
    _drawTickMark(canvas, center, radius, paint, 6);
    _drawTickMark(canvas, center, radius, paint, 7);
    _drawTickMark(canvas, center, radius, paint, 8);
    _drawTickMark(canvas, center, radius, paint, 9);
    _drawTickMark(canvas, center, radius, paint, 10);
    _drawTickMark(canvas, center, radius, paint, 11);
    _drawTickMark(canvas, center, radius, paint, 12);
    _drawTickMark(canvas, center, radius, paint, 13);
    _drawTickMark(canvas, center, radius, paint, 14);
    _drawTickMark(canvas, center, radius, paint, 15);
    _drawTickMark(canvas, center, radius, paint, 16);
    _drawTickMark(canvas, center, radius, paint, 17);
    _drawTickMark(canvas, center, radius, paint, 18);
    _drawTickMark(canvas, center, radius, paint, 19);
    _drawTickMark(canvas, center, radius, paint, 20);
    _drawTickMark(canvas, center, radius, paint, 21);
  }

  void _drawTickMark(
      Canvas canvas, Offset center, double radius, Paint paint, double i) {
    final angle = (i * (360 / 21)) * pi / 180;

    // คำนวณตำแหน่งของจุดเริ่มต้นและปลายของเส้น
    final startOffset = Offset(
      center.dx + radius * 0.72 * sin(angle),
      center.dy - radius * 0.72 * cos(angle),
    );
    final endOffset = Offset(
      center.dx + radius * 0.44 * sin(angle),
      center.dy - radius * 0.44 * cos(angle),
    );

    // วาดเส้นจาก startOffset ไปยัง endOffset
    canvas.drawLine(startOffset, endOffset, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ClockHandPainter extends CustomPainter {
  final double handAngle;
  final Color handColor;

  ClockHandPainter({required this.handAngle, required this.handColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final handLength = radius * 0.8;

    // คำนวณตำแหน่งปลายเส้น
    final handEnd = Offset(
      center.dx + handLength * cos(handAngle - pi / 2),
      center.dy + handLength * sin(handAngle - pi / 2),
    );

    final paint = Paint()
      ..color = handColor
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, handEnd, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
