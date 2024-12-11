import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class CalculateNumber extends StatefulWidget {
  @override
  _CalculateNumberState createState() => _CalculateNumberState();
}

class _CalculateNumberState extends State<CalculateNumber> {
  final TextEditingController _controller = TextEditingController();
  final PdfViewerController _pdfController = PdfViewerController();
  int _pageNumber = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View PDF Page'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter Page Number',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _pageNumber = int.tryParse(_controller.text) ?? 1;
                _pdfController.jumpToPage(_pageNumber);
              });
            },
            child: Text('Go to Page'),
          ),
          Expanded(
            child: SfPdfViewer.asset(
              'assets/sample.pdf',
              controller: _pdfController,
            ),
          ),
        ],
      ),
    );
  }
}
