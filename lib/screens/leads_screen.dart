import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/lead.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/providers/theme_provider.dart';
import 'package:tapni_app/screens/find_user_screen.dart';
import 'package:tapni_app/screens/scan_screen.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/screens/invitations/invitations_home_screen.dart';
import 'package:tapni_app/screens/contacts_search_screen.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/utils/whatsapp_ui.dart';
import 'package:tapni_app/widgets/custom_button.dart';
import 'package:tapni_app/widgets/filter_contacts_sheet.dart';
import 'package:tapni_app/widgets/wa_chats_widgets.dart';

import 'package:tapni_app/l10n/app_localizations_fallback.dart';
class LeadsScreen extends StatefulWidget {
  const LeadsScreen({Key? key}) : super(key: key);

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LeadsProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _refreshContacts() {
    final provider = context.read<LeadsProvider>();
    return Future.wait([
      provider.fetchLeads(),
      provider.fetchCategories(),
    ]);
  }

  void _dismissKeyboard() {
    _searchFocus.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _openScan() async {
    _dismissKeyboard();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ScanScreen()),
    );
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _dismissKeyboard();
    });
  }

  void _openFindUser() {
    _dismissKeyboard();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FindUserScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leadsProvider = Provider.of<LeadsProvider>(context);
    final leadsList = leadsProvider.leads;
    final isFiltering = leadsProvider.activeCategoryId != null;

    return Scaffold(
      backgroundColor: WaUi.toolsScaffold,
      floatingActionButton: Padding(
       padding: const EdgeInsets.only(
    bottom: 88,
    right: 20,
  ),
        child: WaContactSpeedDial(
          onAdd: () => _showAddLeadSheet(context, leadsProvider),
          onFind: _openFindUser,
        ),
      ),
      body: GestureDetector(
        onTap: _dismissKeyboard,
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: Padding(
             padding: const EdgeInsets.only(bottom: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WaChatsHeader(
                  title: context.l10n.contacts,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.photo_camera_outlined, size: 24),
                      color: WaUi.primaryText,
                      tooltip: context.l10n.scan,
                      onPressed: _openScan,
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
                          value: 'invitations',
                          child: Text(context.l10n.invitations, style: WaUi.body),
                        ),
                        PopupMenuItem(
                          value: 'find',
                          child:
                              Text(context.l10n.findUsername, style: WaUi.body),
                        ),
                        PopupMenuItem(
                          value: 'filter',
                          child: Text(context.l10n.filterContacts,
                              style: WaUi.body),
                        ),
                        PopupMenuItem(
                          value: 'categories',
                          child: Text(context.l10n.manageCategories,
                              style: WaUi.body),
                        ),
                      ],
                    ),
                  ],
                ),
                Expanded(
                  child: leadsProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          color: WaUi.accent,
                          onRefresh: _refreshContacts,
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: WaChatSearchBar(
                                  controller: _searchController,
                                  focusNode: _searchFocus,
                                  hintText: context.l10n.searchEllipsis,
                                  readOnly: true,
                                  onTap: () {
                                    _dismissKeyboard();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ContactsSearchScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: WaContactFilterChips(
                                  key: ValueKey(
                                    leadsProvider.categories
                                        .map((c) => c.id)
                                        .join(','),
                                  ),
                                  categories: List.of(leadsProvider.categories),
                                  activeCategoryId:
                                      leadsProvider.activeCategoryId,
                                  onAllTap: () =>
                                      leadsProvider.setActiveCategory(null),
                                  onCategoryTap: (id) =>
                                      leadsProvider.setActiveCategory(id),
                                  onAddCategory: () => _showAddCategoryDialog(
                                    context,
                                    leadsProvider,
                                  ),
                                ),
                              ),
                              if (leadsList.isEmpty)
                                SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: WaContactEmptyState(
                                    isSearching: isFiltering,
                                    onScan: _openScan,
                                    onAdd: () => _showAddLeadSheet(
                                      context,
                                      leadsProvider,
                                    ),
                                  ),
                                )
                              else
                                SliverPadding(
                                  padding: const EdgeInsets.only(bottom: 120),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        return _buildContactRow(
                                          context,
                                          leadsList[index],
                                          leadsProvider,
                                        );
                                      },
                                      childCount: leadsList.length,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onMenuAction(
    BuildContext context,
    String value,
    LeadsProvider provider,
  ) {
    switch (value) {
      case 'invitations':
        _dismissKeyboard();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const InvitationsHomeScreen(),
          ),
        );
        break;
      case 'find':
        _openFindUser();
        break;
      case 'filter':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => FilterContactsSheet(),
        );
        break;
      case 'categories':
        _showCategoriesSheet(context, provider);
        break;
    }
  }

  void _showCategoriesSheet(BuildContext context, LeadsProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: WaUi.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(WaUi.radiusLg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                SizedBox(height: 16),
                Text(ctx.l10n.categories, style: WaUi.sectionHeader),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _categoryChip(
                      context: ctx,
                      provider: provider,
                      label: ctx.l10n.all,
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
                              title: Text(context.l10n.deleteCategory, style: WaUi.title),
                              content: Text(
                                context.l10n.deleteCategoryNamed(category.name),
                                style: WaUi.body,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogCtx),
                                  child: Text(context.l10n.cancel, style: WaUi.bodyMedium),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(dialogCtx);
                                    provider.deleteCategory(category.id);
                                  },
                                  child: Text(
                                    context.l10n.delete,
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
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(
                color: isDark
                    ? AppTheme.greyBorderDark
                    : AppTheme.greyBorderLight,
              ),
            ),
            padding: EdgeInsets.all(24.0),
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
                    SizedBox(height: 20),
                    Text(ctx.l10n.captureNewContact,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(ctx.l10n.enterNetworkingContactDetailsBelow,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    SizedBox(height: 24),

                    _buildFieldLabel(ctx.l10n.fullName),
                    TextFormField(
                      controller: nameController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      decoration: WaUi.fieldDecoration(
                        prefixIcon: Icon(Icons.person_outline),
                        hintText: ctx.l10n.janeDoe,
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? ctx.l10n.nameIsRequired : null,
                    ),
                    SizedBox(height: 16),

                    _buildFieldLabel(ctx.l10n.emailAddress),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: WaUi.fieldDecoration(
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: ctx.l10n.janeCompanyCom,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return context.l10n.emailIsRequired;
                        if (!v.contains('@')) return context.l10n.enterAValidEmail;
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    _buildFieldLabel(context.l10n.phoneNumber),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: WaUi.fieldDecoration(
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: '+1 (555) 123-4567',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? context.l10n.phoneIsRequired : null,
                    ),
                    SizedBox(height: 16),

                    _buildFieldLabel(context.l10n.company),
                    TextFormField(
                      controller: companyController,
                      decoration: WaUi.fieldDecoration(
                        prefixIcon: Icon(Icons.business_outlined),
                        hintText: context.l10n.companyInc,
                      ),
                    ),
                    SizedBox(height: 16),

                    _buildFieldLabel(context.l10n.jobTitle),
                    TextFormField(
                      controller: jobTitleController,
                      decoration: WaUi.fieldDecoration(
                        prefixIcon: Icon(Icons.work_outline),
                        hintText: context.l10n.softwareEngineer,
                      ),
                    ),
                    SizedBox(height: 16),

                    _buildFieldLabel(context.l10n.website),
                    TextFormField(
                      controller: websiteController,
                      keyboardType: TextInputType.url,
                      decoration: WaUi.fieldDecoration(
                        prefixIcon: Icon(Icons.language_outlined),
                        hintText: context.l10n.httpsExampleHint,
                      ),
                    ),
                    SizedBox(height: 16),

                    _buildFieldLabel(context.l10n.address),
                    TextFormField(
                      controller: addressController,
                      decoration: WaUi.fieldDecoration(
                        prefixIcon: Icon(Icons.location_on_outlined),
                        hintText: context.l10n.n123MainStCity,
                      ),
                    ),
                    SizedBox(height: 16),

                    _buildFieldLabel(context.l10n.note),
                    TextFormField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: WaUi.fieldDecoration(
                        prefixIcon: Icon(Icons.note_alt_outlined),
                        hintText: context.l10n.addANote,
                      ).copyWith(alignLabelWithHint: true),
                    ),
                    SizedBox(height: 28),

                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: context.l10n.saveContact,
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
                                  SnackBar(
                                    content: Text(
                                      context.l10n.contactAddedSuccessfully,
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
                padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                      SizedBox(height: 20),

                      // Title row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(ctx.l10n.manageContact,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isEditing)
                            Container(
                              padding: EdgeInsets.symmetric(
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
                                  SizedBox(width: 4),
                                  Text(
                                    ctx.l10n.readOnly2,
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

                      SizedBox(height: 20),

                      // ── Fields ──
                      _buildManageField(
                        label: ctx.l10n.fullName,
                        controller: nameController,
                        icon: Icons.person_outline,
                        isEditing: isEditing,
                        isDark: isDark,
                      ),
                      SizedBox(height: 14),
                      _buildManageField(
                        label: ctx.l10n.email,
                        controller: emailController,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        isEditing: isEditing,
                        isDark: isDark,
                      ),
                      SizedBox(height: 14),
                      _buildManageField(
                        label: ctx.l10n.phone,
                        controller: phoneController,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        isEditing: isEditing,
                        isDark: isDark,
                      ),
                      SizedBox(height: 14),
                      _buildManageField(
                        label: ctx.l10n.company,
                        controller: companyController,
                        icon: Icons.business_outlined,
                        isEditing: isEditing,
                        isDark: isDark,
                      ),
                      SizedBox(height: 14),
                      _buildManageField(
                        label: ctx.l10n.jobTitle,
                        controller: jobTitleController,
                        icon: Icons.work_outline,
                        isEditing: isEditing,
                        isDark: isDark,
                      ),
                      SizedBox(height: 14),
                      _buildManageField(
                        label: ctx.l10n.website,
                        controller: websiteController,
                        icon: Icons.language_outlined,
                        keyboardType: TextInputType.url,
                        isEditing: isEditing,
                        isDark: isDark,
                      ),
                      SizedBox(height: 14),
                      _buildManageField(
                        label: ctx.l10n.address,
                        controller: addressController,
                        icon: Icons.location_on_outlined,
                        isEditing: isEditing,
                        isDark: isDark,
                      ),
                      SizedBox(height: 14),
                      _buildManageField(
                        label: ctx.l10n.note,
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
                                  child: Center(
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
                                          context.l10n.edit,
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
                            SizedBox(width: 12),
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
                                            SnackBar(
                                              content: Text(context.l10n.nameIsRequired),
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
                                              SnackBar(
                                                content: Text(
                                                  context.l10n.contactUpdatedSuccessfully,
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
                                              SnackBar(
                                                content: Text(
                                                  context.l10n.failedToUpdateContact,
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
                                        ? SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_rounded,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                context.l10n.save,
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
        TextField(
          controller: controller,
          readOnly: !isEditing,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          decoration: WaUi.fieldDecoration(
            prefixIcon: Icon(
              icon,
              size: 18,
              color: isEditing
                  ? (isDark ? Colors.white54 : Colors.black54)
                  : (isDark ? Colors.white24 : Colors.grey.shade400),
            ),
            hintText: isEditing ? context.l10n.enterField(label) : '',
            radius: 12,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 16),
              Text(
                context.l10n.optionsForName(lead.name),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.label_outline),
                title: Text(ctx.l10n.assignCategory),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAssignCategoryDialog(context, lead, provider);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text(context.l10n.deleteContact,
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteLead(context, lead, provider);
                },
              ),
              SizedBox(height: 16),
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
        title: Text(context.l10n.deleteContact),
        content: Text(context.l10n.removeFromContacts(lead.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              bool success = await provider.deleteLead(lead.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.contactRemoved(lead.name)),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(context.l10n.delete, style: TextStyle(color: Colors.red)),
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
          title: Text(ctx.l10n.assignCategory),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: provider.categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    title: Text(ctx.l10n.none),
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
              title: Text(ctx.l10n.newCategory),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: WaUi.fieldDecoration(
                      labelText: ctx.l10n.categoryName,
                    ),
                  ),
                  SizedBox(height: 16),
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
                              ? Icon(
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
                  child: Text(context.l10n.cancel),
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
                  child: Text(context.l10n.create),
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
      padding: EdgeInsets.only(left: 4.0, bottom: 6.0),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
    return lead.isScannedContact ? context.l10n.scannedViaQR : context.l10n.noDetailsYet;
  }

  Widget? _previewIcon(Lead lead) {
    if (lead.isScannedContact) {
      return const Icon(Icons.done_all, size: 16, color: WaUi.readCheck);
    }
    return null;
  }

  Widget _buildContactRow(
    BuildContext context,
    Lead lead,
    LeadsProvider provider,
  ) {
    final displayName = lead.displayName;
    final photoUrl = lead.displayProfilePhoto;

    return WaChatListTile(
      name: displayName,
      preview: _contactPreview(lead),
      date: waFormatContactDate(lead.timestamp, context),
      imageUrl: photoUrl,
      initial: displayName,
      avatarColor: waAvatarColorFor(displayName),
      categoryColor:
          lead.category != null ? _parseColor(lead.category!.color) : null,
      highlightDate: false,
      previewIcon: _previewIcon(lead),
      showDivider: false,
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
