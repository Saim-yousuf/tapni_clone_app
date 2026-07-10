import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/lead.dart';
import 'package:tapni_app/models/contact_category.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/providers/theme_provider.dart';
import 'package:tapni_app/screens/find_user_screen.dart';
import 'package:tapni_app/screens/scan_screen.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/custom_button.dart';
import 'package:tapni_app/widgets/filter_contacts_sheet.dart';
import 'package:tapni_app/widgets/wa_chats_widgets.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({Key? key}) : super(key: key);

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    _searchFocus.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _openScan() async {
    _dismissKeyboard();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _dismissKeyboard();
    });
  }

  void _openFindUser() {
    _dismissKeyboard();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FindUserScreen()),
    );
  }

  String _contactsSubtitle(int count, LeadsProvider provider) {
    if (count == 0) return 'Start building your network';
    final parts = <String>['$count contact${count == 1 ? '' : 's'}'];
    if (provider.activeCategoryId != null) {
      parts.add(_activeCategoryLabel(provider));
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final leadsProvider = Provider.of<LeadsProvider>(context);
    final leadsList = leadsProvider.leads;
    final isFiltering = _searchController.text.isNotEmpty ||
        leadsProvider.activeCategoryId != null;

    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 4),
        child: WaContactSpeedDial(
          onScan: _openScan,
          onAdd: () => _showAddLeadSheet(context, leadsProvider),
          onFind: _openFindUser,
        ),
      ),
      body: GestureDetector(
        onTap: _dismissKeyboard,
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WaChatsHeader(
              title: 'Contacts',
              subtitle: _contactsSubtitle(leadsList.length, leadsProvider),
              actions: [
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 24),
                  color: WaUi.primaryText,
                  tooltip: 'Scan',
                  onPressed: _openScan,
                ),
                IconButton(
                  icon: const Icon(Icons.person_search_outlined, size: 24),
                  color: WaUi.primaryText,
                  tooltip: 'Find username',
                  onPressed: _openFindUser,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    size: 24,
                    color: WaUi.primaryText,
                  ),
                  color: WaUi.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(WaUi.radiusMd),
                  ),
                  onSelected: (value) =>
                      _onMenuAction(context, value, leadsProvider),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'filter',
                      child: Text('Filter contacts', style: WaUi.body),
                    ),
                    PopupMenuItem(
                      value: 'categories',
                      child: Text('Manage categories', style: WaUi.body),
                    ),
                    PopupMenuItem(
                      value: 'import',
                      child: Text('Import contacts', style: WaUi.body),
                    ),
                  ],
                ),
              ],
            ),
            WaChatSearchBar(
              controller: _searchController,
              focusNode: _searchFocus,
              onChanged: (val) {
                setState(() {});
                leadsProvider.setSearchQuery(val);
              },
              onClear: () {
                setState(() => _searchController.clear());
                leadsProvider.setSearchQuery('');
              },
            ),
            WaContactFilterChips(
              categories: leadsProvider.categories,
              activeCategoryId: leadsProvider.activeCategoryId,
              onAllTap: () => leadsProvider.setActiveCategory(null),
              onCategoryTap: (id) => leadsProvider.setActiveCategory(id),
              onAddCategory: () =>
                  _showAddCategoryDialog(context, leadsProvider),
            ),
            Expanded(
              child: leadsProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : leadsList.isEmpty
                  ? WaContactEmptyState(
                      isSearching: isFiltering,
                      onScan: _openScan,
                      onAdd: () =>
                          _showAddLeadSheet(context, leadsProvider),
                    )
                  : RefreshIndicator(
                      color: WaUi.accent,
                      onRefresh: leadsProvider.fetchLeads,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 120),
                        itemCount: leadsList.length,
                        itemBuilder: (context, index) {
                          return _buildContactRow(
                            context,
                            leadsList[index],
                            leadsProvider,
                            isLast: index == leadsList.length - 1,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  String _activeCategoryLabel(LeadsProvider provider) {
    final id = provider.activeCategoryId;
    if (id == null) return '';
    ContactCategory? category;
    for (final c in provider.categories) {
      if (c.id == id) {
        category = c;
        break;
      }
    }
    return category == null ? 'Filtered' : category.name;
  }

  void _onMenuAction(
    BuildContext context,
    String value,
    LeadsProvider provider,
  ) {
    switch (value) {
      case 'filter':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => const FilterContactsSheet(),
        );
        break;
      case 'categories':
        _showCategoriesSheet(context, provider);
        break;
      case 'import':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Import contacts is not available yet.',
              style: WaUi.body.copyWith(color: Colors.white),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: WaUi.primaryText,
          ),
        );
        break;
    }
  }

  void _showCategoriesSheet(BuildContext context, LeadsProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: WaUi.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(WaUi.radiusLg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: WaUi.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Categories', style: WaUi.sectionHeader),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _categoryChip(
                      context: ctx,
                      provider: provider,
                      label: 'All',
                      selected: provider.activeCategoryId == null,
                      color: WaUi.secondaryText,
                      onTap: () {
                        provider.setActiveCategory(null);
                        Navigator.pop(ctx);
                      },
                    ),
                    ...provider.categories.map(
                      (category) => _categoryChip(
                        context: ctx,
                        provider: provider,
                        label: category.name,
                        selected: provider.activeCategoryId == category.id,
                        color: _parseColor(category.color),
                        onTap: () {
                          provider.setActiveCategory(category.id);
                          Navigator.pop(ctx);
                        },
                        onLongPress: () {
                          Navigator.pop(ctx);
                          showDialog(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              title: Text('Delete Category', style: WaUi.title),
                              content: Text(
                                'Delete "${category.name}"?',
                                style: WaUi.body,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogCtx),
                                  child: Text('Cancel', style: WaUi.bodyMedium),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(dialogCtx);
                                    provider.deleteCategory(category.id);
                                  },
                                  child: Text(
                                    'Delete',
                                    style: WaUi.bodyMedium.copyWith(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    ActionChip(
                      label: const Icon(Icons.add, size: 18),
                      backgroundColor: WaUi.navPill,
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showAddCategoryDialog(context, provider);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _categoryChip({
    required BuildContext context,
    required LeadsProvider provider,
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: FilterChip(
        label: Text(label, style: WaUi.body),
        selected: selected,
        showCheckmark: false,
        backgroundColor: WaUi.navPill,
        selectedColor: WaUi.buttonDark,
        labelStyle: WaUi.body.copyWith(
          color: selected ? Colors.white : WaUi.primaryText,
        ),
        side: BorderSide(color: color.withValues(alpha: 0.45)),
        onSelected: (_) => onTap(),
      ),
    );
  }

  // ── Add Lead Bottom Sheet ──────────────────────────────────────────────────
  void _showAddLeadSheet(BuildContext context, LeadsProvider provider) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();  
    final companyController = TextEditingController();
    final jobTitleController = TextEditingController();
    final websiteController = TextEditingController();
    final noteController = TextEditingController();
    final addressController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Provider.of<ThemeProvider>(
          context,
          listen: false,
        ).isDarkMode;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDarkBg : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(
                color: isDark
                    ? AppTheme.greyBorderDark
                    : AppTheme.greyBorderLight,
              ),
            ),
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Capture New Contact',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enter networking contact details below.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    _buildFieldLabel('Full Name'),
                    TextFormField(
                      controller: nameController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline),
                        hintText: 'Jane Doe',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    _buildFieldLabel('Email Address'),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: 'jane@company.com',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildFieldLabel('Phone Number'),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: '+1 (555) 123-4567',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Phone is required' : null,
                    ),
                    const SizedBox(height: 16),

                    _buildFieldLabel('Company'),
                    TextFormField(
                      controller: companyController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.business_outlined),
                        hintText: 'Company Inc.',
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildFieldLabel('Job Title'),
                    TextFormField(
                      controller: jobTitleController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.work_outline),
                        hintText: 'Software Engineer',
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildFieldLabel('Website'),
                    TextFormField(
                      controller: websiteController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.language_outlined),
                        hintText: 'https://example.com',
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildFieldLabel('Address'),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.location_on_outlined),
                        hintText: '123 Main St, City',
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildFieldLabel('Note'),
                    TextFormField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.note_alt_outlined),
                        hintText: 'Add a note...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 28),

                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Save Contact',
                            onTap: () {
                              if (formKey.currentState!.validate()) {
                                provider.addLead(
                                  name: nameController.text.trim(),
                                  email: emailController.text.trim(),
                                  phone: phoneController.text.trim(),
                                  company: companyController.text.trim(),
                                  jobTitle: jobTitleController.text.trim(),
                                  website: websiteController.text.trim(),
                                  note: noteController.text.trim(),
                                  address: addressController.text.trim(),
                                );
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Contact added successfully!',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            isGold: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Manage Contact Sheet (readonly → edit → save) ────────────────────────
  void _showManageContactSheet(
    BuildContext context,
    Lead lead,
    LeadsProvider provider,
  ) {
    final nameController = TextEditingController(text: lead.name);
    final emailController = TextEditingController(text: lead.email);
    final phoneController = TextEditingController(text: lead.phone);
    final companyController = TextEditingController(text: lead.company);
    final jobTitleController = TextEditingController(text: lead.jobTitle);
    final websiteController = TextEditingController(text: lead.website);
    final addressController = TextEditingController(text: lead.address);
    final noteController = TextEditingController(text: lead.note);
    bool isEditing = false;
    bool isSaving = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Provider.of<ThemeProvider>(
          context,
          listen: false,
        ).isDarkMode;
        // Local state inside sheet

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDarkBg : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border.all(
                    color: isDark
                        ? AppTheme.greyBorderDark
                        : AppTheme.greyBorderLight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Manage contact',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isEditing)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    size: 12,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Read only',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      // Categories chips
                      if (lead.category != null) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _parseColor(
                                  lead.category!.color,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _parseColor(
                                    lead.category!.color,
                                  ).withOpacity(0.4),
                                ),
                              ),
                              child: Text(
                                lead.category!.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _parseColor(lead.category!.color),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ── Fields ──
                      _buildManageField(
                        label: 'Full Name',
                        controller: nameController,
                        icon: Icons.person_outline,
                        isEditing: isEditing,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      _buildManageField(
                        label: 'Email',
                        controller: emailController,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        isEditing: isEditing,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      _buildManageField(
                        label: 'Phone',
                        controller: phoneController,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        isEditing: isEditing,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      _buildManageField(
                        label: 'Company',
                        controller: companyController,
                        icon: Icons.business_outlined,
                        isEditing: isEditing,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      _buildManageField(
                        label: 'Job Title',
                        controller: jobTitleController,
                        icon: Icons.work_outline,
                        isEditing: isEditing,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      _buildManageField(
                        label: 'Website',
                        controller: websiteController,
                        icon: Icons.language_outlined,
                        keyboardType: TextInputType.url,
                        isEditing: isEditing,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      _buildManageField(
                        label: 'Address',
                        controller: addressController,
                        icon: Icons.location_on_outlined,
                        isEditing: isEditing,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      _buildManageField(
                        label: 'Note',
                        controller: noteController,
                        icon: Icons.note_alt_outlined,
                        maxLines: 3,
                        isEditing: isEditing,
                        isDark: isDark,
                      ),

                      const SizedBox(height: 28),

                      // ── Bottom Buttons ──
                      if (!isEditing)
                        // Edit button
                        Row(
                          children: [
                            // Close
                            GestureDetector(
                              onTap: () => Navigator.of(ctx).pop(),
                              child: Container(
                                width: 48,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Edit
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setSheetState(() => isEditing = true);
                                },
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.edit_outlined,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Edit',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        // Save + Cancel buttons
                        Row(
                          children: [
                            // Cancel edit
                            GestureDetector(
                              onTap: () {
                                // Reset controllers to original values
                                nameController.text = lead.name;
                                emailController.text = lead.email;
                                phoneController.text = lead.phone;
                                companyController.text = lead.company;
                                jobTitleController.text = lead.jobTitle;
                                websiteController.text = lead.website;
                                addressController.text = lead.address;
                                noteController.text = lead.note;
                                setSheetState(() => isEditing = false);
                              },
                              child: Container(
                                width: 48,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Save
                            Expanded(
                              child: GestureDetector(
                                onTap: isSaving
                                    ? null
                                    : () async {
                                        if (nameController.text
                                            .trim()
                                            .isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Name is required'),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                          return;
                                        }
                                        setSheetState(() => isSaving = true);
                                        final navCtx = ctx;
                                        final scaffoldCtx = context;
                                        final success = await provider
                                            .updateLead(lead.id, {
                                              'name': nameController.text
                                                  .trim(),
                                              'email': emailController.text
                                                  .trim(),
                                              'phone': phoneController.text
                                                  .trim(),
                                              'company': companyController.text
                                                  .trim(),
                                              'jobTitle': jobTitleController
                                                  .text
                                                  .trim(),
                                              'website': websiteController.text
                                                  .trim(),
                                              'address': addressController.text
                                                  .trim(),
                                              'note': noteController.text
                                                  .trim(),
                                            });
                                        setSheetState(() => isSaving = false);
                                        if (success) {
                                          if (navCtx.mounted) {
                                            Navigator.of(navCtx).pop();
                                          }
                                          if (scaffoldCtx.mounted) {
                                            ScaffoldMessenger.of(
                                              scaffoldCtx,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Contact updated successfully!',
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        } else {
                                          if (scaffoldCtx.mounted) {
                                            ScaffoldMessenger.of(
                                              scaffoldCtx,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Failed to update contact.',
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: isSaving
                                        ? Colors.black54
                                        : Colors.black,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: isSaving
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_rounded,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Save',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Manage Contact Field Helper ─────────────────────────────────────────────
  Widget _buildManageField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isEditing,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white38 : Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isEditing
                ? (isDark
                      ? Colors.white.withOpacity(0.07)
                      : Colors.grey.shade50)
                : (isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEditing
                  ? (isDark ? Colors.white24 : Colors.grey.shade300)
                  : Colors.transparent,
            ),
          ),
          child: TextField(
            controller: controller,
            readOnly: !isEditing,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                size: 18,
                color: isEditing
                    ? (isDark ? Colors.white54 : Colors.black54)
                    : (isDark ? Colors.white24 : Colors.grey.shade400),
              ),
              hintText: isEditing ? 'Enter $label' : '',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Lead Options (Assign Category / Delete) ──────────────────────────────
  void _showLeadOptions(
    BuildContext context,
    Lead lead,
    LeadsProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Options for ${lead.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.label_outline),
                title: const Text('Assign Category'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAssignCategoryDialog(context, lead, provider);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete Contact',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteLead(context, lead, provider);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteLead(
    BuildContext context,
    Lead lead,
    LeadsProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Remove "${lead.name}" from your contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              bool success = await provider.deleteLead(lead.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${lead.name} removed.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAssignCategoryDialog(
    BuildContext context,
    Lead lead,
    LeadsProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Assign Category'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: provider.categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    title: const Text('None'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await provider.updateLead(lead.id, {'category': ''});
                    },
                  );
                }
                final cat = provider.categories[index - 1];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _parseColor(cat.color),
                    radius: 12,
                  ),
                  title: Text(cat.name),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await provider.updateLead(lead.id, {'category': cat.id});
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context, LeadsProvider provider) {
    final nameCtrl = TextEditingController();
    String selectedColor = '#FF0000'; // Default red

    final colors = [
      '#FF0000',
      '#00FF00',
      '#0000FF',
      '#FFFF00',
      '#FF00FF',
      '#00FFFF',
      '#FFA500',
      '#800080',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: colors.map((colorStr) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedColor = colorStr;
                          });
                        },
                        child: CircleAvatar(
                          backgroundColor: _parseColor(colorStr),
                          radius: 16,
                          child: selectedColor == colorStr
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isNotEmpty) {
                      Navigator.pop(ctx);
                      await provider.createCategory(
                        nameCtrl.text.trim(),
                        selectedColor,
                      );
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _parseColor(String colorStr) {
    try {
      return Color(int.parse(colorStr.replaceAll('#', '0xff')));
    } catch (e) {
      return Colors.blue;
    }
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  String _contactPreview(Lead lead) {
    if (lead.note.trim().isNotEmpty) return lead.note.trim();
    final company = lead.displayCompany.trim();
    final job = lead.displayJobTitle.trim();
    if (job.isNotEmpty && company.isNotEmpty) return '$job · $company';
    if (company.isNotEmpty) return company;
    if (lead.displayEmail.trim().isNotEmpty) return lead.displayEmail.trim();
    if (lead.displayPhone.trim().isNotEmpty) return lead.displayPhone.trim();
    return lead.isScannedContact ? 'Scanned via QR' : 'No details yet';
  }

  bool _isRecentContact(Lead lead) {
    return DateTime.now().difference(lead.timestamp).inDays < 7;
  }

  Widget? _previewIcon(Lead lead) {
    if (lead.isScannedContact) {
      return const Icon(Icons.done_all, size: 16, color: Color(0xFF53BDEB));
    }
    return null;
  }

  Widget _buildContactRow(
    BuildContext context,
    Lead lead,
    LeadsProvider provider, {
    bool isLast = false,
  }) {
    final displayName = lead.displayName;
    final photoUrl = lead.displayProfilePhoto;

    return WaChatListTile(
      name: displayName,
      preview: _contactPreview(lead),
      date: waFormatContactDate(lead.timestamp),
      imageUrl: photoUrl,
      initial: displayName,
      avatarColor: waAvatarColorFor(displayName),
      categoryColor:
          lead.category != null ? _parseColor(lead.category!.color) : null,
      highlightDate: _isRecentContact(lead),
      previewIcon: _previewIcon(lead),
      showDivider: !isLast,
      onTap: () {
        if (lead.contactUser != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ScannedProfileScreen(user: lead.contactUser),
            ),
          );
        } else {
          _showManageContactSheet(context, lead, provider);
        }
      },
      onLongPress: () => _showLeadOptions(context, lead, provider),
    );
  }
}
