import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

/// Pure helpers for a single-source OTP code field.
class OtpInputHelper {
  OtpInputHelper._();

  static const int codeLength = 6;

  /// ASCII `0-9`, Persian `۰-۹` (U+06F0–U+06F9), Arabic-Indic `٠-٩` (U+0660–U+0669).
  static String? asciiDigitFromRune(int rune) {
    if (rune >= 0x30 && rune <= 0x39) {
      return String.fromCharCode(rune);
    }
    if (rune >= 0x06F0 && rune <= 0x06F9) {
      return String.fromCharCode(0x30 + (rune - 0x06F0));
    }
    if (rune >= 0x0660 && rune <= 0x0669) {
      return String.fromCharCode(0x30 + (rune - 0x0660));
    }
    return null;
  }

  /// Normalize Unicode decimal digits → ASCII, drop non-digits.
  /// When [cap] is set (default [codeLength]), truncate to that many digits.
  static String extractDigits(String raw, {int? cap = codeLength}) {
    final out = StringBuffer();
    for (final rune in raw.runes) {
      final digit = asciiDigitFromRune(rune);
      if (digit == null) continue;
      out.write(digit);
      if (cap != null && out.length >= cap) break;
    }
    return out.toString();
  }

  /// Normalize Unicode decimal digits → ASCII, drop non-digits, cap at [codeLength].
  static String sanitize(String raw) => extractDigits(raw);

  static bool isComplete(String code) => sanitize(code).length == codeLength;

  static String digitAt(String code, int index) {
    final sanitized = sanitize(code);
    if (index < 0 || index >= sanitized.length) return '';
    return sanitized[index];
  }

  static String replaceDigit(String code, int index, String digit) {
    final sanitized = sanitize(code);
    final incoming = sanitize(digit);
    if (incoming.isEmpty || index < 0 || index >= codeLength) {
      return sanitized;
    }
    final ch = incoming[0];
    if (index < sanitized.length) {
      return sanitized.substring(0, index) + ch + sanitized.substring(index + 1);
    }
    if (index == sanitized.length && sanitized.length < codeLength) {
      return sanitized + ch;
    }
    return sanitized;
  }

  static String deleteAt(String code, int index) {
    final sanitized = sanitize(code);
    if (index < 0 || index >= sanitized.length) return sanitized;
    return sanitized.substring(0, index) + sanitized.substring(index + 1);
  }

  /// Slot that owns the caret / selection. Tapping never truncates the code.
  static int activeSlotFromSelection(String code, TextSelection selection) {
    final sanitized = sanitize(code);
    if (!selection.isValid) {
      return sanitized.length.clamp(0, codeLength - 1).toInt();
    }
    final start = selection.start < selection.end
        ? selection.start
        : selection.end;
    return start.clamp(0, codeLength - 1).toInt();
  }

  /// Select the digit in [slot] so the next key replaces only that digit.
  /// Empty / beyond-end slots collapse at the first empty position.
  static TextSelection selectionForSlot(String code, int slot) {
    final sanitized = sanitize(code);
    final i = slot.clamp(0, codeLength - 1).toInt();
    if (i < sanitized.length) {
      return TextSelection(baseOffset: i, extentOffset: i + 1);
    }
    return TextSelection.collapsed(offset: sanitized.length);
  }

