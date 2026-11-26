import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/theme/sedi_glass.dart';
import '../../../../core/theme/sedi_palette.dart';
import '../../../../data/models/chat_link.dart';
import '../../../gate3_interactive/models/gate3_interaction_state.dart';
import '../../../gate3_interactive/presentation/widgets/sedi_hologram_orb.dart';

class MessageBubble extends StatefulWidget {
  final String message;
  final bool isSedi;
  final bool isFailed;
  final VoidCallback? onRetry;
  final VoidCallback? onEdit;
  final String? editLabel;
  final bool showTyping;

  /// Localized labels (EN defaults keep older call sites unchanged).
  final String? readMoreLabel;
  final String? readLessLabel;
  final String? retryLabel;

  /// R-073: one-tap answers drawn INSIDE Sedi's message box (Sedi messages only). A tap is sent as an ordinary chat message.
  final List<String> replies;
  final ValueChanged<String>? onReply;

  /// R-107 am.3: the doctor-introduction links of this Sedi message - blue underlined lines OUTSIDE (below) the glass panel;
  /// a tap opens the original site in the browser.
  final List<ChatLink> links;

  /// How a link is opened (tests replace it; the app uses the external browser).
  static Future<bool> Function(Uri uri) linkOpener = (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);

  /// Blue link ink: contrast >= 4.5:1 on the pistachio page.
  static const Color linkColor = Color(0xFF0B57D0);

  /// User bubble (D-127): the same pistachio glass as Sedi's sphere, with deep-olive ink (contrast >= 8:1).
  static const Color userTextColor = Color(0xFF1B2208);
  static const List<Color> userBubbleGradient = [
    SediPalette.pistachio300,
    SediPalette.pistachio500,
  ];

  /// Sedi's logo sphere diameter and the text metrics of a message line. Pilot V1 (R-034): her text sits in a
  /// see-through glass panel, every line of text (hers and the user's) is justified to the same width, and the
  /// logo is centred on the FIRST line of text so the logo, the text and the typing dots share one visual line.
  static const double sediLogoDiameter = 34;
  static const double _fontSize = 15;
  static const double _lineHeight = 1.7;
  static const double _panelPaddingV = 11;
  static const double _panelPaddingH = 15;
  static const double sediLogoTopInset =
      _panelPaddingV + _fontSize * _lineHeight / 2 - sediLogoDiameter / 2;

  /// First-strong-character direction for bidi-safe user text.
  static TextDirection resolveTextDirection(String text) {
    for (final rune in text.runes) {
      if (_isRtlLetter(rune)) return TextDirection.rtl;
      if (_isLtrLetter(rune)) return TextDirection.ltr;
    }
    return TextDirection.ltr;
  }

  static bool _isRtlLetter(int rune) {
    return (rune >= 0x0590 && rune <= 0x08FF) ||
        (rune >= 0xFB1D && rune <= 0xFDFF) ||
        (rune >= 0xFE70 && rune <= 0xFEFF);
  }

  static bool _isLtrLetter(int rune) {
    return (rune >= 0x0041 && rune <= 0x005A) ||
        (rune >= 0x0061 && rune <= 0x007A);
  }

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSedi,
    this.isFailed = false,
    this.onRetry,
    this.onEdit,
    this.editLabel,
    this.showTyping = false,
    this.readMoreLabel,
    this.readLessLabel,
    this.retryLabel,
    this.replies = const <String>[],
    this.onReply,
    this.links = const <ChatLink>[],
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _expanded = false;

  bool get _canCollapseUserMessage {
    if (widget.isSedi || widget.showTyping) return false;
    return widget.message.split('\n').length > 2 || widget.message.length > 120;
  }

