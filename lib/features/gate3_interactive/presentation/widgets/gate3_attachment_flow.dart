import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/memory/memory_attachment.dart';
import '../../../../core/memory/memory_attachments_service.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/theme/app_theme.dart';
import '../gate3_localization.dart';
import '../gate3_memory_l10n.dart';

enum Gate3AttachmentSource { camera, gallery, file }

class _Picked {
  const _Picked(this.bytes, this.name, this.mime);
  final List<int> bytes;
  final String name;
  final String mime;
}

/// R-021 / M4: documents, images and voice from the chat box.
///
/// Documents/images: pick -> upload -> Sedi reads it -> a result sheet where the USER decides to keep it in memory,
/// talk about it, or delete it. Voice: record -> transcribe -> the transcript is put in the composer (never auto-sent).
class Gate3AttachmentFlow {
  Gate3AttachmentFlow({MemoryAttachmentsService? service})
      : _service = service ?? MemoryAttachmentsService();

  final MemoryAttachmentsService _service;
  final ImagePicker _imagePicker = ImagePicker();

  static String mimeForName(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    if (n.endsWith('.pdf')) return 'application/pdf';
    if (n.endsWith('.m4a') || n.endsWith('.mp4')) return 'audio/mp4';
    if (n.endsWith('.aac')) return 'audio/aac';
    if (n.endsWith('.wav')) return 'audio/wav';
    if (n.endsWith('.ogg')) return 'audio/ogg';
    if (n.endsWith('.webm')) return 'audio/webm';
    if (n.endsWith('.mp3')) return 'audio/mpeg';
    return 'image/jpeg';
  }

  static String errorText(Gate3Localization l10n, ApiResponse<dynamic> r) {
    final m = (r.error?.message ?? '').toUpperCase();
    if (m.contains('FEATURE_DISABLED')) return l10n.attachDisabled;
    if (m.contains('MEMORY_WRITE_NOT_GRANTED')) return l10n.attachConsentNeeded;
    return l10n.attachFailed;
  }

  static void _toast(ScaffoldMessengerState messenger, String text) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 96, left: 16, right: 16),
      ),
    );
  }

  Future<_Picked?> _pick(Gate3AttachmentSource source) async {
    try {
      if (source == Gate3AttachmentSource.file) {
        final res = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
          withData: true,
        );
        if (res == null || res.files.isEmpty) return null;
        final f = res.files.first;
        final bytes = f.bytes;
        if (bytes == null) return null;
        return _Picked(bytes, f.name, mimeForName(f.name));
      }
      final x = await _imagePicker.pickImage(
        source: source == Gate3AttachmentSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 2200,
        imageQuality: 85,
      );
      if (x == null) return null;
      final bytes = await x.readAsBytes();
      return _Picked(bytes, x.name, mimeForName(x.name));
    } catch (_) {
      return null;
    }
  }

  /// Runs the whole document flow. [onTalk] receives a message to send to the chat when the user chooses to talk about it.
  Future<void> runDocument(
    BuildContext context,
    String lang,
    Gate3AttachmentSource source, {
    required ValueChanged<String> onTalk,
  }) async {
    final l10n = Gate3Localization(lang);
    final messenger = ScaffoldMessenger.of(context);
    final picked = await _pick(source);
    if (picked == null) return;
    _toast(messenger, l10n.attachUploading);
    final up = await _service.upload(
      bytes: picked.bytes,
      filename: picked.name,
      mimeType: picked.mime,
    );
    final uploaded = up.data;
    if (!up.ok || uploaded == null) {
      _toast(messenger, errorText(l10n, up));
      return;
    }
    _toast(messenger, l10n.attachReading);
    final done = await _service.process(uploaded.id);
    messenger.hideCurrentSnackBar();
    final result = done.data;
    if (!done.ok || result == null) {
      _toast(messenger, errorText(l10n, done));
      return;
    }
    if (!context.mounted) return;
    await _showResult(context, l10n, result, onTalk);
  }

  /// Uploads a recorded voice file, returns the transcript (or null). The server drops the audio after transcribing.
  Future<String?> transcribeVoice(
    BuildContext context,
    String lang,
    String path,
  ) async {
    final l10n = Gate3Localization(lang);
    final messenger = ScaffoldMessenger.of(context);
    try {
      _toast(messenger, l10n.voiceTranscribing);
      final bytes = await File(path).readAsBytes();
      final up = await _service.upload(
        bytes: bytes,
        filename: 'voice.m4a',
        mimeType: mimeForName(path),
      );
      final uploaded = up.data;
      if (!up.ok || uploaded == null) {
        _toast(messenger, errorText(l10n, up));
        return null;
      }
      final done = await _service.process(uploaded.id);
      messenger.hideCurrentSnackBar();
      final text = (done.data?.transcript ?? done.data?.summary ?? '').trim();
      // The transcript becomes the user's message; the voice note record is not needed any more.
      _service.delete(uploaded.id);
      try {
        File(path).delete();
      } catch (_) {}
      if (!done.ok || text.isEmpty) {
        _toast(messenger, l10n.voiceFailed);
        return null;
      }
      return text;
    } catch (_) {
      _toast(messenger, l10n.voiceFailed);
      return null;
    }
  }

  Future<void> _showResult(
    BuildContext context,
    Gate3Localization l10n,
    MemoryAttachment item,
    ValueChanged<String> onTalk,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final summary = (item.summary ?? '').trim();
    final rawFindings = item.findings?['findings'];
    final findings = <String>[];
    if (rawFindings is List) {
      for (final f in rawFindings.take(12)) {
        if (f is Map) {
          final name = (f['name'] ?? '').toString();
          final value = (f['value'] ?? '').toString();
          final unit = (f['unit'] ?? '').toString();
          if (name.isEmpty) continue;
          findings.add('$name: $value $unit'.trim());
        }
      }
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppTheme.gate3PaleOliveBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.attachResultTitle,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    summary,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (findings.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      l10n.attachFindings,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    for (final line in findings)
                      Text(
                        line,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    l10n.attachNotAdvice,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final r = await _service.confirm(item.id);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        _toast(
                          messenger,
                          r.ok ? l10n.attachRemembered : errorText(l10n, r),
                        );
                      },
                      child: Text(l10n.attachRemember),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onTalk(l10n.attachTalkMessage(summary));
                      },
                      child: Text(l10n.attachTalk),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () async {
                        await _service.delete(item.id);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                      child: Text(l10n.attachDiscard),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