  /// Selection-aware edit: replace one slot, backspace, or paste/autofill.
  static TextEditingValue applyEdit({
    required TextEditingValue oldValue,
    required TextEditingValue newValue,
  }) {
    final oldSan = sanitize(oldValue.text);
    final newAll = extractDigits(newValue.text, cap: null);
    final newSan = newAll.length > codeLength
        ? newAll.substring(0, codeLength)
        : newAll;

    var start = oldSan.length;
    var end = oldSan.length;
    if (oldValue.selection.isValid) {
      start = oldValue.selection.start.clamp(0, oldSan.length).toInt();
      end = oldValue.selection.end.clamp(0, oldSan.length).toInt();
      if (end < start) {
        final tmp = start;
        start = end;
        end = tmp;
      }
    }

    final inserted = _insertedDigits(oldSan, newAll, start, end);

    // A 6-digit paste/autofill always replaces the entire OTP, even if a
    // middle slot is selected. Never splice (123456 + paste 654321 ≠ 126543).
    if (inserted.length >= codeLength) {
      final text = sanitize(inserted);
      return _collapsed(text, text.length);
    }

    if (newSan.length == codeLength &&
        oldSan != newSan &&
        inserted.length != 1 &&
        (oldSan.isEmpty || newAll.length >= codeLength)) {
      return _collapsed(newSan, newSan.length);
    }

    if (inserted.length > 1) {
      final text = sanitize(oldSan.substring(0, start) + inserted + oldSan.substring(end));
      return _collapsed(text, text.length);
    }

    if (oldSan.isEmpty && newSan.length > 1) {
      return _collapsed(newSan, newSan.length);
    }

    if (inserted.isEmpty && newSan.length < oldSan.length) {
      if (end > start) {
        final text = oldSan.substring(0, start) + oldSan.substring(end);
        return _collapsed(text, start);
      }
      if (start > 0) {
        final delAt = start - 1;
        return _collapsed(deleteAt(oldSan, delAt), delAt);
      }
      return _collapsed(oldSan, 0);
    }

    if (inserted.isEmpty) {
      if (newSan == oldSan) {
        final sel = oldValue.selection.isValid
            ? TextSelection(
                baseOffset: oldValue.selection.start.clamp(0, oldSan.length).toInt(),
                extentOffset: oldValue.selection.end.clamp(0, oldSan.length).toInt(),
              )
            : TextSelection.collapsed(offset: oldSan.length);
        return TextEditingValue(
          text: oldSan,
          selection: sel,
          composing: TextRange.empty,
        );
      }
      return _collapsed(newSan, newSan.length);
    }

    final digit = inserted[0];
    if (end > start) {
      final text =
          sanitize(oldSan.substring(0, start) + digit + oldSan.substring(end));
      return TextEditingValue(
        text: text,
        selection: selectionForSlot(text, (start + 1).clamp(0, codeLength - 1).toInt()),
        composing: TextRange.empty,
      );
    }
    if (start < oldSan.length) {
      // Collapsed caret (e.g. after deleting a middle digit): INSERT, shift later
      // digits right. Do not replace the following digit.
      final text = sanitize(
        oldSan.substring(0, start) + digit + oldSan.substring(start),
      );
      return _collapsed(text, (start + 1).clamp(0, text.length).toInt());
    }
    if (oldSan.length < codeLength) {
      final text = oldSan + digit;
      final next = text.length < codeLength ? text.length : codeLength - 1;
      return TextEditingValue(
        text: text,
        selection: selectionForSlot(text, next),
        composing: TextRange.empty,
      );
    }
    return TextEditingValue(
      text: oldSan,
      selection: selectionForSlot(oldSan, codeLength - 1),
      composing: TextRange.empty,
    );
  }

  static TextEditingValue _collapsed(String text, int caret) {
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: caret.clamp(0, text.length).toInt()),
      composing: TextRange.empty,
    );
  }

  static String _insertedDigits(
    String oldSan,
    String newAll,
    int start,
    int end,
  ) {
    final prefix = oldSan.substring(0, start);
    final suffix = oldSan.substring(end);
    if (newAll.startsWith(prefix)) {
      if (suffix.isEmpty) {
        return newAll.substring(prefix.length);
      }
      if (newAll.endsWith(suffix) &&
          newAll.length >= prefix.length + suffix.length) {
        return newAll.substring(prefix.length, newAll.length - suffix.length);
      }
    }
    if (oldSan.isEmpty) return newAll;
    if (newAll.length >= codeLength && newAll != oldSan) {
      return newAll.substring(0, codeLength);
    }
    return '';
  }
}

