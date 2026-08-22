import 'package:flutter/material.dart';

/// Barqody Help Center topics & articles (WhatsApp-style structure, our content).
class HelpCenterCatalog {
  HelpCenterCatalog._();

  static const List<HelpTopic> topics = [
    HelpTopic(
      id: 'getting_started',
      title: 'Getting Started',
      icon: Icons.flag_outlined,
      articles: [
        HelpArticle(
          id: 'create_account',
          title: 'How to create a Barqody account',
          body:
              'Open Barqody and sign in with your phone number. Enter the OTP sent to your phone, then complete your profile with your name, photo, and username so people can find and connect with you.',
        ),
        HelpArticle(
          id: 'edit_profile',
          title: 'How to edit your profile',
          body:
              'Go to Profile, tap Edit, then update your name, bio, photo, cover, and business details. Save when you are done. A complete profile helps you look more professional when someone scans your QR.',
        ),
        HelpArticle(
          id: 'add_links',
          title: 'How to add social and website links',
          body:
              'Open Links from the home tools, tap Add Link, choose a platform, and paste your URL or username. You can reorder links and turn them on or off anytime.',
        ),
      ],
    ),
    HelpTopic(
      id: 'digital_card',
      title: 'Digital Business Card',
      icon: Icons.badge_outlined,
      articles: [
        HelpArticle(
          id: 'share_card',
          title: 'How to share your digital card',
          body:
              'Open your card or QR screen and choose Share. You can send your profile link, show your QR for someone to scan, or download a card image to share on WhatsApp or email.',
        ),
        HelpArticle(
          id: 'customize_card',
          title: 'How to customize your card design',
          body:
              'From My Cards or Card Share, pick a template and adjust colors, layout, and details. Save your design so it appears whenever you share or download your card.',
        ),
        HelpArticle(
          id: 'qr_code',
          title: 'How to use your QR code',
          body:
              'Show your QR from the QR or Profile screen. When someone scans it with Barqody (or a camera that opens links), they can open your profile, save your contact, and exchange details.',
        ),
      ],
    ),
    HelpTopic(
      id: 'contacts_chats',
      title: 'Contacts & Chats',
      icon: Icons.chat_bubble_outline,
      articles: [
        HelpArticle(
          id: 'sync_contacts',
          title: 'How to sync phone contacts',
          body:
              'Allow contacts permission when prompted. Barqody finds which of your contacts already use the app so you can message or exchange cards quickly.',
        ),
        HelpArticle(
          id: 'exchange_contact',
          title: 'How to exchange contact details',
          body:
              'After scanning a profile or meeting someone, use Exchange Contact or Save Contact to keep their details in your leads and contacts list.',
        ),
        HelpArticle(
          id: 'leads',
          title: 'Understanding leads',
          body:
              'Leads are people you scanned, who scanned you, or contacts you exchanged. Open Leads to filter, search, and follow up with potential customers.',
        ),
      ],
    ),
    HelpTopic(
      id: 'business_tools',
      title: 'Business Tools',
      icon: Icons.storefront_outlined,
      articles: [
        HelpArticle(
          id: 'go_business',
          title: 'How to go business / Pro',
          body:
              'Open Go Business or Subscription from settings. Choose a plan to unlock business tools like attendance, loyalty programs, catalogs, and more team features.',
        ),
        HelpArticle(
          id: 'catalog',
          title: 'How to manage catalog and orders',
          body:
              'Add products or services in Catalog, then share them from your profile. When customers place requests, manage them from Orders.',
        ),
        HelpArticle(
          id: 'invitations',
          title: 'How to create event invitations',
          body:
              'Open Invitations, choose a template, customize the design, then invite people from your contacts. Guests receive the invitation in the app.',
        ),
      ],
    ),
    HelpTopic(
      id: 'loyalty',
      title: 'Loyalty Programs',
      icon: Icons.card_giftcard_outlined,
      articles: [
        HelpArticle(
          id: 'create_loyalty',
          title: 'How to create a loyalty program',
          body:
              'Open Loyalty Programs, tap Create Program, pick a card template, set stamps and reward text, then save. Customers can collect stamps when they visit.',
        ),
        HelpArticle(
          id: 'add_stamps',
          title: 'How to add stamps for customers',
          body:
              'From your loyalty program details, use Add Stamp and scan or select the customer. Each stamp moves them closer to the reward you set.',
        ),
      ],
    ),
    HelpTopic(
      id: 'workplace',
      title: 'Workplace & Attendance',
      icon: Icons.work_outline,
      articles: [
        HelpArticle(
          id: 'employee_invite',
          title: 'How employee invitations work',
          body:
              'A business can invite you by scanning your QR. Open Workplace → Employee Invitations to accept or decline. After you accept, you can check in and get an employee card.',
        ),
        HelpArticle(
          id: 'check_in',
          title: 'How to check in at work',
          body:
              'Open Workplace → Workplace Check-In, select your company, then Check In. Location (and face photo if required) must match the workplace settings your employer set.',
        ),
        HelpArticle(
          id: 'employee_card',
          title: 'Company employee card',
          body:
              'After joining a company, open Workplace → Company Employee Card to view, customize, and save your work ID card to your phone or wallet.',
        ),
      ],
    ),
    HelpTopic(
      id: 'privacy_security',
      title: 'Privacy & Security',
      icon: Icons.lock_outline,
      articles: [
        HelpArticle(
          id: 'account_security',
          title: 'Keep your account secure',
          body:
              'Only enter OTPs sent to your own phone. Do not share login codes. If you lose access to your number, contact support so we can help recover your account safely.',
        ),
        HelpArticle(
          id: 'profile_visibility',
          title: 'Who can see your profile',
          body:
              'People who scan your QR or open your shared link can view the public parts of your profile and links. You control what you publish on your card and links list.',
        ),
      ],
    ),
    HelpTopic(
      id: 'account',
      title: 'Account',
      icon: Icons.person_outline,
      articles: [
        HelpArticle(
          id: 'switch_accounts',
          title: 'How to switch accounts',
          body:
              'Open Settings → Accounts to switch between saved Barqody accounts on this device, or add another number if you manage more than one profile.',
        ),
        HelpArticle(
          id: 'logout',
          title: 'How to log out',
          body:
              'Go to Settings and tap Log out. You can sign back in anytime with your phone number and OTP.',
        ),
        HelpArticle(
          id: 'language',
          title: 'How to change app language',
          body:
              'Open Settings → App language and choose your preferred language. The app UI updates to match your selection.',
        ),
      ],
    ),
  ];

