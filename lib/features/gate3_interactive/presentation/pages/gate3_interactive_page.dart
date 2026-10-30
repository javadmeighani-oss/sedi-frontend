import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/health_subject/sedi_health_subject_controller.dart';
import '../../../../core/locale/calendar_date_math.dart';
import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/notifications/pending_dislike_reasons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/sedi_palette.dart';
import '../../../../data/models/chat_message.dart';
import '../../../../services/notifications/inbox_refresh_bus.dart';
import '../../../../services/notifications/notifications_service.dart';
import '../../../chat/presentation/widgets/message_bubble.dart';
import '../../../chat/state/chat_controller.dart';
import '../../../devices/presentation/pages/devices_page.dart';
import '../../../lifestyle/presentation/pages/lifestyle_page.dart';
import '../../../notifications/presentation/notification_inbox_l10n.dart';
import '../../../notifications/presentation/pages/notification_inbox_page.dart';
import '../../../notifications/presentation/widgets/dislike_reason_sheet.dart';

import '../../models/gate3_interaction_state.dart';
import '../gate3_localization.dart';
import '../gate3_assistant_starter_bus.dart';
import '../gate3_user_message_bus.dart';
import '../gate3_composer_draft_bus.dart';
import '../widgets/gate3_attachment_flow.dart';
import '../widgets/gate3_composer.dart';
import '../widgets/gate3_main_icon_row.dart';
import '../widgets/gate3_return_to_latest_button.dart';
import '../widgets/gate3_subject_selector.dart';
import '../widgets/gate3_top_navigation_tray.dart';
import '../widgets/sedi_living_echo.dart';
import '../widgets/sedi_resonance_dock.dart';
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
  bool _initialSubjectLoad = true;

  bool _composerListening = false;
  String? _composerDraftSeed;
  final Gate3AttachmentFlow _attachmentFlow = Gate3AttachmentFlow();
  int _composerDraftToken = 0;

  /// localId of the user message being edited; null = normal compose.
  String? _editingLocalId;

  DateTime? _lastBackPressTime;
  Timer? _backPressTimer;
  StreamSubscription<String>? _draftSub;
  StreamSubscription<String>? _starterSub;
  StreamSubscription<String>? _userMessageSub;
  bool _earlierTodayExpanded = false;

  /// Backend canonical unread SENT-history count; null = not loaded yet.
  int? _unreadNotificationCount;
  StreamSubscription<void>? _inboxRefreshSub;

  bool _topTrayExpanded = false;
  bool _keyboardWasOpen = false;

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
    _userMessageSub = Gate3UserMessageBus.instance.stream.listen((text) {
      if (!mounted) return;
      _controller.sendUserMessage(text);
    });
    _refreshUnreadBadge();
    WidgetsBinding.instance.addPostFrameCallback((_) => _askPendingDislikeReason());
    // A1->A3 speed: the subject list and the chat start-up (history + Sedi's opener) do not depend on each
    // other, so they load together. The first subject load is not a "switch" and must not clear the chat.
    _subjects.loadAccessibleSubjects().whenComplete(() {
      _initialSubjectLoad = false;
      _subjectGenSeen = _subjects.generation;
      _syncChatSubject();
    });
    _controller.initialize(
      initialMessage: widget.initialMessage,
      notificationId: widget.notificationId,
    );
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
    if (_initialSubjectLoad) {
      _syncChatSubject();
      setState(() {});
      return;
    }
    // Invalidate chat transcript when subject switches — no stale leakage.
    _controller.messages.clear();
    _editingLocalId = null;
    _syncChatSubject();
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshUnreadBadge();
      _askPendingDislikeReason();
    }
  }

  bool _askingDislikeReason = false;

  /// P7: a tray "Dislike" carries no reason. The next time the chat is in front, Sedi asks why - once - so her
  /// notifications can correct themselves (timing, wording, frequency). Dismissing the sheet is fine: no nagging.
  Future<void> _askPendingDislikeReason() async {
    if (_askingDislikeReason || !mounted) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    _askingDislikeReason = true;
    try {
      final id = await PendingDislikeReasons.takeNext();
      if (id == null || !mounted) return;
      final picked = await showDislikeReasonSheet(
        context,
        NotificationInboxL10n(SediLocaleController.instance.languageCode),
      );
      if (picked == null) return;
      await _notificationsService.sendDislikeReason(id, picked);
    } catch (_) {
      // Fail-open: never break the chat because of a feedback question.
    } finally {
      _askingDislikeReason = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inboxRefreshSub?.cancel();
    _draftSub?.cancel();
    _starterSub?.cancel();
    _userMessageSub?.cancel();
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

  /// The chat always shows the latest texts (D-094): while [_stickToLatest] is
  /// true every change of the transcript or of the list size (new message,
  /// streamed words, typing indicator, keyboard, edit) keeps it at the end.
  /// Only a drag by the user releases it; scrolling back to the end, the
  /// "latest" button or sending a message re-attaches it.
  bool _stickToLatest = true;

  /// Re-attach to the latest messages and scroll there (button, send, edit).
  void _attachToLatest() {
    _stickToLatest = true;
    _scheduleJumpToLatest();
  }

  void _scrollToBottomOnNewMessage() {
    if (_stickToLatest) _scheduleJumpToLatest();
  }

  void _scheduleJumpToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_stickToLatest) return;
      _jumpToLatest();
    });
  }

  void _jumpToLatest() {
    final pos = gate3SingleReadyScrollPosition(_scrollController);
    if (pos == null) return;
    if (pos.maxScrollExtent - pos.pixels > 0.5) {
      _scrollController.jumpTo(pos.maxScrollExtent);
    }
  }

  void _scrollToBottom() {
    _stickToLatest = true;
    final pos = gate3SingleReadyScrollPosition(_scrollController);
    if (pos == null) return;
    _scrollController.animateTo(
      pos.maxScrollExtent,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  /// Touching the list releases the lock at once, so the user can always scroll
  /// by hand, even while Sedi is still writing (D-097). The lock is taken
  /// again when a scroll ends near the latest messages.
  bool _onChatScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (n is ScrollStartNotification && n.dragDetails != null) {
      _stickToLatest = false;
    } else if (n is ScrollEndNotification) {
      final nearEnd = n.metrics.maxScrollExtent - n.metrics.pixels <= 48;
      if (nearEnd) {
        _stickToLatest = true;
        _scheduleJumpToLatest();
      }
    }
    return false;
  }

  /// Content or viewport size changed (streaming text, typing dots, keyboard).
  bool _onChatMetrics(ScrollMetricsNotification n) {
    if (n.metrics.axis == Axis.vertical &&
        _stickToLatest &&
        n.metrics.extentAfter > 0.5) {
      _scheduleJumpToLatest();
    }
    return false;
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
    _attachToLatest();
    final editingId = _editingLocalId;
    if (editingId != null) {
      // Edit mode: the edited text REPLACES the original message (D-093).
      setState(() => _editingLocalId = null);
      _controller.replaceUserMessage(editingId, text);
      return;
    }
    _controller.sendUserMessage(text);
  }

  /// Start editing a sent user message: its text goes into the composer and
  /// Send replaces that message (and re-asks) instead of adding a new one.
  void _beginEditUserMessage(String localId, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _controller.isBusy) return;
    setState(() {
      _editingLocalId = localId;
      _composerDraftSeed = trimmed;
      _composerDraftToken++;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingLocalId = null;
      _composerDraftSeed = '';
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

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final presentationLang = SediLocaleController.instance.languageCode;
    final isRtl = l10n.isRtl;
    // When pushed (e.g. Lifestyle → Chat), allow one-route pop back.
    // Root A3 (no previous route) keeps the existing double-back exit policy.
    final routeCanPop = ModalRoute.of(context)?.canPop ?? false;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    // The tray panel eats half the room the keyboard leaves: when the keyboard opens the panel folds away.
    if (keyboardOpen && !_keyboardWasOpen && _topTrayExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _topTrayExpanded) setState(() => _topTrayExpanded = false);
      });
    }
    _keyboardWasOpen = keyboardOpen;

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
                      // Living Echo (D-127): a full-strength sphere in the empty chat; once the conversation runs
                      // (or the keyboard is open) it moves up into a compact header, so no text is read over it.
                      final compact =
                          keyboardOpen || _controller.messages.length >= 2;
                      final heroSize =
                          math.min(300.0, box.maxHeight * 0.34).toDouble();
                      const chatTopPad = 8.0;
                      // The text area never needs more than what the header, the resonance and the buttons leave
                      // (keyboard open, long text): it scrolls inside the field and the buttons stay in view.
                      // With the keyboard open the resonance steps aside (it is decoration; the room is for typing).
                      final fit = Gate3ComposerFit.plan(
                        available: box.maxHeight,
                        trayExtra:
                            _topTrayExpanded ? Gate3TopNavigationTray.expandedExtraHeight : 0.0,
                        echoHeight: SediLivingEcho.heightFor(compact: compact, heroSize: heroSize),
                        dockHeight: keyboardOpen ? 0.0 : SediResonanceDock.height + 10,
                        bannerHeight: _editingLocalId != null ? 48.0 : 0.0,
                      );
                      final maxFieldHeight = fit.maxField;
                      // A very small screen: the header gives way before anything is cut off.
                      final hideEcho = fit.hideEcho;
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: Column(
                              children: [
                                // The expanded top tray (glass panel + its pill, 88dp more than the collapsed pill) moves the sphere down with it.
                                AnimatedContainer(
                                  duration: Gate3TopNavigationTray.toggleDuration,
                                  curve: Gate3TopNavigationTray.toggleCurve,
                                  height: _topTrayExpanded
                                      ? Gate3TopNavigationTray.expandedExtraHeight
                                      : 0,
                                ),
                                if (!hideEcho)
                                  SediLivingEcho(
                                    state: _orbState(),
                                    compact: compact,
                                    heroSize: heroSize,
                                  ),
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
                                          child: NotificationListener<
                                              ScrollNotification>(
                                            onNotification: _onChatScroll,
                                            child: NotificationListener<
                                                ScrollMetricsNotification>(
                                              onNotification: _onChatMetrics,
                                              child: _buildMessages(
                                                  l10n, chatTopPad),
                                            ),
                                          ),
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
                                if (_editingLocalId != null)
                                  _EditBanner(
                                    label: l10n.editingMessage,
                                    cancelLabel: l10n.cancelEdit,
                                    onCancel: _cancelEdit,
                                  ),
                                // Resonance docked just above the composer, about half the screen width (D-102).
                                if (!keyboardOpen) SediResonanceDock(state: _orbState()),
                                Gate3Composer(
                                  key: ValueKey(
                                      'gate3-composer-$_composerDraftToken'),
                                  placeholder: l10n.composerPlaceholder,
                                  maxFieldHeight: maxFieldHeight,
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
    final hideEarlier = _controller.earlierTodayCollapsed && !_earlierTodayExpanded;
    if (_controller.earlierTodayCollapsed && _controller.restoredTodayCount > 0) {
      // P9: today's earlier chats sit behind one card; Sedi's recap opener follows it.
      entries.add(_earlierTodayEntry);
    }
    for (var i = 0; i < _controller.messages.length; i++) {
      if (hideEarlier && i < _controller.restoredTodayCount) continue;
      // Opened the earlier chats = the user wants to continue that very topic: Sedi's recap steps aside.
      if (_controller.earlierTodayCollapsed &&
          _earlierTodayExpanded &&
          i == _controller.restoredTodayCount) {
        continue;
      }
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
        if (entry == _earlierTodayEntry) {
          return _EarlierTodayCard(
            label: l10n.earlierToday(_controller.restoredTodayCount),
            hideLabel: l10n.earlierTodayHide,
            expanded: _earlierTodayExpanded,
            onTap: () => setState(() => _earlierTodayExpanded = !_earlierTodayExpanded),
          );
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
              ? () => _beginEditUserMessage(msg.localId, msg.text)
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

/// "Editing your message" strip above the composer, with a cancel button.
class _EditBanner extends StatelessWidget {
  final String label;
  final String cancelLabel;
  final VoidCallback onCancel;

  const _EditBanner({
    required this.label,
    required this.cancelLabel,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Container(
        padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
        decoration: BoxDecoration(
          color: SediPalette.sageFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SediPalette.sageLine),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.edit_outlined,
              size: 16,
              color: SediPalette.pistachio900,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: SediPalette.charcoal950,
                ),
              ),
            ),
            IconButton(
              tooltip: cancelLabel,
              onPressed: onCancel,
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.close_rounded,
                size: 18,
                color: SediPalette.pistachio900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small rose-tinted day separator in the transparent chat.
/// Marker entry for the P9 «earlier today» card in the message list.
const String _earlierTodayEntry = 'earlier_today';

/// One tappable card standing in for today's earlier chats (expand to read them and continue from there).
class _EarlierTodayCard extends StatelessWidget {
  final String label;
  final String hideLabel;
  final bool expanded;
  final VoidCallback onTap;

  const _EarlierTodayCard({
    required this.label,
    required this.hideLabel,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Material(
        color: SediPalette.sageFill,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SediPalette.sageLine),
            ),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, size: 20, color: SediPalette.pistachio900),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    expanded ? '$label · $hideLabel' : label,
                    style: const TextStyle(
                      color: SediPalette.charcoal950,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: SediPalette.pistachio900,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