  @override
  Widget build(BuildContext context) {
    // Physical sides, not locale-dependent directional START/END.
    final alignment =
        widget.isSedi ? Alignment.centerLeft : Alignment.centerRight;
    final shouldCollapse = _canCollapseUserMessage && !_expanded;
    // Sedi replies follow the app language (fa/ar are right-to-left even when a line starts with Latin text);
    // the user's own text keeps first-strong-character direction.
    final textDirection = widget.isSedi && SediLocaleController.instance.isRtl
        ? TextDirection.rtl
        : MessageBubble.resolveTextDirection(widget.message);

    // R-120 am.2: a doctor introduction is ONE bubble - the opening line, then each doctor with his link right under him, then the rest.
    final inBubble = widget.isSedi && !widget.showTyping ? widget.links.where((l) => l.inBubble).toList() : const <ChatLink>[];
    final outside = widget.links.where((l) => !l.inBubble || widget.showTyping).toList();
    final split = inBubble.isEmpty ? null : DoctorListSplit.of(widget.message, [for (final d in inBubble) d.title.split(' — ').first]);

    final text = widget.showTyping
        ? const _TypingDots()
        : split != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (split.head.isNotEmpty) _sediText(split.head, textDirection),
                  _DoctorList(doctors: inBubble, direction: textDirection),
                  if (split.tail.isNotEmpty) ...[const SizedBox(height: 8), _sediText(split.tail, textDirection)],
                ],
              )
            : Text(
            widget.message,
            maxLines: shouldCollapse ? 2 : null,
            overflow: shouldCollapse ? TextOverflow.ellipsis : null,
            textDirection: textDirection,
            // Every line the same width (the last line of a paragraph keeps its natural end).
            textAlign: TextAlign.justify,
            style: TextStyle(
              color: widget.isSedi
                  ? SediPalette.charcoal950
                  : MessageBubble.userTextColor,
              fontSize: MessageBubble._fontSize,
              height: MessageBubble._lineHeight,
              // D-127: about 15 % heavier than w500 (Javad's phone test) - the nearest weight step is w600.
              fontWeight: FontWeight.w600,
            ),
          );

    final column = Column(
      crossAxisAlignment:
          widget.isSedi ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        text,
        if (_canCollapseUserMessage) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded
                  ? (widget.readLessLabel ?? 'Read less')
                  : (widget.readMoreLabel ?? 'Read more'),
              style: const TextStyle(
                color: SediPalette.pistachio900,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        if (widget.isFailed && widget.onRetry != null) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: widget.onRetry,
            child: Text(
              widget.retryLabel ?? 'Tap to retry',
              style: const TextStyle(
                color: SediPalette.skin700,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        if (widget.isSedi && widget.replies.isNotEmpty && widget.onReply != null) ...[
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0x2948551F)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final reply in widget.replies)
                  _QuickReplyChip(label: reply, onTap: () => widget.onReply!(reply)),
              ],
            ),
          ),
        ],
      ],
    );

    final body = widget.isSedi
        ? column
        : Directionality(
            textDirection: textDirection,
            child: column,
          );

    final showEdit = !widget.isSedi &&
        !widget.showTyping &&
        widget.onEdit != null &&
        widget.message.trim().isNotEmpty;

    Widget? editAction;
    if (showEdit) {
      editAction = Tooltip(
        message: widget.editLabel ?? 'Edit',
        child: GestureDetector(
          onTap: widget.onEdit,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Align(
              alignment: Alignment.topLeft,
              child: Icon(
                Icons.edit_outlined,
                size: 16,
                color: SediPalette.sageMuted,
              ),
            ),
          ),
        ),
      );
    }

    // Assistant: a see-through glass panel (its own light edge, blur and soft shadow lift it off the page).
    if (widget.isSedi) {
      final radius = const BorderRadiusDirectional.only(
        topStart: Radius.circular(22),
        topEnd: Radius.circular(22),
        bottomEnd: Radius.circular(22),
        bottomStart: Radius.circular(6),
      ).resolve(Directionality.of(context));
      final panel = SediGlass.blur(
        radius: radius,
        child: DecoratedBox(
          decoration: SediGlass.messagePanel(radius),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MessageBubble._panelPaddingH,
              vertical: MessageBubble._panelPaddingV,
            ),
            child: body,
          ),
        ),
      );
      return Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 356),
            // Every Sedi message starts with her small hologram sphere (D-097).
            // The typing dots sit on the SAME line as her icon (D-101).
            child: Row(
              crossAxisAlignment: widget.showTyping
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: 8,
                    top: widget.showTyping
                        ? 0
                        : MessageBubble.sediLogoTopInset,
                  ),
                  child: const SediHologramOrb(
                    state: Gate3InteractionState.idle,
                    diameter: MessageBubble.sediLogoDiameter,
                    showRings: false,
                    animate: false,
                    keyedLogo: false,
                  ),
                ),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      panel,
                      if (outside.isNotEmpty) _LinkLines(links: outside, direction: textDirection),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // User only: visual container/bubble with collapse + retry.
    // The group stays physical-right for all locales. Edit sits fully
    // outside, below the bubble, aligned to the physical bottom-left.
    // Compact visual icon; 44dp hit target. Edit width is
    // not subtracted from the approved bubble max width.
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final available =
                constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0;
            final bubbleMax = available.clamp(0.0, 300.0).toDouble();

            final bubble = ConstrainedBox(
              constraints: BoxConstraints(maxWidth: bubbleMax),
              child: IntrinsicWidth(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MessageBubble._panelPaddingH,
                    vertical: MessageBubble._panelPaddingV,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: MessageBubble.userBubbleGradient,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                      bottomLeft: Radius.circular(22),
                      bottomRight: Radius.circular(6),
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.55),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: SediPalette.pistachio700.withOpacity(0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: body,
                ),
              ),
            );

            if (editAction == null) return bubble;

            return Directionality(
              textDirection: TextDirection.ltr,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  bubble,
                  const SizedBox(height: 4),
                  editAction!,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

Widget _sediText(String text, TextDirection direction) => Text(
      text,
      textDirection: direction,
      textAlign: TextAlign.justify,
      style: const TextStyle(
        color: SediPalette.charcoal950,
        fontSize: MessageBubble._fontSize,
        height: MessageBubble._lineHeight,
        fontWeight: FontWeight.w600,
      ),
    );

/// R-120 am.2: the reply text around the doctor list. The backend's text lists the doctors as «• …» lines (older apps show them); here
/// the list is drawn from the links, so those lines are left out: [head] = everything before the first doctor line, [tail] = after.
class DoctorListSplit {
  final String head;
  final String tail;

  const DoctorListSplit(this.head, this.tail);

  /// Only the «•» lines of the doctors drawn from the links ([names]) - and their indented second lines - are left out; any other line
  /// (another doctor without a page, bulleted advice) stays where it was (Codex P2, PR 34).
  static DoctorListSplit of(String message, List<String> names) {
    final wanted = [for (final n in names) n.trim()].where((n) => n.isNotEmpty).toList();
    final lines = message.split('\n');
    final head = <String>[];
    final tail = <String>[];
    var seenList = false;
    var inItem = false;
    for (final line in lines) {
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('•') && wanted.any((n) => trimmed.substring(1).trimLeft().startsWith(n))) {
        seenList = true;
        inItem = true;
        continue;
      }
      if (inItem && line.startsWith(' ') && line.trim().isNotEmpty) continue; // the indented second line of a drawn doctor
      inItem = false;
      (seenList ? tail : head).add(line);
    }
    return DoctorListSplit(head.join('\n').trim(), tail.join('\n').trim());
  }
}