/// Accepts ASCII / Persian / Arabic-Indic digits; stores ASCII only.
/// Selection-aware: a filled slot replaces only that digit; paste fills all six.
class OtpDigitInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return OtpInputHelper.applyEdit(oldValue: oldValue, newValue: newValue);
  }
}

/// Where the olive caret sits inside an OTP slot.
enum OtpCaretPlacement {
  /// Empty active slot — centered, subtle.
  emptyCenter,

  /// User-tapped filled slot — thin bar beside the digit, never overlapping.
  filledBeside,
}

/// Subtle ~1px olive caret for the active edit position only.
class OtpSlotCaret extends StatelessWidget {
  static const double thickness = 1;

  final double height;
  final OtpCaretPlacement placement;

  const OtpSlotCaret({
    super.key,
    required this.height,
    required this.placement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: thickness,
      height: height,
      color: AppTheme.gate2ButtonOlive.withOpacity(0.45),
    );
  }
}

/// Autofill-friendly OTP entry with a six-box visual layout.
///
/// Uses one [TextEditingController] as the source of truth so OS one-time-code
/// autofill, paste, and manual typing all populate every box consistently.
/// Digit slots are tappable; the tapped slot becomes active without truncating.
class Gate2OtpInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  const Gate2OtpInput({
    super.key,
    required this.controller,
    required this.focusNode,
    this.enabled = true,
    this.onChanged,
  });

  @override
  State<Gate2OtpInput> createState() => _Gate2OtpInputState();
}

