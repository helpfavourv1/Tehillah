import 'package:flutter/widgets.dart';
import 'package:tehillah/theme/app_theme.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/utils/text_direction.dart';
import 'package:tehillah/widgets/app_card.dart';
import 'package:tehillah/widgets/empty_state.dart';
import 'package:tehillah/widgets/nav_bar.dart';
import 'package:tehillah/widgets/pressable.dart';
import 'package:tehillah/widgets/screen_frame.dart';
import 'package:tehillah/widgets/search_field.dart';

/// One match: the reference in the app language and the verse text.
final class SearchResult {
  const SearchResult({required this.id, required this.reference, required this.text});

  final String id;
  final String reference;
  final String text;
}

final class ReaderSearchLabels {
  const ReaderSearchLabels({
    required this.title,
    required this.back,
    required this.hint,
    required this.clear,
    required this.idleTitle,
    required this.idleSubtitle,
    required this.noResultsTitle,
    required this.noResultsSubtitle,
    required this.resultCount,
    required this.searching,
  });

  final String title;
  final String back;
  final String hint;
  final String clear;
  final String idleTitle;
  final String idleSubtitle;
  final String noResultsTitle;
  final String noResultsSubtitle;

  /// "12 verses".
  final String Function(int count) resultCount;
  final String searching;
}

/// Search inside the open Bible. The field is fixed; only the results scroll
/// and they are built as they come into view. Results are shown in the Bible's
/// own text direction.
class ReaderSearchScreen extends StatelessWidget {
  const ReaderSearchScreen({
    required this.labels,
    required this.controller,
    required this.query,
    required this.results,
    required this.language,
    required this.onQueryChanged,
    required this.onOpen,
    required this.onBack,
    super.key,
    this.busy = false,
    this.bottom,
  });

  final ReaderSearchLabels labels;
  final TextEditingController controller;

  /// The query the [results] belong to.
  final String query;
  final List<SearchResult> results;

  /// The Bible's language code.
  final String language;
  final ValueChanged<String> onQueryChanged;
  final void Function(SearchResult result) onOpen;
  final VoidCallback onBack;
  final bool busy;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final TextDirection direction = directionForLanguage(language);
    return ScreenFrame(
      navBar: NavBar.back(onBack: onBack, backLabel: labels.back, title: labels.title),
      bottom: bottom,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.md, Sp.sm, Sp.md, Sp.sm),
            child: AppSearchField(
              controller: controller,
              hint: labels.hint,
              clearLabel: labels.clear,
              onChanged: onQueryChanged,
              textDirection: direction,
            ),
          ),
          if (query.trim().isNotEmpty && !busy)
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.md, 0, Sp.md, Sp.sm),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  labels.resultCount(results.length),
                  style: theme.text.footnote.copyWith(color: theme.palette.textTertiary),
                ),
              ),
            ),
          Expanded(child: _body(context, theme, direction)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, AppThemeData theme, TextDirection direction) {
    if (busy) {
      return Center(
        child: Semantics(
          liveRegion: true,
          child: Text(
            labels.searching,
            style: theme.text.callout.copyWith(color: theme.palette.textSecondary),
          ),
        ),
      );
    }
    if (query.trim().isEmpty) {
      return EmptyState(
        icon: AppIcons.search,
        title: labels.idleTitle,
        subtitle: labels.idleSubtitle,
      );
    }
    if (results.isEmpty) {
      return EmptyState(
        icon: AppIcons.search,
        title: labels.noResultsTitle,
        subtitle: labels.noResultsSubtitle,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(Sp.md, Sp.xs, Sp.md, Sp.lg),
      itemCount: results.length,
      separatorBuilder: (BuildContext c, int i) => const SizedBox(height: Sp.sm),
      itemBuilder: (BuildContext c, int i) {
        final SearchResult r = results[i];
        return Semantics(
          label: '${r.reference}. ${r.text}',
          button: true,
          excludeSemantics: true,
          child: Pressable.opacity(
            onTap: () => onOpen(r),
            child: CardSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    r.reference,
                    style: theme.text.callout.copyWith(color: theme.palette.accent),
                  ),
                  const SizedBox(height: Sp.xs),
                  Directionality(
                    textDirection: direction,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        r.text,
                        style: theme.text.readerBody(1).copyWith(color: theme.palette.textPrimary),
                      ),
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
