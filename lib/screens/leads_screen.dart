import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/lead.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/providers/theme_provider.dart';
import 'package:tapni_app/screens/scan_screen.dart';
import 'package:tapni_app/screens/scanned_profile_screen.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/widgets/custom_app_button.dart';
import 'package:tapni_app/widgets/custom_button.dart';
import 'package:tapni_app/widgets/filter_contacts_sheet.dart';
import 'package:tapni_app/widgets/go_bussiness_button.dart';
import 'package:tapni_app/widgets/notification_icon_button.dart';
import 'package:tapni_app/widgets/pro_upgrade_sheet.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({Key? key}) : super(key: key);

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Main Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final leadsProvider = Provider.of<LeadsProvider>(context);
    final leadsList = leadsProvider.leads;
    final profileProvider = Provider.of<ProfileProvider>(context);
    final profile = profileProvider.profile;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.cardDarkBg : Colors.white,

      // ── AppBar ──
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.cardDarkBg : Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Text(
              'Contacts',
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(width: 6),
            Icon(Icons.refresh_rounded, color: Colors.black38),
          ],
        ),
        actions: const [
          NotificationIconButton(),
          GoBussinessButton(),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            // ── Search + Action Icons ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  // Search bar
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.07)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextFormField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {});
                          leadsProvider.setSearchQuery(val);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: TextStyle(
                            fontSize: 18,
                            color: isDark
                                ? Colors.white38
                                : Colors.grey.shade500,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: isDark
                                ? Colors.white38
                                : Colors.grey.shade500,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setState(() => _searchController.clear());
                                    leadsProvider.setSearchQuery('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Filter icon
                  _topIconBtn(
                    icon: Icons.tune_rounded,
                    isDark: isDark,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => const FilterContactsSheet(),
                      );
                    },
                  ),
                  const SizedBox(width: 6),

                  // Contacts import icon
                  _topIconBtn(
                    icon: Icons.contact_page_outlined,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),

                  // Add contact icon
                  _topIconBtn(
                    icon: Icons.person_add_alt_1_outlined,
                    isDark: isDark,
                    onTap: () => _showAddLeadSheet(context, leadsProvider),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Filter chips row ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => leadsProvider.setActiveCategory(null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: leadsProvider.activeCategoryId == null
                            ? (isDark ? Colors.white : Colors.black)
                            : (isDark ? Colors.white12 : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'All',
                        style: TextStyle(
                          color: leadsProvider.activeCategoryId == null
                              ? (isDark ? Colors.black : Colors.white)
                              : (isDark ? Colors.white : Colors.black),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: leadsProvider.categories.length,
                        itemBuilder: (context, index) {
                          final category = leadsProvider.categories[index];
                          final isActive =
                              leadsProvider.activeCategoryId == category.id;
                          return GestureDetector(
                            onTap: () =>
                                leadsProvider.setActiveCategory(category.id),
                            onLongPress: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Category'),
                                  content: Text('Delete "${category.name}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        leadsProvider.deleteCategory(
                                          category.id,
                                        );
                                      },
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? (isDark ? Colors.white : Colors.black)
                                    : (isDark
                                          ? Colors.white12
                                          : Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _parseColor(
                                    category.color,
                                  ).withOpacity(0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 4,
                                    backgroundColor: _parseColor(
                                      category.color,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    category.name,
                                    style: TextStyle(
                                      color: isActive
                                          ? (isDark
                                                ? Colors.black
                                                : Colors.white)
                                          : (isDark
                                                ? Colors.white
                                                : Colors.black),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Plus button
                  GestureDetector(
                    onTap: () => _showAddCategoryDialog(context, leadsProvider),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        size: 18,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Count label ──
            if (leadsList.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${leadsList.length} contact${leadsList.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 18,
                      color: isDark
                          ? AppTheme.textGreyDark
                          : AppTheme.textGreyLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            // ── Contact List ──
            Expanded(
              child: leadsProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : leadsList.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      itemCount: leadsList.length,
                      itemBuilder: (context, index) {
                        return _buildContactRow(
                          context,
                          leadsList[index],
                          isDark,
                          leadsProvider,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // ── Scan Button (replaces FAB) ──
      bottomNavigationBar: // Scan button
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 50),
        child: CustomAppButton(
          width: double.infinity,
          text: 'Scan',
          icon: Icons.camera_alt_outlined,
          backgroundColor: AppTheme.primaryBlack,
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ScanScreen()));
          },
        ),
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

  // ── Top Icon Button Helper ─────────────────────────────────────────────────
  Widget _topIconBtn({
    required IconData icon,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.07) : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off_outlined,
            size: 64,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 16),
          const Text(
            'No contacts found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            _searchController.text.isEmpty
                ? 'Scan or add connections you meet.'
                : 'Try searching for something else.',
            style: TextStyle(
              color: isDark ? AppTheme.textGreyDark : AppTheme.textGreyLight,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Contact Row (image-style: avatar + name/handle/date + chevron) ─────────
  Widget _buildContactRow(
    BuildContext context,
    Lead lead,
    bool isDark,
    LeadsProvider provider,
  ) {
    final displayName = lead.displayName;
    final displayEmail = lead.displayEmail;
    final displayPhone = lead.displayPhone;
    final photoUrl = lead.displayProfilePhoto;

    return GestureDetector(
      onLongPress: () => _showLeadOptions(context, lead, provider),
      onTap: () {
        if (lead.contactUser != null) {
          // Scanned contact → profile screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ScannedProfileScreen(user: lead.contactUser),
            ),
          );
        } else {
          // Manual contact → manage contact sheet
          _showManageContactSheet(context, lead, provider);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            // Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: photoUrl != null && photoUrl.isNotEmpty
                        ? Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                  ),
                ),
                // Category dot
                if (lead.category != null)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _parseColor(lead.category!.color),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppTheme.cardDarkBg : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                // Scanned badge
                if (lead.isScannedContact)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppTheme.cardDarkBg : Colors.white,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.qr_code,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Name / subtitle / date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayEmail.isNotEmpty
                        ? displayEmail
                        : (displayPhone.isNotEmpty
                              ? displayPhone
                              : 'No contact info'),
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(lead.timestamp),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),

            // More
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 30,
              // color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // ── Date Formatter ─────────────────────────────────────────────────────────
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }
}
