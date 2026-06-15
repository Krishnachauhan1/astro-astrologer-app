import 'dart:typed_data';

import 'package:astrosarthi_konnect_astrologer_app/servicess/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfx/pdfx.dart';

Future<void> openVastuAttachment(
  BuildContext context, {
  required int homeMapId,
  String? attachmentType,
  String? fileName,
}) async {
  if (!context.mounted) return;

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => VastuAttachmentLoaderScreen(
        homeMapId: homeMapId,
        attachmentType: attachmentType,
        fileName: fileName ?? 'Home map',
      ),
    ),
  );
}

class VastuAttachmentLoaderScreen extends StatefulWidget {
  final int homeMapId;
  final String? attachmentType;
  final String fileName;

  const VastuAttachmentLoaderScreen({
    super.key,
    required this.homeMapId,
    this.attachmentType,
    required this.fileName,
  });

  @override
  State<VastuAttachmentLoaderScreen> createState() =>
      _VastuAttachmentLoaderScreenState();
}

class _VastuAttachmentLoaderScreenState
    extends State<VastuAttachmentLoaderScreen> {
  bool _loading = true;
  String? _error;
  Uint8List? _bytes;
  bool _isPdf = false;

  @override
  void initState() {
    super.initState();
    _fetchAttachment();
  }

  Future<void> _fetchAttachment() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiService.download(
        '/vastu/home-map/${widget.homeMapId}/attachment',
      );

      if (response.statusCode != 200) {
        String message = 'Attachment load failed (${response.statusCode})';
        try {
          final body = response.body;
          if (body.contains('message')) {
            message = body;
          }
        } catch (_) {}
        throw Exception(message);
      }

      final bytes = response.bodyBytes;
      if (bytes.isEmpty) {
        throw Exception('Attachment file empty hai');
      }

      final type = widget.attachmentType?.toLowerCase() ?? '';
      final isPdf = type == 'pdf' ||
          widget.fileName.toLowerCase().endsWith('.pdf') ||
          _looksLikePdf(bytes);

      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _isPdf = isPdf;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  bool _looksLikePdf(Uint8List bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName, overflow: TextOverflow.ellipsis),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _fetchAttachment,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final bytes = _bytes;
    if (bytes == null) {
      return const Center(child: Text('No attachment data'));
    }

    if (_isPdf) {
      return VastuPdfMemoryViewer(bytes: bytes, title: widget.fileName);
    }

    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4,
        child: Image.memory(bytes, fit: BoxFit.contain),
      ),
    );
  }
}

class VastuPdfMemoryViewer extends StatefulWidget {
  final Uint8List bytes;
  final String title;

  const VastuPdfMemoryViewer({
    super.key,
    required this.bytes,
    required this.title,
  });

  @override
  State<VastuPdfMemoryViewer> createState() => _VastuPdfMemoryViewerState();
}

class _VastuPdfMemoryViewerState extends State<VastuPdfMemoryViewer> {
  PdfControllerPinch? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _openPdf();
  }

  Future<void> _openPdf() async {
    try {
      if (!mounted) return;
      setState(() {
        _controller = PdfControllerPinch(
          document: PdfDocument.openData(widget.bytes),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      Get.snackbar('PDF', 'PDF open nahi ho paya');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }

    final controller = _controller;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return PdfViewPinch(controller: controller);
  }
}
