import 'package:flutter/material.dart';
import 'package:tapni_app/screens/business_website/business_presence_ui.dart';
import 'package:tapni_app/utils/app_page_transitions.dart';
import 'package:tapni_app/widgets/auth_ui.dart';
import 'package:tapni_app/widgets/barqody_chrome.dart';

enum GuideAudience { business, customer }

/// Opens the app guide hub.
///
/// - [isBusinessUser] true → can open Business guide + Customer guide
/// - [isBusinessUser] false → Customer guide only
/// - [openAudience] skips the Business/Customer picker when set
/// - [websiteType] pre-fills type for business topics that need it
Future<void> showAppGuide(
  BuildContext context, {
  String? websiteType,
  bool isBusinessUser = false,
  GuideAudience? openAudience,
}) {
  final audience = isBusinessUser
      ? openAudience
      : GuideAudience.customer;
  return Navigator.of(context).push<void>(
    AppPageRoute(
      builder: (_) => BusinessWebsiteSetupGuideScreen(
        initialWebsiteType: websiteType,
        isBusinessUser: isBusinessUser,
        initialAudience: audience,
      ),
    ),
  );
}

/// Business Suite / website settings entry (business users see both guides).
Future<void> showBusinessWebsiteSetupGuide(
  BuildContext context, {
  String? websiteType,
  GuideAudience? openAudience,
}) {
  return showAppGuide(
    context,
    websiteType: websiteType,
    isBusinessUser: true,
    openAudience: openAudience,
  );
}

/// Tools / Settings entry for every signed-in user.
Future<void> showCustomerAppGuide(BuildContext context) {
  return showAppGuide(
    context,
    isBusinessUser: false,
    openAudience: GuideAudience.customer,
  );
}

class _GuideStep {
  final String title;
  final String body;
  final String where;

  const _GuideStep({
    required this.title,
    required this.body,
    required this.where,
  });
}

class _SiteType {
  final String id;
  final String label;
  final String blurb;
  final IconData icon;

  const _SiteType({
    required this.id,
    required this.label,
    required this.blurb,
    required this.icon,
  });
}

class _GuideTopic {
  final String id;
  final String title;
  final String blurb;
  final String explainer;
  final IconData icon;
  final bool needsWebsiteType;
  final bool commerceOnly;

  const _GuideTopic({
    required this.id,
    required this.title,
    required this.blurb,
    required this.explainer,
    required this.icon,
    this.needsWebsiteType = false,
    this.commerceOnly = false,
  });
}

const _kSiteTypes = <_SiteType>[
  _SiteType(
    id: 'menu',
    label: 'Menu',
    blurb: 'Customers order food or drinks from your link',
    icon: Icons.restaurant_menu_outlined,
  ),
  _SiteType(
    id: 'service',
    label: 'Services',
    blurb: 'Customers book appointments (salon, clinic, etc.)',
    icon: Icons.design_services_outlined,
  ),
  _SiteType(
    id: 'products',
    label: 'Products',
    blurb: 'Customers buy or book products / rooms / rentals',
    icon: Icons.inventory_2_outlined,
  ),
  _SiteType(
    id: 'portfolio',
    label: 'Portfolio',
    blurb: 'Show your work only — no cart or payments',
    icon: Icons.photo_library_outlined,
  ),
];