  static List<HelpArticle> get popularArticles => const [
        HelpArticle(
          id: 'create_account',
          title: 'How to create a Barqody account',
          body:
              'Open Barqody and sign in with your phone number. Enter the OTP sent to your phone, then complete your profile with your name, photo, and username so people can find and connect with you.',
        ),
        HelpArticle(
          id: 'share_card',
          title: 'How to share your digital card',
          body:
              'Open your card or QR screen and choose Share. You can send your profile link, show your QR for someone to scan, or download a card image to share on WhatsApp or email.',
        ),
        HelpArticle(
          id: 'employee_invite',
          title: 'How employee invitations work',
          body:
              'A business can invite you by scanning your QR. Open Workplace → Employee Invitations to accept or decline. After you accept, you can check in and get an employee card.',
        ),
        HelpArticle(
          id: 'create_loyalty',
          title: 'How to create a loyalty program',
          body:
              'Open Loyalty Programs, tap Create Program, pick a card template, set stamps and reward text, then save. Customers can collect stamps when they visit.',
        ),
      ];

  static HelpTopic? topicById(String id) {
    for (final t in topics) {
      if (t.id == id) return t;
    }
    return null;
  }

  static HelpArticle? articleById(String id) {
    for (final t in topics) {
      for (final a in t.articles) {
        if (a.id == id) return a;
      }
    }
    for (final a in popularArticles) {
      if (a.id == id) return a;
    }
    return null;
  }

  static List<HelpTopic> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return topics;
    return topics
        .where(
          (t) =>
              t.title.toLowerCase().contains(q) ||
              t.articles.any(
                (a) =>
                    a.title.toLowerCase().contains(q) ||
                    a.body.toLowerCase().contains(q),
              ),
        )
        .toList();
  }

  static List<HelpArticle> searchArticles(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final results = <HelpArticle>[];
    for (final t in topics) {
      for (final a in t.articles) {
        if (a.title.toLowerCase().contains(q) ||
            a.body.toLowerCase().contains(q)) {
          results.add(a);
        }
      }
    }
    return results;
  }
}

class HelpTopic {
  final String id;
  final String title;
  final IconData icon;
  final List<HelpArticle> articles;

  const HelpTopic({
    required this.id,
    required this.title,
    required this.icon,
    required this.articles,
  });
}

class HelpArticle {
  final String id;
  final String title;
  final String body;

  const HelpArticle({
    required this.id,
    required this.title,
    required this.body,
  });
}
