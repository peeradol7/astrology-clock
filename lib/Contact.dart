import 'package:dooduang/SelectBirthday.dart';
import 'package:dooduang/clock.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เลือกรายการ'),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ImageSlider()),
                );
              },
              child: Text('ดูนาฬิกา'),
            ),
            SizedBox(width: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CalculateNumber()),
                );
              },
              child: Text('ไปที่ Lobby'),
            ),
          ],
        ),
      ),
    );
  }
}