class _Gate2OtpInputState extends State<Gate2OtpInput> {
  /// True only after an explicit slot tap, until the next text mutation.
  bool _slotTapped = false;
  String _lastCode = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
    widget.focusNode.addListener(_handleFocusChanged);
    _lastCode = OtpInputHelper.sanitize(widget.controller.text);
  }

  @override
  void didUpdateWidget(covariant Gate2OtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
      _lastCode = OtpInputHelper.sanitize(widget.controller.text);
      _slotTapped = false;
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      widget.focusNode.addListener(_handleFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    widget.focusNode.removeListener(_handleFocusChanged);
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) setState(() {});
  }

  void _handleControllerChanged() {
    final sanitized = OtpInputHelper.sanitize(widget.controller.text);
    if (sanitized != widget.controller.text) {
      widget.controller.value = OtpInputHelper.applyEdit(
        oldValue: widget.controller.value,
        newValue: widget.controller.value.copyWith(text: sanitized),
      );
      return;
    }
    if (sanitized != _lastCode) {
      _slotTapped = false;
      _lastCode = sanitized;
    }
    if (mounted) setState(() {});
    widget.onChanged?.call(sanitized);
  }

  void _ensureFocus() {
    if (!widget.enabled) return;
    if (!widget.focusNode.hasFocus) {
      widget.focusNode.requestFocus();
    }
    // Back dismisses the Android IME without dropping focus. requestFocus()
    // is then a no-op, so the keyboard must be shown explicitly on every tap.
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  /// Tap a slot to activate it. Never truncates later digits.
  void _onSlotTap(int index) {
    if (!widget.enabled) return;
    _ensureFocus();
    _slotTapped = true;
    final code = OtpInputHelper.sanitize(widget.controller.text);
    final next = OtpInputHelper.selectionForSlot(code, index);
    if (widget.controller.selection != next) {
      widget.controller.selection = next;
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final layout = _OtpBoxLayout.compute(maxWidth);
        final code = OtpInputHelper.sanitize(widget.controller.text);
        final selection = widget.controller.selection;
        final completeIdle = code.length == OtpInputHelper.codeLength &&
            selection.isCollapsed &&
            selection.extentOffset >= code.length &&
            !_slotTapped;
        final activeSlot = widget.enabled &&
                widget.focusNode.hasFocus &&
                !completeIdle
            ? OtpInputHelper.activeSlotFromSelection(code, selection)
            : -1;

        return AutofillGroup(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _ensureFocus,
              child: SizedBox(
                width: maxWidth,
                height: layout.boxSize + 8,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: TextField(
                          controller: widget.controller,
                          focusNode: widget.focusNode,
                          enabled: widget.enabled,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          enableSuggestions: false,
                          autocorrect: false,
                          showCursor: false,
                          style: const TextStyle(
                            color: Colors.transparent,
                            fontSize: 1,
                            height: 1,
                          ),
                          strutStyle: const StrutStyle(height: 1, fontSize: 1),
                          inputFormatters: [
                            // Must NOT use digitsOnly — that strips Persian/Arabic
                            // digits before normalization can run.
                            OtpDigitInputFormatter(),
                          ],
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          onChanged: (raw) {
                            widget.onChanged?.call(OtpInputHelper.sanitize(raw));
                          },
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        OtpInputHelper.codeLength,
                        (index) {
                          return GestureDetector(
                            key: ValueKey('a2-otp-slot-$index'),
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _onSlotTap(index),
                            child: _OtpDigitBox(
                              digit: OtpInputHelper.digitAt(code, index),
                              size: layout.boxSize,
                              gap: layout.gap,
                              isLast: index == OtpInputHelper.codeLength - 1,
                              active: index == activeSlot,
                              showCaret: index == activeSlot &&
                                  (OtpInputHelper.digitAt(code, index).isEmpty ||
                                      _slotTapped),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OtpBoxLayout {
  final double boxSize;
  final double gap;

  const _OtpBoxLayout({required this.boxSize, required this.gap});

  static _OtpBoxLayout compute(double maxWidth) {
    const count = OtpInputHelper.codeLength;
    const minBox = 32.0;
    const maxBox = 46.0;
    const minGap = 4.0;
    const maxGap = 8.0;

    var gap = maxGap;
    var boxSize = ((maxWidth - gap * (count - 1)) / count)
        .clamp(minBox, maxBox)
        .toDouble();
    var total = boxSize * count + gap * (count - 1);

    while (total > maxWidth && gap > minGap) {
      gap -= 1;
      boxSize = ((maxWidth - gap * (count - 1)) / count)
          .clamp(minBox, maxBox)
          .toDouble();
      total = boxSize * count + gap * (count - 1);
    }

    while (total > maxWidth && boxSize > minBox) {
      boxSize -= 1;
      total = boxSize * count + gap * (count - 1);
    }

    return _OtpBoxLayout(boxSize: boxSize, gap: gap);
  }
}

class _OtpDigitBox extends StatelessWidget {
  final String digit;
  final double size;
  final double gap;
  final bool isLast;
  final bool active;
  final bool showCaret;

  const _OtpDigitBox({
    required this.digit,
    required this.size,
    required this.gap,
    required this.isLast,
    required this.active,
    required this.showCaret,
  });

  @override
  Widget build(BuildContext context) {
    final caretHeight = (size * 0.42).clamp(14, 20).toDouble();
    final placement = digit.isEmpty
        ? OtpCaretPlacement.emptyCenter
        : OtpCaretPlacement.filledBeside;
    final digitStyle = TextStyle(
      color: AppTheme.gate2TextPrimary,
      fontSize: (size * 0.42).clamp(14, 20).toDouble(),
      fontWeight: FontWeight.w600,
    );

    return Container(
      width: size,
      height: size + 4,
      margin: EdgeInsets.only(right: isLast ? 0 : gap),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.gate2InputFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? AppTheme.gate2ButtonOlive : AppTheme.gate2BorderSubtle,
          width: active ? 1.2 : 0.8,
        ),
      ),
      child: showCaret && digit.isEmpty
          ? OtpSlotCaret(height: caretHeight, placement: placement)
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (digit.isNotEmpty) Text(digit, style: digitStyle),
                if (showCaret && digit.isNotEmpty) ...[
                  const SizedBox(width: 1),
                  OtpSlotCaret(height: caretHeight, placement: placement),
                ],
              ],
            ),
    );
  }
}
