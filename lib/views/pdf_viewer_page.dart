import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerPage extends StatefulWidget {
  final String pdfUrl;

  PdfViewerPage(this.pdfUrl);

  @override
  _PdfViewerPageState createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late PdfViewerController _pdfViewerController;
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _pdfViewerController.addListener(() {
      setState(() {
        currentPage = _pdfViewerController.pageNumber;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    print('PDF URL: ${widget.pdfUrl}'); // Print the URL to debug console

    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Viewer'),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          Expanded(
            child: SfPdfViewer.network(
              widget.pdfUrl,
              controller: _pdfViewerController,
            ),
          ),
          _buildPageIndicator(),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              _pdfViewerController.previousPage();
            },
          ),
          Text("Page $currentPage"),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: () {
              _pdfViewerController.nextPage();
            },
          ),
        ],
      ),
    );
  }
}