const _kBusinessTopics = <_GuideTopic>[
  _GuideTopic(
    id: 'go_live',
    title: 'Go live',
    blurb: 'How your public website gets online and shared',
    explainer:
        'Your Barqody website is a public page customers open from a link. '
        'First you finish your profile, pick a ready-made design (template), '
        'add your look, then turn Status on and share the URL. Until Status is on, '
        'customers usually cannot use the live site.',
    icon: Icons.rocket_launch_outlined,
    needsWebsiteType: true,
  ),
  _GuideTopic(
    id: 'catalog',
    title: 'Catalog & sections',
    blurb: 'What customers see to order, book, or browse',
    explainer:
        'A catalog is your list of things on the website (dishes, services, products, or portfolio pieces). '
        'Sections are folders/categories (e.g. “Burgers”, “Haircuts”). '
        'Customers browse sections, open an item, then add to cart or book — '
        'so clear photos, prices, and names matter.',
    icon: Icons.grid_view_rounded,
    needsWebsiteType: true,
  ),
  _GuideTopic(
    id: 'booking',
    title: 'Booking setup',
    blurb: 'How tables, rooms, and staff get chosen',
    explainer:
        'If customers must pick a table, room, equipment, or a specific person, '
        'you set those up here. The website shows what is available; your calendar '
        'blocks busy times so two people cannot take the same slot. '
        'Skip this if you only take simple orders with no seat/room/staff choice.',
    icon: Icons.event_available_outlined,
    needsWebsiteType: true,
    commerceOnly: true,
  ),
  _GuideTopic(
    id: 'orders',
    title: 'Orders & bookings',
    blurb: 'What happens after a customer places a request',
    explainer:
        'When someone orders or books on your site, it appears in Orders & Bookings. '
        'You confirm it, prepare it, then mark it complete when paid or cash is collected. '
        '“Complete” means the job is done — and it can also give loyalty stamps if you set that up.',
    icon: Icons.receipt_long_outlined,
    commerceOnly: true,
  ),
  _GuideTopic(
    id: 'offers',
    title: 'Offers & coupons',
    blurb: 'How discounts show up for customers',
    explainer:
        'Offers are promotions you create (percent or fixed off, with dates). '
        'You choose which website types they apply to (menu, services, products). '
        'Customers see the deal on the site or enter a coupon at checkout — '
        'you do not change every item price by hand.',
    icon: Icons.local_offer_outlined,
    commerceOnly: true,
  ),
  _GuideTopic(
    id: 'stamps',
    title: 'Stamp rewards',
    blurb: 'How stamp cards earn and how rewards are claimed',
    explainer:
        'A stamp card is like “buy 5, get 1 free.” Each qualifying visit/purchase adds one stamp. '
        'You can link one catalog item so stamps happen automatically when a logged-in customer buys it, '
        'or write a simple rule for staff and stamp manually. '
        'When the card is full, the customer claims the reward online (free order) or in your shop (you tap Mark claimed).',
    icon: Icons.loyalty_outlined,
    needsWebsiteType: true,
    commerceOnly: true,
  ),
  _GuideTopic(
    id: 'grow',
    title: 'Grow',
    blurb: 'Extra tools after your site is running',
    explainer:
        'These are optional. POS connect pushes orders into kitchen/POS tools you already use. '
        'Banner ads promote your business inside Barqody. '
        'You can ignore both until the website and orders are working smoothly.',
    icon: Icons.trending_up_rounded,
  ),
];

