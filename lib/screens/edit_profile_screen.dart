import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/utils/theme.dart';
import 'package:tapni_app/widgets/custom_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _designationController;
  late TextEditingController _companyController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<ProfileProvider>(context, listen: false).profile;
    
    _nameController = TextEditingController(text: profile.name);
    _designationController = TextEditingController(text: profile.designation);
    _companyController = TextEditingController(text: profile.company);
    _bioController = TextEditingController(text: profile.bio);
    _phoneController = TextEditingController(text: profile.phone);
    _emailController = TextEditingController(text: profile.email);
    _websiteController = TextEditingController(text: profile.website);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _designationController.dispose();
    _companyController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      Provider.of<ProfileProvider>(context, listen: false).updateProfile(
        name: _nameController.text.trim(),
        designation: _designationController.text.trim(),
        company: _companyController.text.trim(),
        bio: _bioController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        website: _websiteController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Prompt
                Text(
                  'Profile Information',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'These details are visible to anyone who scans your card.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.textGreyDark : AppTheme.textGreyLight,
                  ),
                ),
                const SizedBox(height: 28),

                // Name
                _buildFieldLabel('Full Name'),
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: 'John Doe',
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Name cannot be empty' : null,
                ),
                const SizedBox(height: 20),

                // Designation
                _buildFieldLabel('Designation / Job Title'),
                TextFormField(
                  controller: _designationController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.badge_outlined),
                    hintText: 'Product Designer',
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Job title cannot be empty' : null,
                ),
                const SizedBox(height: 20),

                // Company
                _buildFieldLabel('Company Name'),
                TextFormField(
                  controller: _companyController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.business_outlined),
                    hintText: 'Company Inc.',
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Company name cannot be empty' : null,
                ),
                const SizedBox(height: 20),

                // Bio
                _buildFieldLabel('Bio / Tagline'),
                TextFormField(
                  controller: _bioController,
                  keyboardType: TextInputType.multiline,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 40.0),
                      child: Icon(Icons.description_outlined),
                    ),
                    hintText: 'Describe yourself or your company...',
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Bio cannot be empty' : null,
                ),
                const SizedBox(height: 20),

                // Phone
                _buildFieldLabel('Phone Number'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '+1 (555) 019-2834',
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Phone number cannot be empty' : null,
                ),
                const SizedBox(height: 20),

                // Email
                _buildFieldLabel('Email Address'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.email_outlined),
                    hintText: 'email@domain.com',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Email cannot be empty';
                    if (!value.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Website
                _buildFieldLabel('Website URL'),
                TextFormField(
                  controller: _websiteController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.language_outlined),
                    hintText: 'www.website.com',
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Website cannot be empty' : null,
                ),
                const SizedBox(height: 36),

                // Save Button
                CustomButton(
                  text: 'Save Changes',
                  onTap: _saveProfile,
                  isGold: true,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
