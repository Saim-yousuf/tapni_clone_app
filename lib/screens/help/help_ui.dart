import 'package:flutter/material.dart';
import 'package:tapni_app/utils/help_center_catalog.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';

/// Shared Help Center design tokens & widgets (match reference UI).
class HelpUi {
  HelpUi._();

  static const Color scaffold = Colors.white;
  static const Color container = Color(0xFFF5F5F7);
  static const Color searchBg = Color(0xFFF2F2F7);
  static const Color circleBtn = Color(0xFFF2F2F7);
  static const Color secondaryText = Color(0xFF8E8E93);
  static const Color bodyText = Color(0xFF707070);
  static const Color divider = Color(0xFFE8E8E8);
  static const double containerRadius = 16;
  static const double sidePad = 20;
}

class HelpCircleBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const HelpCircleBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HelpUi.circleBtn,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: Colors.black,
          ),
        ),
      ),
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
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        onChanged: onChanged,
        style: WaUi.body.copyWith(
          fontSize: 15,
          height: 1.2,
          color: Colors.black,
        ),
        cursorColor: Colors.black,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          filled: true,
          fillColor: HelpUi.searchBg,
          hintText: 'Search Help Center',
          hintStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: HelpUi.secondaryText,
            height: 1.2,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 14, right: 6),
            child: Icon(
              Icons.search,
              size: 20,
              color: HelpUi.secondaryText,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 42,
            minHeight: 44,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: HelpUi.secondaryText,
                  onPressed: onClear,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 12,
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

  const HelpSectionTitle(
    this.text, {
    super.key,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: WaUi.toolsTitleOf(
        size: fontSize,
        weight: FontWeight.w700,
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
    return Container(
      decoration: BoxDecoration(
        color: HelpUi.container,
        borderRadius: BorderRadius.circular(HelpUi.containerRadius),
      ),
      child: Column(
        children: [
          for (var i = 0; i < topics.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: HelpUi.divider,
                indent: 16,
                endIndent: 16,
              ),
            InkWell(
              onTap: () => onTap(topics[i]),
              borderRadius: BorderRadius.vertical(
                top: i == 0
                    ? const Radius.circular(HelpUi.containerRadius)
                    : Radius.zero,
                bottom: i == topics.length - 1
                    ? const Radius.circular(HelpUi.containerRadius)
                    : Radius.zero,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        topics[i].title,
                        style: WaUi.body.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
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

    return Container(
      decoration: BoxDecoration(
        color: HelpUi.container,
        borderRadius: BorderRadius.circular(HelpUi.containerRadius),
      ),
      child: Column(
        children: [
          for (var i = 0; i < articles.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: HelpUi.divider,
                indent: 16,
                endIndent: 16,
              ),
            _AccordionItem(
              article: articles[i],
              expanded: _expandedId == articles[i].id,
              isFirst: i == 0,
              isLast: i == articles.length - 1,
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
  final VoidCallback onTap;

  const _AccordionItem({
    required this.article,
    required this.expanded,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst
              ? const Radius.circular(HelpUi.containerRadius)
              : Radius.zero,
          bottom: isLast && !expanded
              ? const Radius.circular(HelpUi.containerRadius)
              : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: HelpUi.secondaryText,
                  ),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: 10),
                Text(
                  article.body,
                  style: WaUi.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: HelpUi.bodyText,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/png/empty-search.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text(
              'No Results Found',
              textAlign: TextAlign.center,
              style: WaUi.toolsTitleOf(
                size: 20,
                weight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'We couldn’t find anything matching your search. Try different keywords or browse the topics below.',
              textAlign: TextAlign.center,
              style: WaUi.body.copyWith(
                fontSize: 14,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1, thickness: 1, color: HelpUi.divider),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'Contact Us',
                  style: WaUi.promoButton.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
