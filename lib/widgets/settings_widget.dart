import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapni_app/helper/text_helper.dart';
import 'package:tapni_app/providers/profile_provider.dart';
import 'package:tapni_app/utils/constant.dart';
import 'package:tapni_app/utils/theme.dart';

class SettingWidgets {
  static void showSettingSheet(BuildContext context) {
    _showTapniAccountBottomSheet(context);
  }
}

void _generalBottomSheet(BuildContext context) {
  final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
  final profile = profileProvider.profile;
  TextEditingController nameController = TextEditingController(
    text: profile.name,
  );
  String? selectedRegion = profile.country;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Drag Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Center(
                          child: Image.asset(
                            'assets/images/jpg/barqody_name.jpg',
                            height: 60,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                const Text(
                  "General",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 8),
                const Text(
                  "Manage your personal details & other preferences",
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Personal Details",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Name Field
                        // _buildTextField("Saim Y"),
                        TextFormField(
                          controller: nameController,
                          keyboardType: TextInputType.name,

                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            hintText: 'Name',
                            fillColor: Colors.grey[100],
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        // Email Field
                        _buildTextField(profile.email),

                        const SizedBox(height: 30),

                        // Region
                        const Text(
                          "Region",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDropdown(
                          value: selectedRegion,
                          items: Constants.countries,
                          onChanged: (val) {
                            setState(() => selectedRegion = val);
                          },
                        ),

                        // const SizedBox(height: 24),

                        // // Language
                        // const Text(
                        //   "Language",
                        //   style: TextStyle(
                        //     fontSize: 16,
                        //     fontWeight: FontWeight.w600,
                        //   ),
                        // ),
                        // const SizedBox(height: 12),
                        // _buildDropdown(
                        //   value: selectedLanguage,
                        //   items: ["English", "Urdu", "Arabic", "Spanish"],
                        //   onChanged: (val) {
                        //     setState(() => selectedLanguage = val!);
                        //   },
                        // ),

                        // const SizedBox(height: 8),
                        // const Text(
                        //   "Translate the app on your preferred language.",
                        //   style: TextStyle(color: Colors.grey, fontSize: 14),
                        // ),
                        const SizedBox(height: 40),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () async {
                                final profileProvider =
                                    Provider.of<ProfileProvider>(
                                      context,
                                      listen: false,
                                    );

                                final response = await profileProvider
                                    .updateProfile(
                                      name: nameController.text.trim(),
                                      designation: profile.designation,
                                      company: profile.company,
                                      bio: profile.bio,
                                      phone: profile.phone,
                                      email: profile.email,
                                      website: profile.website,
                                      links: profile.socialLinks,
                                      country: selectedRegion,
                                      context: context,
                                    );
                                if (response.success) {
                                  profileProvider.setEditingProfile(false);
                                  profileProvider.onSaveTriggered = null;
                                }
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      response.success
                                          ? 'Profile updated successfully!'
                                          : response.message ??
                                                'Unable to save profile. Try again.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: const Text(
                                "SAVE",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Save Button
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _buildTextField(String text) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Text(text, style: const TextStyle(fontSize: 16)),
        SizedBox(width: 8),
        Text(
          "(Read only)",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

Widget _buildDropdown({
  required String? value,
  required List<String> items,
  required void Function(String?)? onChanged,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        hint: const Text("Select Region"),
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down),
        items: items.map((String item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item.capitalizeFirst()),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    ),
  );
}

void _showTapniAccountBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.60,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 20),

            // Logo
            // const Text(
            //   "tapni",
            //   style: TextStyle(
            //     fontSize: 28,
            //     fontWeight: FontWeight.bold,
            //     letterSpacing: -1,
            //   ),
            // ),
            Image.asset('assets/images/jpg/barqody_name.jpg', height: 60),

            const SizedBox(height: 8),

            const Text(
              "Welcome to Account Center",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 4),

            const Text(
              "saimyousuf.y@gmail.com",
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),

            const SizedBox(height: 30),

            // Menu Items
            _buildMenuItem(Icons.person_outline, "General", () {
              Navigator.pop(context);
              _generalBottomSheet(context);
            }),
            _buildMenuItem(Icons.security, "Security", () {}),
            _buildMenuItem(Icons.credit_card, "Billing", () {}),

            const Spacer(),

            // Version
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                "Version: 1.0.1",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildMenuItem(IconData icon, String title, void Function()? onTap) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 4),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.secondaryWhite,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.black87),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    ),
  );
}
