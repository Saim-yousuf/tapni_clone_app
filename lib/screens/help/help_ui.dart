import 'package:flutter/material.dart';
import 'package:tapni_app/utils/help_center_catalog.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

/// Shared Help Center tokens & widgets — Figma `Help Center` (271:1735),
/// scaled with [AuthScale] like the rest of the app.
class HelpUi {
  HelpUi._();

  static const Color scaffold = Colors.white;
  static const Color container = Color(0xFFF5F5F5);
  static const Color containerBorder = Color(0xFFE5E7EB);
  static const Color searchBg = Color(0xFFF5F5F5);
  static const Color circleBtn = Color(0xFFF3F4F6);
  static const Color secondaryText = Color(0xFF6B7280);
  static const Color mutedText = Color(0xFFB3B3B3);
  static const Color divider = Color(0xFFE5E7EB);

  /// Design pts @ 390 width (Figma proportions).
  static const double titleSize = 20;
  static const double heroSize = 24;
  static const double subtitleSize = 12;
  static const double sectionSize = 14;
  static const double rowSize = 13;
  static const double articleBodySize = 12;
  static const double searchHintSize = 16;
  static const double containerRadius = 16;
  static const double searchHeight = 46;
  static const double searchRadius = 25;
  static const String searchIconAsset = 'assets/images/png/search-icon.png';

  static double font(AuthScale m, double pt, {double min = 11}) =>
      m.s(pt).clamp(min, pt * 1.25);

  static EdgeInsets pagePad(AuthScale m, {double top = 14, double bottom = 12}) =>
      EdgeInsets.fromLTRB(m.padH, m.v(top), m.padH, m.v(bottom));

  static EdgeInsets headerPad(AuthScale m) =>
      EdgeInsets.fromLTRB(m.padH, m.v(4), m.padH, 0);
}

/// Alias of [AuthBackButton] (OTP / Verify) for Help Center screens.
class HelpCircleBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const HelpCircleBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AuthBackButton(
      onPressed: onTap,
      backgroundColor: HelpUi.circleBtn,
    );
  }
}

class HelpSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final bool autofocus;
  final VoidCallback? onClear;

  const HelpSearchField({
    super.key,
    required this.controller,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final h = m.s(HelpUi.searchHeight);
    final radius = m.s(HelpUi.searchRadius);
    final icon = m.s(20);
    final hint = HelpUi.font(m, HelpUi.searchHintSize, min: 14);

    return SizedBox(
      height: h,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        onChanged: onChanged,
        style: WaUi.body.copyWith(
          fontSize: hint,
          height: 1.4,
          color: Colors.black,
        ),
        cursorColor: Colors.black,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          filled: true,
          fillColor: HelpUi.searchBg,
          hintText: 'Search Help Center',
          hintStyle: TextStyle(
            fontSize: hint,
            fontWeight: FontWeight.w400,
            color: HelpUi.secondaryText,
            height: 1.4,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: m.s(14), right: m.s(8)),
            child: Image.asset(
              HelpUi.searchIconAsset,
              width: icon,
              height: icon,
              color: HelpUi.secondaryText,
              errorBuilder: (_, __, ___) => Icon(
                Icons.search,
                size: icon,
                color: HelpUi.secondaryText,
              ),
            ),
          ),
          prefixIconConstraints: BoxConstraints(
            minWidth: m.s(46),
            minHeight: h,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, size: m.s(18)),
                  color: HelpUi.secondaryText,
                  onPressed: onClear,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: m.s(4),
            vertical: m.s(12),
          ),
          isDense: true,
        ),
      ),
    );
  }
}

class HelpSectionTitle extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight weight;

  const HelpSectionTitle(
    this.text, {
    super.key,
    this.fontSize = HelpUi.sectionSize,
    this.weight = FontWeight.w500,
  });

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    return Text(
      text,
      style: WaUi.toolsTitleOf(
        size: HelpUi.font(m, fontSize, min: 13),
        weight: weight,
        color: Colors.black,
      ),
    );
  }
}

class HelpTopicListCard extends StatelessWidget {
  final List<HelpTopic> topics;
  final ValueChanged<HelpTopic> onTap;

