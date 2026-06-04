import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/widgets/custom_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<ProfileProvider>(context, listen: false).profile;

    _nameController = TextEditingController(text: profile.name);
    _bioController = TextEditingController(text: profile.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final profile = profileProvider.profile;
    final response = await profileProvider.updateProfile(
      name: _nameController.text.trim(),
      designation: profile.designation,
      company: profile.company,
      bio: _bioController.text.trim(),
      phone: profile.phone,
      email: profile.email,
      website: profile.website,
      links: profile.socialLinks,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.success
              ? 'Profile updated successfully!'
              : response.message ?? 'Unable to save profile. Try again.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (response.success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profile = Provider.of<ProfileProvider>(context).profile;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Edit Profile'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: profile.coverPhotoUrl != null && profile.coverPhotoUrl!.isNotEmpty
                            ? Image.network(
                                profile.coverPhotoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
                              )
                            : Container(
                                color: Colors.grey.shade300,
                                child: const Center(
                                  child: Icon(
                                    Icons.photo_size_select_large_outlined,
                                    size: 54,
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _buildCircleIconButton(
                        icon: Icons.edit,
                        backgroundColor: Colors.white,
                        iconColor: Colors.black,
                      ),
                    ),
                    Positioned(
                      bottom: -44,
                      left: 20,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: const Color(0xFF1E2022),
                            backgroundImage: profile.profilePhotoUrl != null && profile.profilePhotoUrl!.isNotEmpty
                                ? NetworkImage(profile.profilePhotoUrl!) as ImageProvider
                                : null,
                            child: profile.profilePhotoUrl == null || profile.profilePhotoUrl!.isEmpty
                                ? Text(
                                    profile.name.isNotEmpty
                                        ? profile.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: -4,
                            child: _buildCircleIconButton(
                              icon: Icons.edit,
                              backgroundColor: Colors.black,
                              iconColor: Colors.white,
                              size: 34,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 62),
                Text(
                  'Edit your profile details',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Only cover, profile photo, name and bio are editable here.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Icon(Icons.edit_outlined),
                    ),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter your bio' : null,
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Save Profile',
                  onTap: _saveProfile,
                  isGold: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    double size = 38,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 18, color: iconColor),
    );
  }

  Widget _buildLinkButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
  }) {
    return Container(
      width: 120,
      height: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: Colors.white),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
