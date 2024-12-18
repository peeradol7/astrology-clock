import 'dart:io';

import 'package:dooduang/CheckSlipController.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CheckSlipWidget extends StatefulWidget {
  @override
  _CheckSlipWidgetState createState() => _CheckSlipWidgetState();
}

class _CheckSlipWidgetState extends State<CheckSlipWidget> {
  File? _selectedImage;
  final CheckSlipController _controller = CheckSlipController();
  bool _isValidating = false;
  String _validationResult = '';

  Future<void> _pickImage() async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _validateSlip() async {
    if (_selectedImage == null) return;

    setState(() {
      _isValidating = true;
      _validationResult = '';
    });

    try {
      bool isValid = await _controller.validateSlip(_selectedImage!);

      setState(() {
        _validationResult =
            isValid ? 'Slip Validated Successfully' : 'Invalid Slip';
        _isValidating = false;
      });
    } catch (e) {
      setState(() {
        _validationResult = 'Validation Error';
        _isValidating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Check Slip Validation'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // QR Code Image Placeholder
            Image.asset(
              'assets/images/qr_code.png',
              width: 200,
              height: 200,
            ),
            SizedBox(height: 20),

            // Image Selection Button
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Select Slip Image'),
            ),

            // Selected Image Preview
            if (_selectedImage != null)
              Image.file(
                _selectedImage!,
                width: 150,
                height: 150,
              ),

            // Validate Button
            ElevatedButton(
              onPressed: _selectedImage != null ? _validateSlip : null,
              child: _isValidating
                  ? CircularProgressIndicator()
                  : Text('Validate Slip'),
            ),

            // Validation Result
            if (_validationResult.isNotEmpty)
              Text(
                _validationResult,
                style: TextStyle(
                  color: _validationResult.contains('Successfully')
                      ? Colors.green
                      : Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
