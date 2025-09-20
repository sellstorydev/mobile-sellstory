import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';
import 'package:get/get.dart';

class PdfViewerPage extends StatefulWidget {
  final String url;
  final String? title;
  const PdfViewerPage({super.key, required this.url, this.title});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  PdfControllerPinch? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await http.get(Uri.parse(widget.url));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final bytes = res.bodyBytes;
      setState(() {
        _controller = PdfControllerPinch(document: PdfDocument.openData(Uint8List.fromList(bytes)));
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'failed_load_pdf'.trParams({'error': '$e'});
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'PDF')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : PdfViewPinch(controller: _controller!),
    );
  }
}
