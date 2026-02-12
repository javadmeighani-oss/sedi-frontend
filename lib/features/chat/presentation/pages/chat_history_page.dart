import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/user_profile_manager.dart';
import '../../../../data/dto/history_response.dart';
import '../../../../data/repositories/chat_repository.dart';

/// ------------------------------------------------------------
/// ChatHistoryPage
///
/// Displays real chat history from GET /memory/history.
/// Group selector: Daily / Weekly / Monthly / Yearly.
/// ------------------------------------------------------------
class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key});

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  static const List<String> _groups = ['daily', 'weekly', 'monthly', 'yearly'];
  static const List<String> _groupLabels = ['Daily', 'Weekly', 'Monthly', 'Yearly'];

  int? _userId;
  String _selectedGroup = 'daily';
  bool _loading = true;
  String? _error;
  HistoryResponse? _data;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetch();
  }

  Future<void> _loadUserIdAndFetch() async {
    final profile = await UserProfileManager.loadProfile();
    if (!mounted) return;
    setState(() {
      _userId = profile.userId;
      _loading = true;
      _error = null;
    });
    if (_userId == null) {
      setState(() {
        _loading = false;
        _error = 'Please sign in to see history';
      });
      return;
    }
    await _fetch();
  }

  Future<void> _fetch() async {
    if (_userId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await fetchHistory(
        userId: _userId!,
        group: _selectedGroup,
        limit: 50,
        offset: 0,
      );
      if (!mounted) return;
      setState(() {
        _data = res;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
        _data = null;
      });
    }
  }

  void _onGroupSelected(String group) {
    if (group == _selectedGroup) return;
    setState(() => _selectedGroup = group);
    _fetch();
  }

  /// Parse created_at (ISO) to HH:MM in local time. Safe: empty/fail -> "--:--".
  String _timeFromCreatedAt(String createdAt) {
    if (createdAt.trim().isEmpty) return '--:--';
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '--:--';
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _preview(String text, [int maxLen = 60]) {
    if (text.isEmpty) return '—';
    final t = text.trim();
    if (t.length <= maxLen) return t;
    return '${t.substring(0, maxLen)}…';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            // ================= TOP BAR =================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.history),
                    color: AppTheme.primaryBlack,
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    color: AppTheme.primaryBlack,
                    onPressed: () {},
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // ================= GROUP SELECTOR =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: List.generate(_groups.length, (i) {
                  final g = _groups[i];
                  final label = _groupLabels[i];
                  final selected = _selectedGroup == g;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) => _onGroupSelected(g),
                      selectedColor: AppTheme.pistachioGreen.withOpacity(0.3),
                      checkmarkColor: AppTheme.primaryBlack,
                    ),
                  );
                }),
              ),
            ),

            // ================= CONTENT =================
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlack))
                  : _error != null
                      ? _buildError()
                      : _data == null || _data!.items.isEmpty
                          ? _buildEmpty()
                          : _buildList(),
            ),

            // ================= BACK TO CHAT =================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryBlack,
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.backgroundWhite,
                      size: 24,
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

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _fetch,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Retry'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primaryBlack),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text(
        'No history yet',
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
      ),
    );
  }

  Widget _buildList() {
    final items = _data!.items;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final group = items[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Text(
                group.key,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...group.turns.map((turn) => _TurnTile(
                  turn: turn,
                  timeStr: _timeFromCreatedAt(turn.createdAt),
                  preview: _preview(turn.userMessage),
                  onTap: () => _showTurnDialog(turn),
                )),
          ],
        );
      },
    );
  }

  void _showTurnDialog(HistoryTurnItem turn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_timeFromCreatedAt(turn.createdAt)),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.5),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('You', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 4),
                Text(turn.userMessage, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              const Text('Sedi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 4),
              Text(turn.sediResponse ?? '—', style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _TurnTile extends StatelessWidget {
  final HistoryTurnItem turn;
  final String timeStr;
  final String preview;
  final VoidCallback onTap;

  const _TurnTile({
    required this.turn,
    required this.timeStr,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 44,
              child: Text(
                timeStr,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: Text(
                preview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.metalGrey, size: 20),
          ],
        ),
      ),
    );
  }
}