const _kCustomerTopics = <_GuideTopic>[
  _GuideTopic(
    id: 'c_browse',
    title: 'Browse a business website',
    blurb: 'How you open a shop link and what you can do there',
    explainer:
        'Businesses share a Barqody website link (or QR). Opening it shows their menu, services, products, or portfolio. '
        'On menu/products/services sites you can add items to a cart or book a slot. '
        'Portfolio sites are for viewing work only — no checkout.',
    icon: Icons.language_outlined,
  ),
  _GuideTopic(
    id: 'c_order',
    title: 'Order or book',
    blurb: 'Cart, checkout, guest vs logged-in',
    explainer:
        'Add items (or pick a booking time), then checkout. '
        'You can continue as a guest with contact details, or stay logged in to Barqody. '
        'Logged-in orders are easier to track and can earn stamp rewards. '
        'Guest orders can later be claimed into your account.',
    icon: Icons.shopping_bag_outlined,
  ),
  _GuideTopic(
    id: 'c_track',
    title: 'My Orders & Bookings',
    blurb: 'Track status and claim guest orders',
    explainer:
        '“My Orders & Bookings” is your list of everything you placed. '
        'Open an order to see status (pending, confirmed, completed). '
        'If you ordered as a guest, claim it to your account so it stays in this list and can count for rewards.',
    icon: Icons.receipt_long_outlined,
  ),
  _GuideTopic(
    id: 'c_stamps',
    title: 'Stamp cards & rewards',
    blurb: 'How you earn stamps and claim a free reward',
    explainer:
        'Some businesses give digital stamp cards. Buying the linked item (while logged in) can add a stamp automatically. '
        'Other cards need staff to stamp you in-store. '
        'When the card is full, tap Claim for a free reward order, or show the card in the shop so staff can mark it claimed.',
    icon: Icons.loyalty_outlined,
  ),
  _GuideTopic(
    id: 'c_offers',
    title: 'Offers & coupons',
    blurb: 'How discounts appear when you buy',
    explainer:
        'Businesses can run sales or coupons. Some discounts show on the item or cart automatically. '
        'Others need a coupon code at checkout. If a code fails, it may be expired or for a different site type.',
    icon: Icons.local_offer_outlined,
  ),
];

class BusinessWebsiteSetupGuideScreen extends StatefulWidget {
  final String? initialWebsiteType;
  final bool isBusinessUser;
  final GuideAudience? initialAudience;

  const BusinessWebsiteSetupGuideScreen({
    super.key,
    this.initialWebsiteType,
    this.isBusinessUser = false,
    this.initialAudience,
  });

  @override
  State<BusinessWebsiteSetupGuideScreen> createState() =>
      _BusinessWebsiteSetupGuideScreenState();
}