/// R-120 am.2 (Javad 2026-11-26): the doctors INSIDE Sedi's bubble - name and specialty, his place, an optional note, and RIGHT UNDER them the
/// blue link to his page on the reference site. Each link is a 44 dp touch target and a screen-reader link.
class _DoctorList extends StatelessWidget {
  final List<ChatLink> doctors;
  final TextDirection direction;

  const _DoctorList({required this.doctors, required this.direction});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: direction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final d in doctors)
            Padding(
              key: ValueKey('chat-doctor-${d.url}'),
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(d.title,
                      style: const TextStyle(color: SediPalette.charcoal950, fontSize: 15, height: 1.6, fontWeight: FontWeight.w700)),
                  if (d.location.isNotEmpty)
                    Text(d.location,
                        style: const TextStyle(color: SediPalette.charcoal950, fontSize: 13.5, height: 1.6, fontWeight: FontWeight.w500)),
                  if (d.note.isNotEmpty)
                    Text(d.note,
                        style: const TextStyle(color: SediPalette.pistachio900, fontSize: 13.5, height: 1.6, fontWeight: FontWeight.w600)),
                  _LinkLine(link: d, text: d.linkText.isNotEmpty ? d.linkText : d.label),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> _openLink(BuildContext context, ChatLink link) async {
  final uri = link.uri;
  var opened = false;
  if (uri != null) {
    try {
      opened = await MessageBubble.linkOpener(uri);
    } catch (_) {
      opened = false;
    }
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(link.url, textDirection: TextDirection.ltr)));
  }
}

class _LinkLine extends StatelessWidget {
  final ChatLink link;
  final String text;

  const _LinkLine({required this.link, required this.text});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      label: text,
      child: InkWell(
        key: ValueKey('chat-link-${link.url}'),
        onTap: () => _openLink(context, link),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                text,
                style: const TextStyle(
                  color: MessageBubble.linkColor,
                  decoration: TextDecoration.underline,
                  decorationColor: MessageBubble.linkColor,
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// R-107 am.3 (Javad 2026-11-21): the links of a doctor introduction - blue, underlined, OUTSIDE the chat bubble.
/// A tap opens the doctor's page on the original site (Paziresh24, Doctor-Doctor, ...) in the browser; if the phone cannot open it,
/// the address is shown so it can still be used. Each line is a 44 dp touch target and a screen-reader link.
class _LinkLines extends StatelessWidget {
  final List<ChatLink> links;
  final TextDirection direction;

  const _LinkLines({required this.links, required this.direction});

  Future<void> _open(BuildContext context, ChatLink link) async {
    final uri = link.uri;
    var opened = false;
    if (uri != null) {
      try {
        opened = await MessageBubble.linkOpener(uri);
      } catch (_) {
        opened = false;
      }
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(link.url, textDirection: TextDirection.ltr)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6, end: 6, top: 2),
      child: Directionality(
        textDirection: direction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final link in links)
              Semantics(
                link: true,
                label: link.label,
                child: InkWell(
                  key: ValueKey('chat-link-${link.url}'),
                  onTap: () => _open(context, link),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          link.label,
                          style: const TextStyle(
                            color: MessageBubble.linkColor,
                            decoration: TextDecoration.underline,
                            decorationColor: MessageBubble.linkColor,
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(0),
            const SizedBox(width: 4),
            _dot(1),
            const SizedBox(width: 4),
            _dot(2),
          ],
        );
      },
    );
  }

  Widget _dot(int index) {
    final phase = (_controller.value + (index * 0.2)) % 1.0;
    final pulse = 1 - ((phase - 0.5).abs() * 2);
    final opacity = 0.35 + (0.65 * pulse.clamp(0.0, 1.0).toDouble());
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: SediPalette.pistachio900,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// One glass answer inside Sedi's message box (touch target >= 44 dp).
class _QuickReplyChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickReplyChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.center,
          decoration: SediGlass.pill().copyWith(borderRadius: BorderRadius.circular(22)),
          child: Text(
            label,
            style: const TextStyle(
              color: SediGlass.inkDeep,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}
