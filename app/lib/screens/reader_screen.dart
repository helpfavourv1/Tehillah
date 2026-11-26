import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_icon.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/utils/text_direction.dart';
import 'package:tehillah/widgets/app_chip.dart';
import 'package:tehillah/widgets/empty_state.dart';
import 'package:tehillah/widgets/icon_chip.dart';
import 'package:tehillah/widgets/nav_bar.dart';
import 'package:tehillah/widgets/pressable.dart';
import 'package:tehillah/widgets/primary_button.dart';
import 'package:tehillah/widgets/screen_frame.dart';

/// What the reader is showing.
enum ReaderView { loading, missingPack, failed, ready }

/// The four highlight colours, by meaning of the token, not the hex.
enum MarkTone { sun, leaf, sky, rose }

/// What the player has done to one verse.
final class VerseMark {
  const VerseMark({this.highlight, this.bookmarked = false});

  final MarkTone? highlight;
  final bool bookmarked;
}

final class ReaderLabels {
  const ReaderLabels({
    required this.back,
    required this.chooseChapter,
    required this.search,
    required this.theme,
    required this.language,
    required this.settings,
    required this.previous,
    required this.next,
    required this.loading,
    required this.missingTitle,
    required this.missingSubtitle,
    required this.download,
    required this.failedTitle,
    required this.failedSubtitle,
    required this.retry,
    required this.verseNumber,
    required this.bookmarked,
    required this.verseLabel,
  });

  final String back;

  /// Announced on the title chip that opens the book and chapter picker.
  final String chooseChapter;
  final String search;
  final String theme;
  final String language;
  final String settings;
  final String previous;
  final String next;
  final String loading;
  final String missingTitle;
  final String missingSubtitle;
  final String download;
  final String failedTitle;
  final String failedSubtitle;
  final String retry;

  /// The verse number in the app language's digits.
  final String Function(int verse) verseNumber;

  /// Said after a verse that has a bookmark.
  final String bookmarked;

  /// What a screen reader says for a verse: "Verse 3. In the beginning...".
  final String Function(int verse, String text) verseLabel;
}