class _BusinessWebsiteSetupGuideScreenState
    extends State<BusinessWebsiteSetupGuideScreen> {
  late final String? _lockedType;
  String? _type;
  GuideAudience? _audience;
  String? _topicId;
  bool _pickingTypeForTopic = false;

  @override
  void initState() {
    super.initState();
    final raw = (widget.initialWebsiteType ?? '').trim().toLowerCase();
    final normalized = switch (raw) {
      'service' || 'services' => 'service',
      'products' || 'product' => 'products',
      'portfolio' => 'portfolio',
      'menu' || 'catalog' => 'menu',
      _ => null,
    };
    _lockedType = normalized;
    _type = normalized;
    if (!widget.isBusinessUser) {
      _audience = GuideAudience.customer;
    } else {
      _audience = widget.initialAudience;
    }
  }

  String get _typeLabel {
    switch (_type) {
      case 'service':
        return 'Services';
      case 'products':
        return 'Products';
      case 'portfolio':
        return 'Portfolio';
      case 'menu':
        return 'Menu';
      default:
        return 'website';
    }
  }

  String get _itemWord {
    switch (_type) {
      case 'service':
        return 'services';
      case 'products':
        return 'products';
      case 'portfolio':
        return 'portfolio items';
      case 'menu':
      default:
        return 'menu items';
    }
  }

  String get _manageTab {
    switch (_type) {
      case 'service':
        return 'Services';
      case 'products':
        return 'Products';
      case 'portfolio':
        return 'Portfolio';
      case 'menu':
      default:
        return 'Menu';
    }
  }

  String get _customerActionWord {
    switch (_type) {
      case 'service':
        return 'book';
      case 'portfolio':
        return 'browse';
      case 'products':
        return 'buy or book';
      case 'menu':
      default:
        return 'order';
    }
  }

  bool get _isCustomerAudience => _audience == GuideAudience.customer;

  List<_GuideTopic> get _topicCatalog =>
      _isCustomerAudience ? _kCustomerTopics : _kBusinessTopics;

  _GuideTopic? get _activeTopic {
    final id = _topicId;
    if (id == null) return null;
    for (final t in _topicCatalog) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<_GuideTopic> get _visibleTopics {
    if (_isCustomerAudience) return _kCustomerTopics;
    final lockedIsPortfolio = _lockedType == 'portfolio' || _type == 'portfolio';
    return _kBusinessTopics.where((t) {
      if (!t.commerceOnly) return true;
      if (_type == null && _lockedType == null) return true;
      return !lockedIsPortfolio;
    }).toList();
  }

  List<_GuideStep> get _topicSteps {
    final topic = _activeTopic;
    if (topic == null) return const [];
    switch (topic.id) {
      case 'go_live':
        return _goLiveSteps;
      case 'catalog':
        return _catalogSteps;
      case 'booking':
        return _bookingSteps;
      case 'orders':
        return _ordersSteps;
      case 'offers':
        return _offersSteps;
      case 'stamps':
        return _stampSteps;
      case 'grow':
        return _growSteps;
      case 'c_browse':
        return _customerBrowseSteps;
      case 'c_order':
        return _customerOrderSteps;
      case 'c_track':
        return _customerTrackSteps;
      case 'c_stamps':
        return _customerStampSteps;
      case 'c_offers':
        return _customerOfferSteps;
      default:
        return const [];
    }
  }

  List<_GuideStep> get _goLiveSteps => [
        const _GuideStep(
          title: 'Make your profile look trustworthy',
          body:
              'Customers see your name, photo, cover, and bio on the site. If these are empty or unclear, the page feels unfinished — fill them first.',
          where: 'Profile',
        ),
        const _GuideStep(
          title: 'Tell Barqody what your business is',
          body:
              'Business name, industry, and map location help people find you in Explore and understand who you are when they open the link.',
          where: 'Profile → Business profile',
        ),
        _GuideStep(
          title: 'Create a $_typeLabel website',
          body:
              'This adds a public $_typeLabel site to your profile. You pick a business category, then a subcategory, then a template (the layout customers will see).',
          where: 'Profile → Add link → $_typeLabel',
        ),
        const _GuideStep(
          title: 'Preview before you create',
          body:
              'Sample preview shows fake demo items in that template so you can judge the design. Nothing is saved until you create the website.',
          where: 'Create website → Template → Preview',
        ),
        const _GuideStep(
          title: 'Match the look to your brand',
          body:
              'Theme color, homepage headline, and logo/bio toggles change how the live template looks — without rebuilding the whole site.',
          where: 'Settings → Customize Website',
        ),
        const _GuideStep(
          title: 'Switch template if you change your mind',
          body:
              'Changing template only changes the design. Your catalog (items and sections) stays — you do not re-add everything.',
          where: 'Settings → Change template',
        ),
        const _GuideStep(
          title: 'Turn the site on',
          body:
              'Status = on means the public link works. Live Preview lets you check phone and desktop before you share widely.',
          where: 'Settings → Status / Live Preview',
        ),
        _GuideStep(
          title: 'Share the link with customers',
          body:
              'Copy or share the URL. That is how customers $_customerActionWord — WhatsApp, Instagram, QR, or your Google listing.',
          where: 'Settings → Share / Copy URL',
        ),
      ];

  List<_GuideStep> get _catalogSteps {
    final steps = <_GuideStep>[
      _GuideStep(
        title: 'Make sections (categories) first',
        body:
            'Sections are groups on the website — like menus on a restaurant board. Create them before items so customers can find $_itemWord quickly.',
        where: 'Business Presence → $_manageTab → Sections',
      ),
      _GuideStep(
        title: 'Add the $_itemWord customers will see',
        body: _type == 'portfolio'
            ? 'Each piece needs a photo, title, and short story. Portfolio sites are for viewing only — there is no cart, price checkout, or payment.'
            : 'Each item needs a clear photo, name, price, and short description. Turn the item on so it appears. You can also set an item-level discount that shows as a sale price.',
        where: 'Business Presence → $_manageTab',
      ),
    ];
    if (_type == 'service') {
      steps.add(
        const _GuideStep(
          title: 'Tell each service how booking works',
          body:
              'Booking type, duration, and open days/hours decide what times customers can pick. Without this, the site cannot offer real appointment slots.',
          where: 'Services → Item → Booking & schedule',
        ),
      );
    }
    if (_type == 'products') {
      steps.add(
        const _GuideStep(
          title: 'Name products the same way you sell them',
          body:
              'If a product is a room or rental, use the same name in Rooms & tables later so booking can match the right resource. Clear prices reduce confusion at checkout.',
          where: 'Products tab + Business Suite → Rooms & tables',
        ),
      );
    }
    return steps;
  }

  List<_GuideStep> get _bookingSteps => const [
        _GuideStep(
          title: 'Add what customers can reserve',
          body:
              'Tables, rooms, or equipment are the physical things people choose. If your flow does not ask for these, you can skip this step.',
          where: 'Business Suite → Rooms & tables',
        ),
        _GuideStep(
          title: 'Let customers pick a person (optional)',
          body:
              'For salons/clinics, turn on “bookable specialist” on a team member so the site can offer that person as a choice. Skip if anyone on the team can do the job.',
          where: 'Business Suite → Team → Employee → Settings',
        ),
        _GuideStep(
          title: 'Keep the calendar honest',
          body:
              'The booking calendar shows when you are busy. Check it so new online bookings do not clash with walk-ins or other appointments.',
          where: 'Business Suite → Booking calendar',
        ),
      ];

  List<_GuideStep> get _ordersSteps => const [
        _GuideStep(
          title: 'Watch the Orders & Bookings list',
          body:
              'Every website order or booking lands here. Open it to see what the customer wants, their contact, and payment status — this is your daily inbox for the site.',
          where: 'Business Suite → Orders & Bookings',
        ),
        _GuideStep(
          title: 'Confirm, then complete when done',
          body:
              'Confirm so the customer knows you accepted it. Mark complete only when the order/booking is finished and money is settled (online paid or cash collected). That “complete” step is also what can trigger stamp rewards.',
          where: 'Orders → Confirm / Complete',
        ),
      ];

  List<_GuideStep> get _offersSteps => const [
        _GuideStep(
          title: 'Create one promotion',
          body:
              'Choose percent or fixed amount off, start/end dates, and which catalog types get the deal. The site and checkout apply it for you.',
          where: 'Business Suite → Offers',
        ),
        _GuideStep(
          title: 'How customers use it',
          body:
              'Some offers show automatically; coupons are entered at checkout. If nothing looks discounted, check dates and that the offer includes the right website type (menu / services / products).',
          where: 'Customer site → Cart / Checkout',
        ),
      ];

  List<_GuideStep> get _stampSteps => [
        const _GuideStep(
          title: 'Create the stamp card',
          body:
              'Think of it as a digital punch card: title (what they win), how many stamps are needed, and the look of the card. Draft = only you see it. Go live = customers can join and earn.',
          where: 'Business Suite → Loyalty → Create stamp card',
        ),
        _GuideStep(
          title: 'Option A — Link one catalog item',
          body:
              'Choose one of your $_itemWord (e.g. “Classic Burger”). Then: logged-in customer buys that item → order is completed & paid/cash → they get the card if needed → +1 stamp → they get a notification. One order = one stamp (not per quantity).',
          where: 'Loyalty → Design → How to earn → Select item',
        ),
        const _GuideStep(
          title: 'Option B — Write a staff rule instead',
          body:
              'Leave the item empty and write something like “Any burger”. The card shows this text, but orders will not auto-stamp. Staff enroll with QR or add stamps manually when the rule is met — good for busy walk-in shops.',
          where: 'Loyalty → Design → How to earn',
        ),
        const _GuideStep(
          title: 'Guest orders need an account later',
          body:
              'Website guests who check out without login do not get stamps yet. After they claim that order to their Barqody account, loyalty can catch up. Logged-in buyers get stamps right away when rules match.',
          where: 'Automatic after order claim / login',
        ),
        const _GuideStep(
          title: 'When stamps reach the target',
          body:
              'The card becomes “completed.” Both you and the customer get a notification so you can prepare the free reward.',
          where: 'Notifications + Loyalty enrollments',
        ),
        const _GuideStep(
          title: 'Claim path 1 — Free reward order',
          body:
              'Customer taps Claim in the app. Barqody creates a no-charge reward order for you (like a normal order but payment is free). You fulfill it; status stays claim-pending until finished.',
          where: 'Customer app → Stamp card → Claim',
        ),
        const _GuideStep(
          title: 'Claim path 2 — In your shop',
          body:
              'Customer shows the completed card. You open their enrollment and tap Mark claimed. No free order is created — you just confirm they got the reward in person.',
          where: 'Loyalty → Program → Enrollment → Mark claimed',
        ),
        const _GuideStep(
          title: 'Points are separate (optional)',
          body:
              'Points are a different loyalty style (earn points, spend points). You can use stamps only, points only, or both — stamps do not require points.',
          where: 'Business Suite → Loyalty → Points',
        ),
      ];

  List<_GuideStep> get _growSteps => const [
        _GuideStep(
          title: 'POS connect',
          body:
              'Use this only if you already run a kitchen/POS system and want Barqody orders to appear there. It does not replace Orders & Bookings inside the app.',
          where: 'Business Suite → POS',
        ),
        _GuideStep(
          title: 'Banner ads',
          body:
              'Paid placements that show your business to more Barqody users. Useful after your website and fulfillment are solid — not required to go live.',
          where: 'Business Suite → Banner Ads',
        ),
      ];

  List<_GuideStep> get _customerBrowseSteps => const [
        _GuideStep(
          title: 'Open the business link',
          body:
              'Tap the link or scan the QR the business shared. The website opens in Barqody (or a browser preview). You see their homepage, sections, and items.',
          where: 'Shared link / QR',
        ),
        _GuideStep(
          title: 'Browse sections and item details',
          body:
              'Sections group items (like categories). Open an item to read description, price, duration, or photos before you decide.',
          where: 'Website → Section → Item',
        ),
        _GuideStep(
          title: 'Know what the site can do',
          body:
              'Menu/products: order. Services: book a time. Portfolio: view only. If you do not see Add / Book, it may be portfolio or the item is turned off.',
          where: 'Website',
        ),
      ];

  List<_GuideStep> get _customerOrderSteps => const [
        _GuideStep(
          title: 'Add to cart or pick a slot',
          body:
              'For orders, add items and open the cart. For bookings, choose date/time (and sometimes a room or specialist), then continue.',
          where: 'Website → Cart / Booking',
        ),
        _GuideStep(
          title: 'Checkout as guest or logged in',
          body:
              'Guest = enter name/phone and place the order without signing up. Logged in = saved to your Barqody account, easier tracking, and eligible for auto stamps.',
          where: 'Checkout',
        ),
        _GuideStep(
          title: 'Pay or pay at the shop',
          body:
              'Some businesses take online payment; others ask for cash on delivery / at the counter. Follow the options shown at checkout — the business confirms after they receive the request.',
          where: 'Checkout → Payment',
        ),
      ];

  List<_GuideStep> get _customerTrackSteps => const [
        _GuideStep(
          title: 'Open My Orders & Bookings',
          body:
              'This list shows requests tied to your account. Status updates when the business confirms or completes your order.',
          where: 'Tools → My Orders & Bookings',
        ),
        _GuideStep(
          title: 'Claim a guest order',
          body:
              'Ordered without login? Use the claim flow (from order tracking / prompt) to attach it to your account so it appears here and can earn rewards later.',
          where: 'Order tracking → Claim to account',
        ),
      ];

  List<_GuideStep> get _customerStampSteps => const [
        _GuideStep(
          title: 'Find your stamp cards',
          body:
              'Reward cards you joined live under My Reward Cards. Open a card to see how many stamps you have and what you win.',
          where: 'Tools → My Reward Cards',
        ),
        _GuideStep(
          title: 'How stamps get added',
          body:
              'If the business linked an item: buy that item while logged in, and when they mark the order complete you usually get +1 stamp automatically. If there is only a written rule, staff may stamp you in the shop or via QR.',
          where: 'Purchase / shop visit',
        ),
        _GuideStep(
          title: 'Claim when the card is full',
          body:
              'Completed card → Claim free reward (creates a no-charge order for the business) OR show the card in person so staff taps Mark claimed. You will see Claim pending until they finish.',
          where: 'Reward card → Claim',
        ),
      ];

  List<_GuideStep> get _customerOfferSteps => const [
        _GuideStep(
          title: 'Spot a sale on the site',
          body:
              'Discounted items often show a sale price or badge. Cart totals update when an automatic offer applies.',
          where: 'Website / Cart',
        ),
        _GuideStep(
          title: 'Enter a coupon if you have one',
          body:
              'At checkout, look for a coupon field. Codes are set by the business and may expire or apply only to certain site types.',
          where: 'Checkout → Coupon',
        ),
      ];

  void _openAudience(GuideAudience audience) {
    if (audience == GuideAudience.business && !widget.isBusinessUser) return;
    setState(() {
      _audience = audience;
      _topicId = null;
      _pickingTypeForTopic = false;
      if (_lockedType == null) _type = null;
    });
  }

  void _openTopic(_GuideTopic topic) {
    if (!_isCustomerAudience &&
        topic.commerceOnly &&
        _type == 'portfolio') {
      return;
    }
    if (!_isCustomerAudience &&
        topic.needsWebsiteType &&
        _type == null) {
      setState(() {
        _topicId = topic.id;
        _pickingTypeForTopic = true;
      });
      return;
    }
    setState(() {
      _topicId = topic.id;
      _pickingTypeForTopic = false;
    });
  }

  void _onBack() {
    if (_pickingTypeForTopic) {
      setState(() {
        _pickingTypeForTopic = false;
        _topicId = null;
        if (_lockedType == null) _type = null;
      });
      return;
    }
    if (_topicId != null) {
      setState(() {
        _topicId = null;
        if (_lockedType == null) _type = _lockedType;
      });
      return;
    }
    // Business users return to audience picker unless audience was forced.
    if (widget.isBusinessUser &&
        _audience != null &&
        widget.initialAudience == null) {
      setState(() => _audience = null);
      return;
    }
    Navigator.of(context).maybePop();
  }

  String get _titleBar {
    if (_pickingTypeForTopic) return 'Website type';
    final topic = _activeTopic;
    if (topic != null) return topic.title;
    if (_audience == GuideAudience.business) return 'Business guide';
    if (_audience == GuideAudience.customer) return 'Customer guide';
    return 'Guides';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final showingSteps = _topicId != null && !_pickingTypeForTopic;
    final pickingAudience = widget.isBusinessUser && _audience == null;

    return Scaffold(
      backgroundColor: BwUi.pageBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BarqodyTitleBar(
              title: _titleBar,
              onBack: _onBack,
            ),
            Expanded(
              child: pickingAudience
                  ? _buildAudiencePicker()
                  : _pickingTypeForTopic
                      ? _buildTypePicker()
                      : showingSteps
                          ? _buildStepsView(bottom)
                          : _buildTopicHub(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudiencePicker() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const Text(
          'Which guide do you need?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.15,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Business guide is for running your site. Customer guide explains ordering, tracking, and rewards — useful for you too when you buy from others.',
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w500,
            color: AuthUi.textSecondary,
          ),
        ),
        const SizedBox(height: 22),
        _audienceCard(
          title: 'Business guide',
          blurb:
              'Go live, catalog, bookings, orders, offers, stamp cards, and growth tools',
          icon: Icons.storefront_outlined,
          badge: 'Business only',
          onTap: () => _openAudience(GuideAudience.business),
        ),
        _audienceCard(
          title: 'Customer guide',
          blurb:
              'Browse links, order or book, track orders, earn stamps, and use coupons',
          icon: Icons.person_outline_rounded,
          badge: 'Everyone',
          onTap: () => _openAudience(GuideAudience.customer),
        ),
      ],
    );
  }

  Widget _audienceCard({
    required String title,
    required String blurb,
    required IconData icon,
    required String badge,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 16, 12, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: BwUi.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: BwUi.iconTileBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.black, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: BwUi.pageBg,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: BwUi.cardBorder),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        blurb,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: AuthUi.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.black45,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopicHub() {
    final topics = _visibleTopics;
    final isCustomer = _isCustomerAudience;
    final typeHint =
        !isCustomer && _type != null ? ' · $_typeLabel' : '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          isCustomer
              ? 'Customer guide$typeHint'
              : 'Business guide$typeHint',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.15,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isCustomer
              ? 'How shopping on Barqody works for you — open one topic at a time.'
              : 'How to run your website — open one topic at a time. Each page explains what it is, then how to do it.',
          style: const TextStyle(
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w500,
            color: AuthUi.textSecondary,
          ),
        ),
        const SizedBox(height: 22),
        ...topics.map((topic) {
          final disabled = !isCustomer &&
              topic.commerceOnly &&
              _type == 'portfolio';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Opacity(
              opacity: disabled ? 0.45 : 1,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: disabled ? null : () => _openTopic(topic),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 16, 12, 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: BwUi.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: BwUi.iconTileBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            topic.icon,
                            color: Colors.black,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                topic.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                topic.blurb,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                  color: AuthUi.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTypePicker() {
    final topic = _activeTopic;
    final types = _kSiteTypes.where((s) {
      if (topic?.commerceOnly == true && s.id == 'portfolio') return false;
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const Text(
          'Which website is this about?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.15,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          topic == null
              ? 'Pick the type of site you run so the next steps use the right words.'
              : '“${topic.title}” works a bit differently per type. Pick yours so examples match what customers do.',
          style: const TextStyle(
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w500,
            color: AuthUi.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        ...types.map((site) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  setState(() {
                    _type = site.id;
                    _pickingTypeForTopic = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 16, 12, 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: BwUi.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: BwUi.iconTileBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(site.icon, color: Colors.black, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              site.label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              site.blurb,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                                color: AuthUi.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStepsView(double bottom) {
    final topic = _activeTopic;
    final steps = _topicSteps;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              Text(
                topic?.title ?? 'Guide',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.15,
                  color: Colors.black,
                ),
              ),
              if (!_isCustomerAudience && _type != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: BwUi.pageBg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: BwUi.cardBorder),
                    ),
                    child: Text(
                      _typeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
              if (topic != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F8),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: BwUi.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What this is',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        topic.explainer,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'How to do it',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Follow these steps in order. The chip under each step shows where to tap.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: AuthUi.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              ..._buildStepList(steps),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 12 + bottom),
          child: SizedBox(
            width: double.infinity,
            child: AuthPrimaryPillButton(
              label: 'Back to topics',
              onPressed: _onBack,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildStepList(List<_GuideStep> steps) {
    return List.generate(steps.length, (i) {
      final step = steps[i];
      final isLast = i == steps.length - 1;
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: const Color(0xFFE8E8ED),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: BwUi.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        step.body,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                          color: AuthUi.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: BwUi.pageBg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: BwUi.cardBorder),
                        ),
                        child: Text(
                          step.where,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
