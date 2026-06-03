import 'package:tapni_app/models/profile.dart';
import 'package:tapni_app/models/social_link.dart';
import 'package:tapni_app/models/lead.dart';
import 'package:tapni_app/models/activity.dart';

class MockDataService {
  static UserProfile getInitialProfile() {
    return UserProfile(
      name: 'Saim Y',
      designation: 'Senior Product Designer',
      company: 'Antigravity Studio',
      bio:
          'Creating immersive digital experiences. Hit the links below to connect with me or download my contact card!',
      phone: '+1 (555) 019-2834',
      email: 'saimy@antigravity.io',
      website: 'www.antigravity.io',
      // avatarUrl: null, // Custom design initials will be rendered
      viewsCount: 1420,
      scansCount: 894,
      leadsCount: 128,
      socialLinks: [
        SocialLink(
          id: '1',
          platform: SocialPlatform.linkedIn,
          value: 'saimy-designer',
          isActive: true,
        ),
        SocialLink(
          id: '2',
          platform: SocialPlatform.whatsApp,
          value: '+15550192834',
          isActive: true,
        ),
        SocialLink(
          id: '3',
          platform: SocialPlatform.instagram,
          value: 'saimy.design',
          isActive: true,
        ),
        SocialLink(
          id: '4',
          platform: SocialPlatform.facebook,
          value: 'saimy.creative',
          isActive: false,
        ),
        SocialLink(
          id: '5',
          platform: SocialPlatform.youTube,
          value: '@antigravitystudio',
          isActive: true,
        ),
        SocialLink(
          id: '6',
          platform: SocialPlatform.website,
          value: 'https://antigravity.io',
          isActive: true,
        ),
      ],
    );
  }

  static List<Lead> getInitialLeads() {
    return [
      Lead(
        id: 'l1',
        name: 'Jane Doe',
        email: 'jane.doe@techcorp.com',
        phone: '+1 (555) 432-1098',
        company: 'TechCorp Solutions',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Lead(
        id: 'l2',
        name: 'Alex Johnson',
        email: 'alex.j@innovate.co',
        phone: '+1 (555) 876-5432',
        company: 'Innovate Labs',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Lead(
        id: 'l3',
        name: 'Sarah Connor',
        email: 's.connor@cyberdyne.io',
        phone: '+1 (555) 901-2345',
        company: 'Cyberdyne Systems',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Lead(
        id: 'l4',
        name: 'Michael Scott',
        email: 'mscott@dundermifflin.com',
        phone: '+1 (555) 123-4567',
        company: 'Dunder Mifflin Paper Co.',
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Lead(
        id: 'l5',
        name: 'Bruce Wayne',
        email: 'bruce@wayneenterprises.com',
        phone: '+1 (555) 999-0000',
        company: 'Wayne Enterprises',
        timestamp: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];
  }

  static List<Activity> getInitialActivities() {
    return [
      Activity(
        id: 'a1',
        title: 'New Contact Captured',
        description: 'Jane Doe added their contact details',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: ActivityType.lead,
      ),
      Activity(
        id: 'a2',
        title: 'Profile Viewed',
        description: 'Someone viewed your card via direct link',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        type: ActivityType.view,
      ),
      Activity(
        id: 'a3',
        title: 'QR Code Scanned',
        description: 'Profile scanned at Networking Summit 2026',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: ActivityType.scan,
      ),
      Activity(
        id: 'a4',
        title: 'Card Shared',
        description: 'You shared your card link via WhatsApp',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        type: ActivityType.share,
      ),
      Activity(
        id: 'a5',
        title: 'System Welcome',
        description: 'Tapni Business Account successfully activated',
        timestamp: DateTime.now().subtract(const Duration(days: 10)),
        type: ActivityType.system,
      ),
    ];
  }

  static Map<String, List<double>> getAnalyticsData() {
    return {
      'profileViews': [15, 30, 25, 45, 50, 75, 60], // last 7 days
      'qrScans': [8, 12, 10, 22, 35, 40, 28],
      'leadsCollected': [1, 3, 2, 5, 8, 12, 6],
    };
  }

  static List<Map<String, dynamic>> getMockNotifications() {
    return [
      {
        'id': 'n1',
        'title': '🔥 Trending Profile!',
        'body': 'Your profile views increased by 45% this week. Keep sharing!',
        'time': 'Just now',
        'isRead': false,
      },
      {
        'id': 'n2',
        'title': '🤝 New Contact Connection',
        'body': 'Alex Johnson saved your digital card and left notes.',
        'time': '2 hours ago',
        'isRead': false,
      },
      {
        'id': 'n3',
        'title': '🆕 Feature Launch',
        'body': 'You can now customize your QR code styling with Gold accent.',
        'time': 'Yesterday',
        'isRead': true,
      },
      {
        'id': 'n4',
        'title': '📈 Monthly Summary',
        'body':
            'In May, you collected 42 leads and received 620 profile scans.',
        'time': '3 days ago',
        'isRead': true,
      },
    ];
  }
}
