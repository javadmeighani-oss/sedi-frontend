import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/health_subject/sedi_health_subject_controller.dart';
import '../../../../core/locale/calendar_date_math.dart';
import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/sedi_palette.dart';
import '../../../../data/models/chat_message.dart';
import '../../../../services/notifications/inbox_refresh_bus.dart';
import '../../../../services/notifications/notifications_service.dart';
import '../../../chat/presentation/widgets/message_bubble.dart';
import '../../../chat/state/chat_controller.dart';
import '../../../devices/presentation/pages/devices_page.dart';
import '../../../lifestyle/presentation/pages/lifestyle_page.dart';
import '../../../notifications/presentation/pages/notification_inbox_page.dart';

import '../../models/gate3_interaction_state.dart';
import '../gate3_localization.dart';
import '../gate3_assistant_starter_bus.dart';
import '../gate3_composer_draft_bus.dart';
import '../widgets/gate3_attachment_flow.dart';
import '../widgets/gate3_composer.dart';
import '../widgets/gate3_main_icon_row.dart';
import '../widgets/gate3_return_to_latest_button.dart';
import '../widgets/gate3_subject_selector.dart';
import '../widgets/gate3_top_navigation_tray.dart';
import '../widgets/sedi_brain_orb.dart';
import '../widgets/sedi_orb_presence.dart';
import '../widgets/sedi_scene_backdrop.dart';

class Gate3InteractivePage extends StatefulWidget {
  final String? initialMessage;

  /// Composer-only seed text. Never auto-sends; never inserts into transcript.
  final String? initialDraft;
  final bool fromNotification;
  final int? notificationId;

  const Gate3InteractivePage({
    super.key,
    this.initialMessage,
    this.initialDraft,
    this.fromNotification = false,
    this.notificationId,
  });

  @override
  State<Gate3InteractivePage> createState() => _Gate3InteractivePageState();
}