  const HelpTopicListCard({
    super.key,
    required this.topics,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final radius = m.s(HelpUi.containerRadius);
    final rowPadH = m.s(14);
    final rowPadV = m.s(12);
    final rowFont = HelpUi.font(m, HelpUi.rowSize, min: 12);
    final chevron = m.s(18);
    final dividerInset = m.s(12);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: HelpUi.container,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: HelpUi.containerBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < topics.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: HelpUi.divider,
                indent: dividerInset,
                endIndent: dividerInset,
              ),
            InkWell(
              onTap: () => onTap(topics[i]),
              borderRadius: BorderRadius.vertical(
                top: i == 0 ? Radius.circular(radius) : Radius.zero,
                bottom: i == topics.length - 1
                    ? Radius.circular(radius)
                    : Radius.zero,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: rowPadH,
                  vertical: rowPadV,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        topics[i].title,
                        style: WaUi.body.copyWith(
                          fontSize: rowFont,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          height: 1.4,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: chevron,
                      color: HelpUi.secondaryText,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class HelpArticleAccordion extends StatefulWidget {
  final List<HelpArticle> articles;
  final bool expandFirst;

  const HelpArticleAccordion({
    super.key,
    required this.articles,
    this.expandFirst = false,
  });

  @override
  State<HelpArticleAccordion> createState() => _HelpArticleAccordionState();
}

class _HelpArticleAccordionState extends State<HelpArticleAccordion> {
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    if (widget.expandFirst && widget.articles.isNotEmpty) {
      _expandedId = widget.articles.first.id;
    }
  }

  @override
  void didUpdateWidget(covariant HelpArticleAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.articles != oldWidget.articles) {
      final stillExists =
          widget.articles.any((a) => a.id == _expandedId);
      if (!stillExists) {
        _expandedId = widget.expandFirst && widget.articles.isNotEmpty
            ? widget.articles.first.id
            : null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final articles = widget.articles;
    if (articles.isEmpty) return const SizedBox.shrink();

    final m = AuthScale.of(context);
    final radius = m.s(HelpUi.containerRadius);
    final dividerInset = m.s(12);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: HelpUi.container,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: HelpUi.containerBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < articles.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: HelpUi.divider,
                indent: dividerInset,
                endIndent: dividerInset,
              ),
            _AccordionItem(
              article: articles[i],
              expanded: _expandedId == articles[i].id,
              isFirst: i == 0,
              isLast: i == articles.length - 1,
              radius: radius,
              onTap: () {
                setState(() {
                  _expandedId =
                      _expandedId == articles[i].id ? null : articles[i].id;
                });
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _AccordionItem extends StatelessWidget {
  final HelpArticle article;
  final bool expanded;
  final bool isFirst;
  final bool isLast;
  final double radius;
  final VoidCallback onTap;

  const _AccordionItem({
    required this.article,
    required this.expanded,
    required this.isFirst,
    required this.isLast,
    required this.radius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final titleSize = HelpUi.font(m, HelpUi.rowSize, min: 12);
    final bodySize = HelpUi.font(m, HelpUi.articleBodySize, min: 11);
    final chevron = m.s(18);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? Radius.circular(radius) : Radius.zero,
          bottom: isLast && !expanded ? Radius.circular(radius) : Radius.zero,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(m.s(14), m.s(12), m.s(10), m.s(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      article.title,
                      style: WaUi.body.copyWith(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        height: 1.4,
                      ),
                    ),
                  ),
                  SizedBox(width: m.s(8)),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: chevron,
                    color: HelpUi.secondaryText,
                  ),
                ],
              ),
              if (expanded) ...[
                SizedBox(height: m.v(8)),
                Text(
                  article.body,
                  style: WaUi.body.copyWith(
                    fontSize: bodySize,
                    fontWeight: FontWeight.w500,
                    color: HelpUi.secondaryText,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class HelpEmptySearch extends StatelessWidget {
  const HelpEmptySearch({super.key});

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final art = m.s(120);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: m.padH * 1.2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/png/empty-search.png',
              width: art,
              height: art,
              fit: BoxFit.contain,
            ),
            SizedBox(height: m.v(24)),
            Text(
              'No Results Found',
              textAlign: TextAlign.center,
              style: WaUi.toolsTitleOf(
                size: HelpUi.font(m, HelpUi.titleSize, min: 18),
                weight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: m.v(10)),
            Text(
              'We couldn’t find anything matching your search. Try different keywords or browse the topics below.',
              textAlign: TextAlign.center,
              style: WaUi.body.copyWith(
                fontSize: HelpUi.font(m, 14, min: 13),
                color: HelpUi.secondaryText,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HelpContactUsBar extends StatelessWidget {
  final VoidCallback onPressed;

  const HelpContactUsBar({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: HelpUi.containerBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0x40000000),
            blurRadius: m.s(5),
            offset: Offset(0, m.s(1)),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(m.padH, m.v(16), m.padH, m.v(16)),
          child: PillButton(
            label: 'Contact Us',
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}

/// Decorative search bar on the home layout; opens the real search field.
class HelpSearchBarTapTarget extends StatelessWidget {
  final VoidCallback onTap;

  const HelpSearchBarTapTarget({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final m = AuthScale.of(context);
    final h = m.s(HelpUi.searchHeight);
    final radius = m.s(HelpUi.searchRadius);
    final icon = m.s(20);
    final hint = HelpUi.font(m, HelpUi.searchHintSize, min: 14);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: h,
        padding: EdgeInsets.symmetric(horizontal: m.s(14)),
        decoration: BoxDecoration(
          color: HelpUi.searchBg,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Row(
          children: [
            Image.asset(
              HelpUi.searchIconAsset,
              width: icon,
              height: icon,
              color: HelpUi.secondaryText,
              errorBuilder: (_, __, ___) => Icon(
                Icons.search,
                size: icon,
                color: HelpUi.secondaryText,
              ),
            ),
            SizedBox(width: m.s(10)),
            Expanded(
              child: Text(
                'Search Help Center',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WaUi.body.copyWith(
                  fontSize: hint,
                  fontWeight: FontWeight.w400,
                  color: HelpUi.secondaryText,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
