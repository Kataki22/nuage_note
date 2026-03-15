import 'package:flutter/material.dart';
import 'package:scribble/scribble.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
    final imageByteData = await notifier.renderImage();

    final bytes = imageByteData.buffer.asUint8List();

    // Sauvegarder dans le stockage de l'app
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'drawing_${DateTime.now().millisecondsSinceEpoch}.png';
    final p = '${directory.path}/$fileName';
    final file = File(p);
    await file.writeAsBytes(bytes);

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