/// The Bible reader. Navigation is fixed at the top (back, the chapter title
/// that opens the picker, and four action chips) and at the bottom (previous
/// and next chapter); only the verses scroll. The text direction follows the
/// Bible's own language, not the app's. Highlights are a fill behind the
/// verse and a bookmark is an icon, so neither relies on colour alone.
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    required this.labels,
    required this.view,
    required this.title,
    required this.language,
    required this.verses,
    required this.textScale,
    required this.onBack,
    required this.onPickChapter,
    required this.onSearch,
    required this.onTheme,
    required this.onLanguage,
    required this.onSettings,
    required this.onVerseTap,
    super.key,
    this.marks = const <int, VerseMark>{},
    this.focusVerse,
    this.hasPrevious = false,
    this.hasNext = false,
    this.onPrevious,
    this.onNext,
    this.onDownload,
    this.onRetry,
    this.bottom,
  });

  final ReaderLabels labels;
  final ReaderView view;

  /// "Genesis 3" in the app language.
  final String title;

  /// The Bible's language code; sets the direction of the verses.
  final String language;

  /// Verse 1 is at index 0.
  final List<String> verses;

  /// Marks by verse number (1-based).
  final Map<int, VerseMark> marks;
  final int? focusVerse;
  final double textScale;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onBack;
  final VoidCallback onPickChapter;
  final VoidCallback onSearch;
  final VoidCallback onTheme;
  final VoidCallback onLanguage;
  final VoidCallback onSettings;
  final void Function(int verse) onVerseTap;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onDownload;
  final VoidCallback? onRetry;
  final Widget? bottom;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final Map<int, GlobalKey> _keys = <int, GlobalKey>{};
  int? _scrolledTo;

  GlobalKey _keyFor(int verse) => _keys.putIfAbsent(verse, GlobalKey.new);

  void _scrollToFocus() {
    final int? focus = widget.focusVerse;
    if (focus == null || widget.view != ReaderView.ready || _scrolledTo == focus) {
      return;
    }
    _scrolledTo = focus;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      final BuildContext? target = _keys[focus]?.currentContext;
      if (target != null && target.mounted) {
        Scrollable.ensureVisible(target, alignment: 0.15);
      }
    });
  }

  @override
  void didUpdateWidget(ReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title) {
      _keys.clear();
      _scrolledTo = null;
    }
  }

  Color _fill(AppPalette p, MarkTone tone) => switch (tone) {
        MarkTone.sun => p.highlightSun,
        MarkTone.leaf => p.highlightLeaf,
        MarkTone.sky => p.highlightSky,
        MarkTone.rose => p.highlightRose,
      };

  @override
  Widget build(BuildContext context) {
    final ReaderLabels l = widget.labels;
    _scrollToFocus();
    return ScreenFrame(
      navBar: NavBar(
        leading: IconChip(icon: AppIcons.back, semanticLabel: l.back, onTap: widget.onBack),
        actions: <Widget>[
          IconChip(icon: AppIcons.search, semanticLabel: l.search, onTap: widget.onSearch),
          IconChip(icon: AppIcons.theme, semanticLabel: l.theme, onTap: widget.onTheme),
          IconChip(icon: AppIcons.language, semanticLabel: l.language, onTap: widget.onLanguage),
          IconChip(icon: AppIcons.textSize, semanticLabel: l.settings, onTap: widget.onSettings),
        ],
      ),
      bottom: widget.bottom,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.md, Sp.xs, Sp.md, Sp.sm),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Semantics(
                label: '${widget.title}. ${l.chooseChapter}',
                button: true,
                excludeSemantics: true,
                child: AppChip(
                  label: widget.title,
                  icon: AppIcons.list,
                  onTap: widget.onPickChapter,
                ),
              ),
            ),
          ),
          Expanded(child: _content(context)),
          if (widget.view == ReaderView.ready) _pager(context),
        ],
      ),
    );
  }

  Widget _content(BuildContext context) {
    final ReaderLabels l = widget.labels;
    final AppThemeData theme = AppTheme.of(context);
    switch (widget.view) {
      case ReaderView.loading:
        return Center(
          child: Semantics(
            liveRegion: true,
            child: Text(l.loading, style: theme.text.callout.copyWith(color: theme.palette.textSecondary)),
          ),
        );
      case ReaderView.missingPack:
        return EmptyState(
          icon: AppIcons.download,
          title: l.missingTitle,
          subtitle: l.missingSubtitle,
          action: PrimaryButton(
            label: l.download,
            icon: AppIcons.download,
            expanded: false,
            onPressed: widget.onDownload,
          ),
        );
      case ReaderView.failed:
        return EmptyState(
          icon: AppIcons.warning,
          title: l.failedTitle,
          subtitle: l.failedSubtitle,
          action: PrimaryButton(
            label: l.retry,
            icon: AppIcons.retry,
            expanded: false,
            onPressed: widget.onRetry,
          ),
        );
      case ReaderView.ready:
        return _verses(context, theme);
    }
  }

  Widget _verses(BuildContext context, AppThemeData theme) {
    final AppPalette p = theme.palette;
    final TextDirection direction = directionForLanguage(widget.language);
    final TextStyle body = theme.text.readerBody(widget.textScale).copyWith(color: p.textPrimary);
    final TextStyle number = theme.text.footnote.copyWith(color: p.textTertiary);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Sp.md, Sp.xs, Sp.md, Sp.lg),
      child: Directionality(
        textDirection: direction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (int i = 0; i < widget.verses.length; i++)
              _verse(i + 1, widget.verses[i], body, number, p),
          ],
        ),
      ),
    );
  }

  Widget _verse(int n, String text, TextStyle body, TextStyle number, AppPalette p) {
    final VerseMark? mark = widget.marks[n];
    final MarkTone? tone = mark?.highlight;
    final bool bookmarked = mark?.bookmarked ?? false;
    final String label = widget.labels.verseLabel(n, text) +
        (bookmarked ? '. ${widget.labels.bookmarked}' : '');
    return Padding(
      key: _keyFor(n),
      padding: const EdgeInsets.only(bottom: Sp.xs),
      child: Semantics(
        label: label,
        button: true,
        excludeSemantics: true,
        child: Pressable(
          onTap: () => widget.onVerseTap(n),
          focusRadius: Radii.chip,
          minSize: 0,
          builder: (BuildContext context, bool pressed) => AnimatedOpacity(
            opacity: pressed ? Metrics.pressedOpacity : 1,
            duration: Motion.scaled(context, Motion.press),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tone == null ? const Color(0x00000000) : _fill(p, tone),
                borderRadius: BorderRadius.circular(Radii.chip),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: Sp.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 32,
                      child: Padding(
                        padding: const EdgeInsets.only(top: Sp.xs),
                        child: Text(widget.labels.verseNumber(n), style: number),
                      ),
                    ),
                    Expanded(child: Text(text, style: body)),
                    if (bookmarked) ...<Widget>[
                      const SizedBox(width: Sp.sm),
                      AppIcon(AppIcons.bookmark, size: IconSizes.rowTrailing, color: p.accent),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pager(BuildContext context) {
    final ReaderLabels l = widget.labels;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.md, Sp.sm, Sp.md, Sp.sm),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppChip(
                label: l.previous,
                icon: AppIcons.back,
                onTap: widget.hasPrevious ? widget.onPrevious : null,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: AppChip(
                label: l.next,
                icon: AppIcons.forward,
                onTap: widget.hasNext ? widget.onNext : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
