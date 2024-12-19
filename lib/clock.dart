import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ImageSlider extends StatefulWidget {
  @override
  _ImageSliderState createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  late SharedPreferences _prefs;
  int _currentIndex = 1;
  int _numberRotationIndex = 0;
  DateTime _currentTime = DateTime.now();
  Timer? _timer;
  Timer? _refreshTimer;
  Timer? _timeUpdateTimer;
  List<String> _images = [];
  List<String> innerNumbers = [];
  int _rotationCounter = 0;
  bool _isLoading = true;
  bool _hasError = false;
  Timer? _apiTimer;
  @override
  void initState() {
    fetchData(); // ดึงข้อมูลจาก API ครั้งแรก
    _startRefreshTimer(); // ตั้ง Timer สำหรับรีเฟรชข้อมูล API
    _startCurrentTimeTimer(); // ตั้ง Timer สำหรับอัพเดทเวลาปัจจุบัน
    _startNumberRotationTimer();
    super.initState();
  }

  void _startNumberRotationTimer() {
    DateTime now = DateTime.now();
    DateTime nextRotationTime =
        DateTime(now.year, now.month, now.day, 23, 56, 0);

    if (now.isAfter(nextRotationTime)) {
      nextRotationTime = nextRotationTime.add(Duration(days: 1));
    }

    Duration initialDelay = nextRotationTime.difference(now);

    Timer(initialDelay, () {
      if (mounted) {
        setState(() {
          _numberRotationIndex =
              (_numberRotationIndex + 1) % innerNumbers.length;
        });
      }

      _timer = Timer.periodic(Duration(minutes: 1360), (timer) {
        if (mounted) {
          setState(() {
            _numberRotationIndex =
                (_numberRotationIndex + 1) % innerNumbers.length;
          });
        }
      });
    });
  }

  void _startRealtimeUpdates() {
    // เรียก API ทุก 30 วินาที
    _apiTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      fetchData();
    });
  }

  /// ฟังก์ชันดึงข้อมูลจาก API
  Future<void> fetchData() async {
    try {
      // final url = Uri.parse('https://clock-api-wu4f.onrender.com/clock-data');
      https: //clock-api-production-ef71.up.railway.app/clock-data
      final url = Uri.parse(
          'https://clock-api-production-ef71.up.railway.app/clock-data');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        String? imagePath = data['image'];
        if (imagePath != null && mounted) {
          setState(() {
            _images = [
              'https://clock-api-production-ef71.up.railway.app/Clock/$imagePath'
            ];
            innerNumbers = List<String>.from(data['numbers']['current']);
            _isLoading = false;
            _hasError = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
        print('API Error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
      print('Network Error: $e');
    }
  }

  double _calculateHandAngle(int value, int max) {
    return (value / max) * 2 * pi - pi / 2;
  }

  int _findCurrentNumberForHand(double handAngle, List<String> numbers) {
    // เพิ่มการเช็คก่อนคำนวณ
    if (numbers.isEmpty) return 0;

    double startAngle = -pi / 1.5;
    double anglePerSection = (2 * pi) / numbers.length;
    double normalizedAngle = (handAngle - startAngle + 2 * pi) % (2 * pi);
    int index = (normalizedAngle / anglePerSection).floor();
    return index % numbers.length;
  }

  void _startRefreshTimer() {
    // คำนวณเวลาถึง 23:56
    DateTime now = DateTime.now();
    DateTime nextRefreshTime =
        DateTime(now.year, now.month, now.day, 23, 56, 0);

    // ถ้าเวลาปัจจุบันเกิน 23:56 แล้ว ให้ไปยังวันถัดไป
    if (now.isAfter(nextRefreshTime)) {
      nextRefreshTime = nextRefreshTime.add(Duration(days: 1));
    }

    // คำนวณเวลาที่ต้องรอ
    Duration initialDelay = nextRefreshTime.difference(now);

    // ตั้ง Timer แรก
    Timer(initialDelay, () {
      fetchData(); // รีเฟรชข้อมูลครั้งแรก

      // ตั้ง Timer วนซ้ำทุกๆ 1360 นาที
      _refreshTimer = Timer.periodic(Duration(minutes: 1360), (timer) {
        fetchData();
      });
    });
  }

  void _startCurrentTimeTimer() {
    _timeUpdateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
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
    _apiTimer?.cancel(); // ยกเลิก Timer สำหรับเรียก API
    _timeUpdateTimer?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  String _getBackgroundImage() {
    final hour = _currentTime.hour;
    if (hour >= 6 && hour <= 18) {
      return 'assets/sky.jpg'; // Daytime image
    } else {
      return 'assets/night.jpg'; // Nighttime image
    }
  }

  @override
  Widget build(BuildContext context) {
    final secondAngle = _calculateHandAngle(_currentTime.second, 60);
    final minuteAngle = _calculateHandAngle(_currentTime.minute, 60);
    final hourAngle = _calculateHandAngle(
        (_currentTime.hour % 12) * 60 + _currentTime.minute, 12 * 60);

    final hourHandIndex = _findCurrentNumberForHand(hourAngle, innerNumbers);
    final hourHandNumber = innerNumbers.isNotEmpty
        ? innerNumbers[hourHandIndex]
        : ''; // ป้องกัน null error
    final minuteHandIndex =
        _findCurrentNumberForHand(minuteAngle, innerNumbers);
    final minuteHandNumber =
        innerNumbers.isNotEmpty ? innerNumbers[minuteHandIndex] : '';
    print('เข็มชั่วโมงชี้เลข: $hourHandNumber');
    print('เข็มนาทีชี้เลข: $minuteHandNumber');
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'กำลังโหลดข้อมูล...',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }
    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              SizedBox(height: 20),
              Text(
                'ไม่สามารถโหลดข้อมูลได้',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
              ElevatedButton(
                onPressed: fetchData,
                child: Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(_getBackgroundImage(),
                    width: 580, height: 740, fit: BoxFit.cover),
                Positioned(
                  top: 220,
                  left: 0,
                  right: 0,
                  child: _images.isNotEmpty
                      ? Image.network(
                          _images.first,
                          width: 350,
                          height: 350,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return CircularProgressIndicator();
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading image: $error');
                            return Text('โหลดรูปภาพล้มเหลว');
                          },
                        )
                      : CircularProgressIndicator(),
                ),
                _buildArrowHand(
                  angle: secondAngle,
                  color: Colors.red,
                  length: 150,
                  thickness: 2,
                  offset: Offset(0, 10),
                ),
                _buildArrowHand(
                  angle: minuteAngle,
                  color: Colors.blue,
                  length: 130,
                  thickness: 4,
                  offset: Offset(0, 15),
                ),
                _buildArrowHand(
                  angle: hourAngle,
                  color: Colors.black,
                  length: 95,
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
