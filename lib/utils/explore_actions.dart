import 'package:flutter/material.dart';
import 'package:tapni_app/models/catalog_item.dart';
import 'package:tapni_app/models/explore_business.dart';
import 'package:tapni_app/models/profile.dart';
import 'package:tapni_app/models/reward.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/repository/auth_repo.dart';
import 'package:tapni_app/repository/reward_repo.dart';
import 'package:tapni_app/screens/explore_item_detail_screen.dart';
import 'package:tapni_app/screens/loyalty_program/customer/customer_program_details_screen.dart';
import 'package:tapni_app/widgets/loading_widget.dart';

/// Opens real Explore flows: loyalty enroll → customer detail; item → detail page.
class ExploreActions {
  static Future<void> openOffer(
    BuildContext context,
    ExploreOffer offer,
  ) async {
    if (offer.id.isEmpty) return;

    CustomDialog.loadingDialog(context);
    final repo = RewardRepo();

    try {
      final mine = await repo.getMyEnrollments();
      if (!context.mounted) return;

      RewardEnrollment? existing;
      if (mine.success && mine.data != null) {
        final list = mine.data is List
            ? mine.data as List
            : (mine.data['data'] as List? ?? []);
        for (final raw in list) {
          if (raw is! Map) continue;
          final enrollment =
              RewardEnrollment.fromJson(Map<String, dynamic>.from(raw));
          if (enrollment.programId == offer.id ||
              enrollment.program?.id == offer.id) {
            existing = enrollment;
            break;
          }
        }
      }

      if (existing != null) {
        Navigator.pop(context); // loading
        if (!context.mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                CustomerProgramDetailsScreen(enrollment: existing!),
          ),
        );
        return;
      }

      final enrollRes = await repo.selfEnroll(offer.id);
      if (!context.mounted) return;
      Navigator.pop(context); // loading

      if (!enrollRes.success || enrollRes.data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enrollRes.message ?? 'Could not enroll in this reward program',
            ),
          ),
        );
        return;
      }

      final payload = enrollRes.data is Map
          ? (enrollRes.data['data'] ?? enrollRes.data)
          : enrollRes.data;
      if (payload is! Map) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid enrollment response')),
        );
        return;
      }

      final enrollment =
          RewardEnrollment.fromJson(Map<String, dynamic>.from(payload));
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CustomerProgramDetailsScreen(enrollment: enrollment),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  static Future<void> openCatalogItem(
    BuildContext context,
    ExploreItem item,
  ) async {
    if (item.businessUsername.isEmpty) return;

    CustomDialog.loadingDialog(context);
    try {
      final res = await AuthRepo().profileByUsername(
        username: item.businessUsername,
      );
      if (!context.mounted) return;
      Navigator.pop(context);

      if (!res.success || res.data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message ?? 'Could not open item'),
          ),
        );
        return;
      }

      final data = res.data is Map
          ? Map<String, dynamic>.from(res.data as Map)
          : <String, dynamic>{};
      final userJson = data['user'] is Map
          ? Map<String, dynamic>.from(data['user'] as Map)
          : data;
      final profile = UserProfile.fromApiJson(userJson);
      final match = _findCatalogLink(profile.socialLinks, item);
      if (match == null || profile.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This item is no longer available')),
        );
        return;
      }

      CatalogItem? catalogItem;
      for (final c in match.catalogItems ?? const <CatalogItem>[]) {
        if (c.isActive && c.name.trim() == item.name.trim()) {
          catalogItem = c;
          break;
        }
      }

      if (catalogItem == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This item is no longer available')),
        );
        return;
      }

      final catalogType = (match.catalogType ?? item.catalogType).trim();
      if (!context.mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ExploreItemDetailScreen(
            exploreItem: item,
            catalogItem: catalogItem!,
            profile: profile,
            catalogLink: match,
            catalogType: catalogType.isNotEmpty ? catalogType : 'catalog',
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
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
}
