import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scribble/scribble.dart';

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  late ScribbleNotifier notifier;

  @override
  void initState() {
    super.initState();
    notifier = ScribbleNotifier();
  }

  @override
  void dispose() {
    notifier.dispose();
    super.dispose();
  }

  Future<void> _saveAndReturn() async {
    final scribbleBytes = (await notifier.renderImage()).buffer.asUint8List();
    final strokeImage = await decodeImageFromList(scribbleBytes);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final width = strokeImage.width.toDouble();
    final height = strokeImage.height.toDouble();

    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = Colors.white,
    );
    canvas.drawImage(strokeImage, Offset.zero, Paint());

    final composed = await recorder.endRecording().toImage(
      strokeImage.width,
      strokeImage.height,
    );
    final pngData = await composed.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (pngData == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final bytes = pngData.buffer.asUint8List();

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'drawing_${DateTime.now().millisecondsSinceEpoch}.png';
    final p = '${directory.path}/$fileName';
    await File(p).writeAsBytes(bytes);

    if (mounted) {
      Navigator.pop(context, p);
    }
  }

  Color _selectedColor = Colors.black;
  bool _isEraser = false;

  void _setColor(Color color) {
    setState(() {
      _selectedColor = color;
      _isEraser = false;
      notifier.setColor(color);
    });
  }

  void _setEraser() {
    setState(() {
      _isEraser = true;
      notifier.setEraser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Dessin', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => notifier.clear(),
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: notifier.canUndo ? () => notifier.undo() : null,
          ),
          IconButton(icon: const Icon(Icons.check), onPressed: _saveAndReturn),
        ],
      ),
      body: Stack(
        children: [
          Scribble(notifier: notifier, drawPen: true),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildColorButton(Colors.black),
                _buildColorButton(Colors.red),
                _buildColorButton(Colors.blue),
                _buildColorButton(Colors.green),
                IconButton(
                  icon: const Icon(Icons.cleaning_services),
                  onPressed: _setEraser,
                  color: _isEraser ? Colors.blue : Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    final isSelected = !_isEraser && _selectedColor == color;
    return GestureDetector(
      onTap: () {
        _setColor(color);
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.blueAccent, width: 3)
              : null,
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
      ),
    );
  }
}
