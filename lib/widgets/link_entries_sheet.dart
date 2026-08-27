import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tapni_app/models/social_link.dart';
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
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(size * 0.18),
          child: Image.asset(
            link.assetPath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.link, size: size * 0.4),
          ),
        ),
      );
    }

    if (logo.isEmpty) return fallback();

    if (logo.startsWith('http://') || logo.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
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
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entries = link.effectiveEntries;
    final bg = isDark ? const Color(0xFF111111) : Colors.white;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Material(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Text(
                    link.platformName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final title = entry.name.trim().isNotEmpty
                        ? entry.name.trim()
                        : entry.value;
                    return ListTile(
                      onTap: () => _openEntry(context, entry),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      leading: _entryImage(entry),
                      title: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: entry.name.trim().isNotEmpty &&
                              entry.name.trim() != entry.value
                          ? Text(
                              entry.value,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            )
                          : null,
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey.shade500,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
