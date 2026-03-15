import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';

class AudioRecorderWidget extends StatefulWidget {
  final String? initialAudioPath;
  final ValueChanged<String?> onAudioSaved;

  const AudioRecorderWidget({
    super.key,
    this.initialAudioPath,
    required this.onAudioSaved,
  });

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  late final AudioRecorder _audioRecorder;
  late final AudioPlayer _audioPlayer;

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _audioPath;

  // Durées
  Timer? _recordTimer;
  int _recordDuration = 0;
  Duration _totalDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();
    _audioPath = widget.initialAudioPath;

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() => _totalDuration = duration);
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() => _currentPosition = position);
      }
    });

    if (_audioPath != null) {
      _audioPlayer.setSourceDeviceFile(_audioPath!);
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path =
            '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() {
          _isRecording = true;
          _audioPath = path;
          _recordDuration = 0;
        });
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() => _recordDuration++);
          }
        });
      }
    } catch (e) {
      // Ignorer ou afficher une erreur
    }
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      if (path != null) {
        _audioPath = path;
        widget.onAudioSaved(path);
        _audioPlayer.setSourceDeviceFile(path);
      }
    });
  }

  Future<void> _deleteRecording() async {
    if (_audioPath != null) {
      final file = File(_audioPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    setState(() {
      _audioPath = null;
      _totalDuration = Duration.zero;
      _currentPosition = Duration.zero;
      _recordDuration = 0;
      widget.onAudioSaved(null);
    });
  }

  Future<void> _togglePlay() async {
    if (_audioPath == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Audio Recorder',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              if (_audioPath == null || _isRecording) ...[
                IconButton(
                  icon: Icon(
                    _isRecording
                        ? Icons.stop_circle_rounded
                        : Icons.mic_rounded,
                    color: _isRecording ? Colors.redAccent : Colors.blueAccent,
                    size: 32,
                  ),
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                ),
                const SizedBox(width: 8),
                Text(
                  _isRecording
                      ? _formatDuration(_recordDuration)
                      : 'Appuyez pour enregistrer',
                  style: TextStyle(
                    color: _isRecording
                        ? Colors.redAccent
                        : Colors.white.withValues(alpha: 0.7),
                    fontWeight: _isRecording
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                if (_audioPath != null && !_isRecording) ...[
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.white54,
                    ),
                    onPressed: _deleteRecording,
                  ),
                ],
              ] else ...[
                IconButton(
                  icon: Icon(
                    _isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    color: Colors.greenAccent,
                    size: 32,
                  ),
                  onPressed: _togglePlay,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_currentPosition.inSeconds),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDuration(_totalDuration.inSeconds),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: _totalDuration.inMilliseconds > 0
                            ? _currentPosition.inMilliseconds /
                                  _totalDuration.inMilliseconds
                            : 0.0,
                        backgroundColor: Colors.white24,
                        color: Colors.greenAccent,
                        borderRadius: BorderRadius.circular(2),
                        minHeight: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white54),
                  onPressed: _deleteRecording,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
