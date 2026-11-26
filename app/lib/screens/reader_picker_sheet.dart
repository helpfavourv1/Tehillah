import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_card.dart';
import 'package:tehillah/widgets/app_chip.dart';
import 'package:tehillah/widgets/app_row.dart';
import 'package:tehillah/widgets/pressable.dart';
import 'package:tehillah/widgets/section_header.dart';

/// One book in the picker.
final class PickerBook {
  const PickerBook({
    required this.id,
    required this.name,
    required this.chapters,
    required this.isNewTestament,
  });

  final String id;
  final String name;
  final int chapters;
  final bool isNewTestament;
}

final class ReaderPickerLabels {
  const ReaderPickerLabels({
    required this.oldTestament,
    required this.newTestament,
    required this.books,
    required this.chapterLabel,
    required this.number,
  });

  final String oldTestament;
  final String newTestament;

  /// The chip that goes back from the chapter grid to the book list.
  final String books;

  /// "Genesis chapter 3", for screen readers.
  final String Function(String book, int chapter) chapterLabel;

  /// A number in the app language's digits.
  final String Function(int n) number;
}

/// The content of the book and chapter picker (shown with
/// `showAppBottomSheet`): the books under Old and New Testament, then a grid
/// of chapter numbers for the chosen book. The open book is marked with a
/// check as well as its place in the list.
class ReaderPickerSheet extends StatefulWidget {
  const ReaderPickerSheet({
    required this.labels,
    required this.books,
    required this.onPick,
    super.key,
    this.currentBook,
    this.currentChapter,
  });

  final ReaderPickerLabels labels;
  final List<PickerBook> books;
  final String? currentBook;
  final int? currentChapter;

  /// Called with the book id and chapter (1-based) that was chosen.
  final void Function(String book, int chapter) onPick;

  @override
  State<ReaderPickerSheet> createState() => _ReaderPickerSheetState();
}

class _ReaderPickerSheetState extends State<ReaderPickerSheet> {
  PickerBook? _book;

  @override
  Widget build(BuildContext context) {
    final PickerBook? open = _book;
    return open == null ? _bookList() : _chapterGrid(open);
  }

  Widget _group(String title, List<PickerBook> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(title, padding: EdgeInsets.zero),
        const SizedBox(height: Sp.sm),
        CardSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              for (final PickerBook b in list)
                AppRow(
                  label: b.name,
                  leading: b.id == widget.currentBook ? AppIcons.check : null,
                  onTap: () => setState(() => _book = b),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bookList() {
    final List<PickerBook> ot = <PickerBook>[
      for (final PickerBook b in widget.books)
        if (!b.isNewTestament) b,
    ];
    final List<PickerBook> nt = <PickerBook>[
      for (final PickerBook b in widget.books)
        if (b.isNewTestament) b,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (ot.isNotEmpty) _group(widget.labels.oldTestament, ot),
        if (ot.isNotEmpty && nt.isNotEmpty) const SizedBox(height: Sp.lg),
        if (nt.isNotEmpty) _group(widget.labels.newTestament, nt),
      ],
    );
  }

  Widget _chapterGrid(PickerBook book) {
    final AppThemeData theme = AppTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppChip(
            label: widget.labels.books,
            icon: AppIcons.back,
            onTap: () => setState(() => _book = null),
          ),
        ),
        const SizedBox(height: Sp.sm),
        Text(book.name, style: theme.text.title2),
        const SizedBox(height: Sp.md),
        Wrap(
          spacing: Sp.sm,
          runSpacing: Sp.sm,
          children: <Widget>[
            for (int c = 1; c <= book.chapters; c++)
              _ChapterCell(
                number: widget.labels.number(c),
                semanticLabel: widget.labels.chapterLabel(book.name, c),
                current: book.id == widget.currentBook && c == widget.currentChapter,
                onTap: () => widget.onPick(book.id, c),
              ),
          ],
        ),
      ],
    );
  }
}

class _ChapterCell extends StatelessWidget {
  const _ChapterCell({
    required this.number,
    required this.semanticLabel,
    required this.current,
    required this.onTap,
  });

  final String number;
  final String semanticLabel;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final AppPalette p = theme.palette;
    return Semantics(
      label: semanticLabel,
      selected: current,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        semanticLabel: semanticLabel,
        builder: (BuildContext context, bool pressed) => AnimatedOpacity(
          opacity: pressed ? Metrics.pressedOpacity : 1,
          duration: Motion.scaled(context, Motion.press),
          child: SizedBox.square(
            dimension: Metrics.touchTarget,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: current ? p.accent : p.bgTertiary,
                borderRadius: BorderRadius.circular(Radii.chip),
              ),
              child: Center(
                child: Text(
                  number,
                  style: theme.text.callout.copyWith(color: current ? p.onAccent : p.textPrimary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