class _Gate3InteractivePageState extends State<Gate3InteractivePage>
    with WidgetsBindingObserver {
  late final ChatController _controller;
  final ScrollController _scrollController = ScrollController();
  final SediHealthSubjectController _subjects =
      SediHealthSubjectController.instance;
  final NotificationsService _notificationsService = NotificationsService();
  int _subjectGenSeen = -1;

  bool _composerListening = false;
  String? _composerDraftSeed;
  final Gate3AttachmentFlow _attachmentFlow = Gate3AttachmentFlow();
  int _composerDraftToken = 0;

  DateTime? _lastBackPressTime;
  Timer? _backPressTimer;
  StreamSubscription<String>? _draftSub;
  StreamSubscription<String>? _starterSub;

  /// Backend canonical unread SENT-history count; null = not loaded yet.
  int? _unreadNotificationCount;
  StreamSubscription<void>? _inboxRefreshSub;

  bool _topTrayExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = ChatController();
    _controller.addListener(_onControllerChanged);
    _controller.addListener(_scrollToBottomOnNewMessage);
    _subjects.addListener(_onSubjectChanged);
    _inboxRefreshSub = InboxRefreshBus.instance.stream.listen((_) {
      _refreshUnreadBadge();
    });
    final seed = widget.initialDraft?.trim();
    if (seed != null && seed.isNotEmpty) {
      _composerDraftSeed = seed;
    }
    _draftSub = Gate3ComposerDraftBus.instance.stream.listen((draft) {
      if (!mounted) return;
      setState(() {
        _composerDraftSeed = draft;
        _composerDraftToken++;
      });
    });
    _starterSub = Gate3AssistantStarterBus.instance.stream.listen((text) {
      if (!mounted) return;
      _controller.insertPresentationAssistantMessage(text);
    });
    _refreshUnreadBadge();
    _subjects.loadAccessibleSubjects().then((_) {
      _syncChatSubject();
      _controller.initialize(
        initialMessage: widget.initialMessage,
        notificationId: widget.notificationId,
      );
    });
  }

  Future<void> _refreshUnreadBadge() async {
    final resp = await _notificationsService.fetchUnreadCount();
    if (!mounted) return;
    if (resp.ok) {
      setState(() => _unreadNotificationCount = resp.data ?? 0);
    } else {
      setState(() => _unreadNotificationCount = _unreadNotificationCount ?? 0);
    }
  }

  Future<void> _openNotificationsInbox() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const NotificationInboxPage(),
      ),
    );
    if (!mounted) return;
    await _refreshUnreadBadge();
  }

  void _syncChatSubject() {
    _controller.activeHealthSubjectId = _subjects.activeSubject?.id;
  }

  void _onSubjectChanged() {
    if (!mounted) return;
    if (_subjectGenSeen == _subjects.generation) {
      setState(() {});
      return;
    }
    _subjectGenSeen = _subjects.generation;
    // Invalidate chat transcript when subject switches — no stale leakage.
    _controller.messages.clear();
    _syncChatSubject();
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshUnreadBadge();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inboxRefreshSub?.cancel();
    _draftSub?.cancel();
    _starterSub?.cancel();
    _backPressTimer?.cancel();
    _controller.removeListener(_onControllerChanged);
    _controller.removeListener(_scrollToBottomOnNewMessage);
    _subjects.removeListener(_onSubjectChanged);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Gate3Localization get _l10n =>
      Gate3Localization(SediLocaleController.instance.languageCode);

  void _scrollToBottomOnNewMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    final pos = gate3SingleReadyScrollPosition(_scrollController);
    if (pos == null) return;
    _scrollController.animateTo(
      pos.maxScrollExtent,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  bool _handleBackPress() {
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      _backPressTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_l10n.pressBackAgainToExit),
          duration: const Duration(seconds: 2),
          backgroundColor: AppTheme.primaryBlack.withOpacity(0.8),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
        ),
      );
      _backPressTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _lastBackPressTime = null);
      });
      return false;
    }
    _backPressTimer?.cancel();
    SystemNavigator.pop();
    return true;
  }

  void _handleSendText(String text) {
    _controller.sendUserMessage(text);
  }

  /// Presentation-only: seed composer with historical user text.
  /// Does not mutate transcript; Send creates a NEW user message.
  void _editUserMessageAsNewDraft(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _composerDraftSeed = trimmed;
      _composerDraftToken++;
    });
  }

  Gate3InteractionState _orbState() {
    if (_controller.isSpeaking) return Gate3InteractionState.speaking;
    if (_controller.isThinking) return Gate3InteractionState.thinking;
    if (_controller.isRecording || _composerListening) {
      return Gate3InteractionState.listening;
    }
    return Gate3InteractionState.idle;
  }

  void _goTo(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  /// Background hologram opacity (D-091/D-092). Its purpose is to never get in
  /// the way of reading: 40 % transparent on an empty chat, 60 % transparent
  /// once messages float over it (worst-case text contrast >= 7:1), fainter
  /// while the keyboard is open. Sedi's state shows in the motion instead.
  double _orbAmbient({required bool keyboardOpen}) {
    if (keyboardOpen) return 0.22;
    return _controller.messages.isEmpty
        ? SediOrbPresence.hologramOpacity
        : SediOrbPresence.hologramOpacityChat;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final presentationLang = SediLocaleController.instance.languageCode;
    final isRtl = l10n.isRtl;
    // When pushed (e.g. Lifestyle → Chat), allow one-route pop back.
    // Root A3 (no previous route) keeps the existing double-back exit policy.
    final routeCanPop = ModalRoute.of(context)?.canPop ?? false;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    final content = PopScope(
      canPop: routeCanPop,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBackPress();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: SediPalette.sagePage,
          resizeToAvoidBottomInset: true,
          body: Stack(
            fit: StackFit.expand,
            children: [
              const SediSceneBackdrop(),
              SafeArea(
                child: Directionality(
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final usableW =
                          box.maxWidth - 2 * SediOrbPresence.horizontalInset;
                      // The hologram sits lower, almost resting on the resonance
                      // line (D-091); the line stays at about the middle.
                      const gap = 4.0;
                      final orbD = SediBrainOrb.diameterFor(usableW);
                      final barsTop = (box.maxHeight * 0.455)
                          .clamp(260.0, 460.0)
                          .toDouble();
                      final presenceTop = math.max(56.0, barsTop - gap - orbD);
                      final presenceBottom =
                          presenceTop + SediOrbPresence.heightFor(usableW, gap);
                      final chatTopPad =
                          keyboardOpen ? 56.0 : presenceBottom + 10;
                      return Stack(
                        children: [
                          // Background layer: hologram + horizontal resonance.
                          Positioned(
                            top: presenceTop,
                            left: 0,
                            right: 0,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SediOrbPresence.horizontalInset,
                              ),
                              child: SediOrbPresence(
                                state: _orbState(),
                                lang: presentationLang,
                                ambient:
                                    _orbAmbient(keyboardOpen: keyboardOpen),
                                gap: gap,
                              ),
                            ),
                          ),
                          // Transparent chat floating over the hologram.
                          Positioned.fill(
                            child: Column(
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: ShaderMask(
                                          blendMode: BlendMode.dstIn,
                                          shaderCallback: (rect) =>
                                              const LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Color(0x00FFFFFF),
                                              Color(0xFFFFFFFF),
                                            ],
                                            stops: [0.0, 0.16],
                                          ).createShader(rect),
                                          child:
                                              _buildMessages(l10n, chatTopPad),
                                        ),
                                      ),
                                      Positioned(
                                        right: 12,
                                        bottom: 12,
                                        child: Gate3ReturnToLatestButton(
                                          scrollController: _scrollController,
                                          onTap: _scrollToBottom,
                                          tooltip: l10n.returnToLatest,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Gate3Composer(
                                  key: ValueKey(
                                      'gate3-composer-$_composerDraftToken'),
                                  placeholder: l10n.composerPlaceholder,
                                  lang: presentationLang,
                                  isRtl: isRtl,
                                  initialText:
                                      _composerDraftSeed ?? widget.initialDraft,
                                  onListeningChanged: (listening) {
                                    if (!mounted) return;
                                    if (_composerListening == listening) {
                                      return;
                                    }
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (!mounted) return;
                                      if (_composerListening == listening) {
                                        return;
                                      }
                                      setState(
                                          () => _composerListening = listening);
                                    });
                                  },
                                  onSendText: _handleSendText,
                                  onStartRecording: () {
                                    _controller
                                        .startVoiceRecording()
                                        .then((ok) {
                                      if (!mounted) return;
                                      if (ok == false) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              l10n.microphonePermissionRequired,
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.only(
                                              bottom: 100,
                                              left: 16,
                                              right: 16,
                                            ),
                                          ),
                                        );
                                      } else {
                                        setState(
                                            () => _composerListening = true);
                                      }
                                    });
                                  },
                                  onStopRecordingAndSend: () {
                                    _controller
                                        .stopVoiceRecording()
                                        .then((path) async {
                                      if (!mounted) return;
                                      if (path != null && kDebugMode) {
                                        debugPrint(
                                            '[Audio] recorded file: $path');
                                      }
                                      setState(
                                          () => _composerListening = false);
                                      if (path == null) return;
                                      // R-021 / M4: the recording becomes TEXT in the composer (never auto-sent).
                                      final text =
                                          await _attachmentFlow.transcribeVoice(
                                              context, presentationLang, path);
                                      if (!mounted || text == null) return;
                                      setState(() {
                                        _composerDraftSeed = text;
                                        _composerDraftToken++;
                                      });
                                    });
                                  },
                                  isRecording: _controller.isRecording,
                                  recordingTime:
                                      _controller.recordingTimeFormatted,
                                ),
                              ],
                            ),
                          ),
                          // Glass destinations tray (Profile | Lifestyle | Gadgets | Notifications).
                          Positioned(
                            top: 0,
                            left: 12,
                            right: 12,
                            child: Gate3TopNavigationTray(
                              expanded: _topTrayExpanded,
                              onToggle: () {
                                setState(
                                    () => _topTrayExpanded = !_topTrayExpanded);
                              },
                              expandLabel: l10n.expandDestinations,
                              collapseLabel: l10n.collapseDestinations,
                              child: Gate3MainIconRow(
                                lang: presentationLang,
                                unreadNotificationCount:
                                    _unreadNotificationCount,
                                onLifestyle: () {
                                  if (!_subjects.isActiveSelf) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            l10n.lifestyleOtherUnavailable),
                                      ),
                                    );
                                    return;
                                  }
                                  _goTo(const LifestylePage());
                                },
                                onGadgets: () => _goTo(const DevicesPage()),
                                onNotifications: _openNotificationsInbox,
                              ),
                            ),
                          ),
                          Offstage(
                            offstage: true,
                            child: Gate3SubjectSelector(l10n: l10n),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return content;
  }

  Widget _buildMessages(Gate3Localization l10n, double topPad) {
    if (_controller.messages.isEmpty &&
        _controller.conversationState == ConversationState.initializing) {
      return const ColoredBox(
        color: Color(0x00000000),
        child: SizedBox.expand(),
      );
    }

    if (_controller.messages.isEmpty) {
      // Non-transcript empty presentation — below the hologram, no artificial gap.
      return ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(12, topPad, 12, 12),
        children: [
          Text(
            l10n.emptyConversationHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: SediPalette.sageMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      );
    }

    // Entries: DateTime = day separator, int >= 0 = message index, -1 = typing.
    final entries = <Object>[];
    DateTime? lastDay;
    for (var i = 0; i < _controller.messages.length; i++) {
      final t = _controller.messages[i].createdAt.toLocal();
      final day = DateTime(t.year, t.month, t.day);
      if (lastDay == null || day != lastDay) {
        entries.add(day);
        lastDay = day;
      }
      entries.add(i);
    }
    if (_controller.isThinking) entries.add(-1);

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(10, topPad, 10, 8),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        if (entry is DateTime) {
          return _DayChip(label: _dayLabel(entry, l10n));
        }
        if (entry == -1) {
          return const MessageBubble(
            message: '...',
            isSedi: true,
            showTyping: true,
          );
        }
        final msg = _controller.messages[entry as int];
        return MessageBubble(
          key: ValueKey(msg.localId),
          message: msg.text,
          isSedi: msg.isSedi,
          isFailed: msg.isUser && msg.status == ChatMessageStatus.failed,
          onRetry: msg.isUser && msg.status == ChatMessageStatus.failed
              ? () => _controller.retryFailedMessage(msg.localId)
              : null,
          onEdit: msg.isUser && msg.text.trim().isNotEmpty
              ? () => _editUserMessageAsNewDraft(msg.text)
              : null,
          editLabel: l10n.editMessage,
          readMoreLabel: l10n.readMore,
          readLessLabel: l10n.readLess,
          retryLabel: l10n.tapToRetry,
        );
      },
    );
  }

  /// Today / Yesterday, otherwise the calendar date in the app language.
  String _dayLabel(DateTime day, Gate3Localization l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return l10n.dayToday;
    if (diff == 1) return l10n.dayYesterday;
    final iso = '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    return CalendarDateMath.formatIsoForLanguage(iso, l10n.lang);
  }
}

/// Small rose-tinted day separator in the transparent chat.
class _DayChip extends StatelessWidget {
  final String label;

  const _DayChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: SediPalette.sageFill,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: SediPalette.pistachio900,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
