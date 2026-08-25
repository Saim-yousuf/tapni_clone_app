import 'package:flutter/material.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/explore_business.dart';
import 'package:tapni_app/models/profile.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/screens/explore_item_detail_screen.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/explore_detail_shimmers.dart';

class ExploreItemDetailLoaderScreen extends StatefulWidget {
  final ExploreItem item;

  const ExploreItemDetailLoaderScreen({super.key, required this.item});

  @override
  State<ExploreItemDetailLoaderScreen> createState() =>
      _ExploreItemDetailLoaderScreenState();
}

class _ExploreItemDetailLoaderScreenState
    extends State<ExploreItemDetailLoaderScreen> {
  bool _loading = true;
  String? _error;

  UserProfile? _profile;
  SocialLink? _catalogLink;
  CatalogItem? _catalogItem;
  String _catalogType = 'catalog';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await AuthRepo().profileByUsername(
        username: widget.item.businessUsername,
      );
      if (!mounted) return;

      if (!res.success || res.data == null) {
        setState(() {
          _loading = false;
          _error = res.message ?? 'Could not open item';
        });
        return;
      }

      final data = res.data is Map
          ? Map<String, dynamic>.from(res.data as Map)
          : <String, dynamic>{};
      final userJson = data['user'] is Map
          ? Map<String, dynamic>.from(data['user'] as Map)
          : data;
      final profile = UserProfile.fromApiJson(userJson);
      final match = _findCatalogLink(profile.socialLinks, widget.item);

      if (match == null || profile.id == null) {
        setState(() {
          _loading = false;
          _error = 'This item is no longer available';
        });
        return;
      }

      CatalogItem? catalogItem;
      for (final c in match.catalogItems ?? const <CatalogItem>[]) {
        if (c.isActive && c.name.trim() == widget.item.name.trim()) {
          catalogItem = c;
          break;
        }
      }

      if (catalogItem == null) {
        setState(() {
          _loading = false;
          _error = 'This item is no longer available';
        });
        return;
      }

      final catalogType = (match.catalogType ?? widget.item.catalogType).trim();

      setState(() {
        _loading = false;
        _profile = profile;
        _catalogLink = match;
        _catalogItem = catalogItem;
        _catalogType = catalogType.isNotEmpty ? catalogType : 'catalog';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  static SocialLink? _findCatalogLink(
    List<SocialLink> links,
    ExploreItem item,
  ) {
    final wantedType = item.catalogType;
    SocialLink? fallback;

    for (final link in links) {
      if (!link.isActive || !link.isCatalogLink) continue;
      final items = link.catalogItems ?? const [];
      final hasItem = items.any(
        (c) => c.isActive && c.name.trim() == item.name.trim(),
      );
      if (!hasItem) continue;

      final type = link.catalogType ?? '';
      if (wantedType.isNotEmpty && type == wantedType) {
        return link;
      }
      fallback ??= link;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ExploreItemDetailShimmer();
    }

    if (_error != null ||
        _profile == null ||
        _catalogLink == null ||
        _catalogItem == null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Scaffold(
        backgroundColor:
            isDark ? AppTheme.primaryBlack : WaUi.toolsScaffold,
        appBar: AppBar(
          backgroundColor:
              isDark ? AppTheme.primaryBlack : WaUi.toolsScaffold,
          foregroundColor: isDark ? Colors.white : WaUi.primaryText,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error ?? 'Could not open item',
                  textAlign: TextAlign.center,
                  style: WaUi.body.copyWith(
                    color: isDark ? Colors.white70 : WaUi.secondaryText,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _load,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ExploreItemDetailScreen(
      exploreItem: widget.item,
      catalogItem: _catalogItem!,
      profile: _profile!,
      catalogLink: _catalogLink!,
      catalogType: _catalogType,
    );
  }
}
