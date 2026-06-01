import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/models/lead.dart';
import 'package:tapni_app/providers/leads_provider.dart';
import 'package:tapni_app/providers/theme_provider.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/widgets/glass_card.dart';
import 'package:tapni_app/widgets/custom_button.dart';

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

  void _showAddLeadSheet(BuildContext context, LeadsProvider provider) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final companyController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDarkBg : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: isDark ? AppTheme.greyBorderDark : AppTheme.greyBorderLight,
                width: 1,
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
                    // Handle Bar
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
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enter networking contact details below.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    // Name
                    _buildFieldLabel('Full Name'),
                    TextFormField(
                      controller: nameController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline),
                        hintText: 'Jane Doe',
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Email
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

                    // Phone
                    _buildFieldLabel('Phone Number'),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: '+1 (555) 123-4567',
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Phone is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Company
                    _buildFieldLabel('Company'),
                    TextFormField(
                      controller: companyController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.business_outlined),
                        hintText: 'Company Inc.',
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Company is required' : null,
                    ),
                    const SizedBox(height: 28),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Save Lead',
                            onTap: () {
                              if (formKey.currentState!.validate()) {
                                provider.addLead(
                                  name: nameController.text.trim(),
                                  email: emailController.text.trim(),
                                  phone: phoneController.text.trim(),
                                  company: companyController.text.trim(),
                                );
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Lead added successfully!'),
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

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final leadsProvider = Provider.of<LeadsProvider>(context);
    final leadsList = leadsProvider.leads;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Captured Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt),
            onPressed: () => _showAddLeadSheet(context, leadsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLeadSheet(context, leadsProvider),
        backgroundColor: Colors.transparent,
        elevation: 0,
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: AppTheme.goldGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentGold.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: const [
              Icon(Icons.add, color: AppTheme.secondaryWhite),
              SizedBox(width: 8),
              Text(
                'Add Contact',
                style: TextStyle(
                  color: AppTheme.secondaryWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: TextFormField(
                controller: _searchController,
                onChanged: (val) => leadsProvider.setSearchQuery(val),
                decoration: InputDecoration(
                  hintText: 'Search contacts by name, company, email...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            leadsProvider.setSearchQuery('');
                          },
                        )
                      : null,
                  fillColor: isDark 
                      ? Colors.white.withOpacity(0.04) 
                      : Colors.black.withOpacity(0.02),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? AppTheme.greyBorderDark : AppTheme.greyBorderLight,
                    ),
                  ),
                ),
              ),
            ),

            // Leads List
            Expanded(
              child: leadsList.isEmpty
                  ? Center(
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchController.text.isEmpty
                                ? 'Add connections you meet at conferences.'
                                : 'Try searching for something else.',
                            style: TextStyle(
                              color: isDark ? AppTheme.textGreyDark : AppTheme.textGreyLight,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 80),
                      itemCount: leadsList.length,
                      itemBuilder: (context, index) {
                        final lead = leadsList[index];
                        return _buildLeadCard(context, lead, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadCard(BuildContext context, Lead lead, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Lead Avatar Initials
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Center(
                child: Text(
                  lead.name.isNotEmpty ? lead.name[0].toUpperCase() : 'L',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Lead info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    lead.company,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppTheme.textGreyDark : AppTheme.textGreyLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  // Contact details details
                  Row(
                    children: [
                      Icon(Icons.email_outlined, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          lead.email,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        lead.phone,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Call / Email Quick Buttons
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.phone_rounded, color: Colors.green, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Dialing ${lead.name}: ${lead.phone}'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.mail_rounded, color: AppTheme.accentGold, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Composing email to ${lead.email}'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
