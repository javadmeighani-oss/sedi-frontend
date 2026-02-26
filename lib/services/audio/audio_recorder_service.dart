/// Stage 24 UX Fix Pack 01: MVP audio recording to a local file.
/// Fail-safe: permission denied or errors do not crash; callers handle feedback.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentPath;

  bool get isRecording => _isRecording;

  /// Request microphone permission if needed. Returns true if granted/already granted.
  Future<bool> ensurePermission() async {
    try {
      final granted = await _recorder.hasPermission();
      return granted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AudioRecorderService] ensurePermission error: $e');
      }
      return false;
    }
  }

  /// Start recording to a temp file. Call [ensurePermission] first.
  Future<void> start() async {
    if (_isRecording) return;
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/sedi_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentPath = path;
      await _recorder.start(const RecordConfig(), path: path);
      _isRecording = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AudioRecorderService] start error: $e');
      }
      _currentPath = null;
      rethrow;
    }
  }

  /// Stop recording and return the file path, or null on error/cancel.
  Future<String?> stop() async {
    if (!_isRecording) return null;
    try {
      final path = await _recorder.stop();
      _isRecording = false;
      final p = path ?? _currentPath;
      _currentPath = null;
      if (p != null && File(p).existsSync()) return p;
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AudioRecorderService] stop error: $e');
      }
      _isRecording = false;
      _currentPath = null;
      return null;
    }
  }

  /// Dispose the recorder (e.g. when closing the app).
  Future<void> dispose() async {
    try {
      if (_isRecording) await _recorder.stop();
      await _recorder.dispose();
    } catch (_) {}
  }
}
