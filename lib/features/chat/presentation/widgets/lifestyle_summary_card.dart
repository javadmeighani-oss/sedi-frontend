/// LifestyleSummaryCard — display lifestyle summary from GET /lifestyle/summary.
/// Stage 17.2: Chat-only trigger via command.

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/dto/lifestyle_summary_response.dart';

class LifestyleSummaryCard extends StatefulWidget {
  final LifestyleSummaryResponse? data;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final String lang;

  const LifestyleSummaryCard({
    super.key,
    this.data,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.lang = 'en',
  });

  @override
  State<LifestyleSummaryCard> createState() => _LifestyleSummaryCardState();
}

class _LifestyleSummaryCardState extends State<LifestyleSummaryCard> {
  bool _expanded = false;

  String _t(String en, String fa, String ar) {
    if (widget.lang == 'fa') return fa;
    if (widget.lang == 'ar') return ar;
    return en;
  }

  /// Collect all sources from shown sections (never display ids/labels verbatim).
  List<LifestyleSummarySource> get _allSources {
    final sections = widget.data?.sections ?? [];
    final shown = _expanded ? sections : sections.take(2).toList();
    final list = <LifestyleSummarySource>[];
    for (final s in shown) {
      if (s.sources != null && s.sources!.isNotEmpty) {
        list.addAll(s.sources!);
      }
    }
    return list;
  }

  bool get _hasSources => _allSources.isNotEmpty;

  /// Type-based description (safe; no raw memory text).
  String _typeDescription(String type) {
    switch (type) {
      case 'user_profile_knowledge':
        return _t('Your baseline & goals', 'خط پایه و اهداف شما', 'خطك الأساسي وأهدافك');
      case 'user_fact':
        return _t('Facts you shared', 'حقایقی که به اشتراک گذاشتید', 'حقائق شاركتها');
      case 'user_memory_fact':
        return _t('Your preferences/settings', 'ترجیحات و تنظیمات شما', 'تفضيلاتك وإعداداتك');
      case 'daily_summary':
        return _t('Your recent days summary', 'خلاصه روزهای اخیر شما', 'ملخص أيامك الأخيرة');
      case 'memory_turn':
        return _t('Recent conversations', 'مکالمات اخیر', 'المحادثات الأخيرة');
      case 'candidate_fact':
        return _t('Possible new insights (pending)', 'احتمالاً نکات جدید (در انتظار)', 'رؤى جديدة محتملة (قيد الانتظار)');
      default:
        return _t('Your data in Sedi', 'داده‌های شما در صدی', 'بياناتك في صدي');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoading();
    }
    if (widget.error != null) {
      return _buildError();
    }
    if (widget.data == null || (widget.data!.sections.isEmpty && widget.data!.factsCount == 0)) {
      return _buildEmpty();
    }
    return _buildContent();
  }

  Widget _buildLoading() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borderInactive.withOpacity(0.5)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.pistachioGreen),
          ),
          const SizedBox(width: 12),
          Text(
            _t('Loading summary…', 'در حال بارگذاری خلاصه…', 'جاري تحميل الملخص…'),
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borderInactive.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('Could not load summary', 'خلاصه بارگذاری نشد', 'لم يتم تحميل الملخص'),
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
          ),
          if (widget.error != null && widget.error!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.error!,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (widget.onRetry != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: widget.onRetry,
                child: Text(_t('Retry', 'تلاش مجدد', 'إعادة المحاولة')),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borderInactive.withOpacity(0.5)),
      ),
      child: Text(
        _t('No lifestyle data yet. Chat with Sedi to build your summary.', 'هنوز داده‌ای نیست. با صدی چت کنید تا خلاصه ساخته شود.', 'لا توجد بيانات بعد. تواصل مع صدي لبناء ملخصك.'),
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
      ),
    );
  }

  Widget _buildContent() {
    final d = widget.data!;
    final showSections = d.sections.take(_expanded ? d.sections.length : 2).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borderInactive.withOpacity(0.5)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _t('Lifestyle summary', 'خلاصه سبک زندگی', 'ملخص نمط الحياة'),
                    style: const TextStyle(
                      color: AppTheme.primaryBlack,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (_hasSources)
                  TextButton(
                    onPressed: _showWhyThisDialog,
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _t('Why this?', 'چرا؟', 'لماذا؟'),
                      style: TextStyle(color: AppTheme.pistachioGreen, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
          ),
          ...showSections.map((s) => _buildSection(s)),
          if (d.sections.length > 2)
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  _expanded
                      ? _t('Show less', 'کمتر', 'عرض أقل')
                      : _t('Show more', 'بیشتر', 'المزيد'),
                  style: TextStyle(color: AppTheme.pistachioGreen, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              _t(
                'Based on ${d.factsCount} facts and last ${d.memoryDaysCovered} days',
                'بر اساس ${d.factsCount} نکته و ${d.memoryDaysCovered} روز اخیر',
                'استناداً إلى ${d.factsCount} حقائق وآخر ${d.memoryDaysCovered} أيام',
              ),
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showWhyThisDialog() {
    final sources = _allSources;
    if (sources.isEmpty) return;

    // Group by type and count; never show raw ids/labels.
    final byType = <String, int>{};
    String? latestTs;
    for (final s in sources) {
      final t = s.type.isNotEmpty ? s.type : 'unknown';
      byType[t] = (byType[t] ?? 0) + 1;
      if (s.ts != null && s.ts!.isNotEmpty && (latestTs == null || s.ts!.compareTo(latestTs) > 0)) {
        latestTs = s.ts;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('Why this summary?', 'چرا این خلاصه؟', 'لماذا هذا الملخص؟')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...byType.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                        Expanded(
                          child: Text(
                            '${_typeDescription(e.key)} (${e.value})',
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
              if (latestTs != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _t('Latest: ', 'آخرین: ', 'الأحدث: ') + _formatTs(latestTs),
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _t('This summary is based on your data in Sedi.', 'این خلاصه بر اساس داده‌های شما در صدی است.', 'هذا الملخص يستند إلى بياناتك في صدي.'),
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(_t('Got it', 'متوجه شدم', 'فهمت')),
          ),
        ],
      ),
    );
  }

  String _formatTs(String ts) {
    try {
      final dt = DateTime.tryParse(ts);
      if (dt != null) {
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }
    } catch (_) {}
    return ts;
  }

  Widget _buildSection(LifestyleSummarySection s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (s.title.isNotEmpty)
            Text(
              s.title,
              style: const TextStyle(
                color: AppTheme.primaryBlack,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          if (s.body.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                s.body,
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              ),
            ),
          if (s.items != null && s.items!.isNotEmpty)
            ...s.items!.take(5).map((item) => Padding(
                  padding: const EdgeInsets.only(top: 2, left: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      Expanded(child: Text(item, style: TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
                    ],
                  ),
                )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
