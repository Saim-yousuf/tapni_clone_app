import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showLinkEntriesSheet({
  required BuildContext context,
  required SocialLink link,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => LinkEntriesSheet(link: link),
  );
}

class LinkEntriesSheet extends StatelessWidget {
  const LinkEntriesSheet({super.key, required this.link});

  final SocialLink link;

  Widget _entryImage(LinkEntry entry, {double size = 48}) {
    final logo = (entry.logo?.trim().isNotEmpty == true)
        ? entry.logo!.trim()
        : (link.logoUrl?.trim() ?? '');

    Widget fallback() {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFF2F2F7),
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: EdgeInsets.all(size * 0.2),
          child: Image.asset(
            link.assetPath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.person, size: size * 0.4, color: Colors.black54),
          ),
        ),
      );
    }

    Widget clipped(Widget child) {
      return ClipOval(
        child: SizedBox(width: size, height: size, child: child),
      );
    }

    if (logo.isEmpty) return fallback();

    if (logo.startsWith('http://') || logo.startsWith('https://')) {
      return clipped(
        Image.network(
          logo,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback(),
        ),
      );
    }

    try {
      final raw = logo.contains(',') ? logo.split(',').last : logo;
      return clipped(
        Image.memory(
          base64Decode(raw),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback(),
        ),
      );
    } catch (_) {
      return fallback();
    }
  }

  Future<void> _openEntry(BuildContext context, LinkEntry entry) async {
    final url = link.urlForValue(entry.value);
    if (url.isEmpty) return;
    Navigator.pop(context);
    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  }

  void _copyValue(BuildContext context, String value) {
    if (value.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.copied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = link.publicEntries.isNotEmpty
        ? link.publicEntries
        : link.effectiveEntries;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(BarqodyChrome.sheetRadius),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.72,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const SheetDragHandle(),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      CircleBackButton(
                        onTap: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          link.platformName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: WaUi.toolsTitleOf(
                            size: 18,
                            weight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 28),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 20,
                    endIndent: 12,
                    color: Color(0xFFE8E8E8),
                  ),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final title = entry.name.trim().isNotEmpty
                        ? entry.name.trim()
                        : entry.value;
                    final subtitle = entry.value.trim();
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (index == 0)
                          const Divider(
                            height: 1,
                            thickness: 1,
                            indent: 20,
                            endIndent: 12,
                            color: Color(0xFFE8E8E8),
                          ),
                        InkWell(
                          onTap: () => _openEntry(context, entry),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 14, 8, 14),
                            child: Row(
                              children: [
                                _entryImage(entry, size: 52),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: WaUi.body.copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                          height: 1.2,
                                        ),
                                      ),
                                      if (subtitle.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                subtitle,
                                                style: WaUi.body.copyWith(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                  color: const Color(
                                                    0xFF6B7280,
                                                  ),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () => _copyValue(
                                                context,
                                                subtitle,
                                              ),
                                              child: Image.asset(
                                                'assets/images/png/copy-icon.png',
                                                width: 15,
                                                height: 15,
                                                color: const Color(0xFF6B7280),
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(
                                                  Icons.copy_rounded,
                                                  size: 15,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.black,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
