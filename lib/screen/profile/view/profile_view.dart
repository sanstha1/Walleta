import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:walleta/config/api_config.dart';
import 'package:walleta/screen/authentication/login_page.dart';
import 'package:walleta/screen/chart/viewmodel/get_transaction_viewmodel.dart';
import 'package:walleta/screen/profile/budget/view/budget_management_screen.dart';
import 'package:walleta/screen/profile/view/notification_view.dart';
import 'package:walleta/screen/profile/viewmodel/notification_viewmodel.dart';
import 'dart:convert';

import 'package:walleta/screen/profile/viewmodel/profile_viewmodel.dart';
import 'package:walleta/screen/report/export_screen.dart';
import 'package:walleta/services/currency_service.dart';
import 'package:walleta/services/token_service.dart';
import 'package:walleta/services/transaction_service.dart';
import 'package:walleta/theme/app_colors.dart';
import 'package:walleta/theme/app_theme_manager.dart';

const Color _accentTeal = Color(0xFF006A60);
const Color _expenseDeep = Color(0xFFBA1A1A);

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // ignore: use_build_context_synchronously
    Future.microtask(() => context.read<ProfileViewModel>().loadUserData());
  }

  Future<bool> _requestPermission(Permission permission) async {
    final status = await permission.status;
    if (status.isGranted) return true;
    if (status.isDenied) {
      final result = await permission.request();
      return result.isGranted;
    }
    if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog();
      return false;
    }
    return false;
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.read<AppThemeManager>().colors.backgroundColor,
        title: Text(
          "Permission Required",
          style: TextStyle(
            fontFamily: 'monospace',
            color: context.read<AppThemeManager>().colors.primaryText,
          ),
        ),
        content: Text(
          "This feature requires permission to access your camera or gallery. Please enable it in your device settings.",
          style: TextStyle(
            fontFamily: 'monospace',
            color: context.read<AppThemeManager>().colors.disabledText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadProfilePicture(File imageFile) async {
    setState(() => _isUploading = true);
    try {
      final token = await TokenService.getToken();
      if (token == null) return;

      final uri = Uri.parse(ApiConfig.uploadProfilePicture);
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(
          await http.MultipartFile.fromPath('profileImage', imageFile.path),
        );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newImageUrl = data['data']['profileImage'] as String;
        context.read<ProfileViewModel>().updateProfileImage(newImageUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile picture updated!'),
            backgroundColor: _accentTeal,
          ),
        );
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err['message'] ?? 'Upload failed'),
            backgroundColor: _expenseDeep,
          ),
        );
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Please try again.'),
            backgroundColor: _expenseDeep,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickFromCamera() async {
    final hasPermission = await _requestPermission(Permission.camera);
    if (!hasPermission) return;
    final XFile? photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo != null) await _uploadProfilePicture(File(photo.path));
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) await _uploadProfilePicture(File(image.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to access gallery. Please try using the camera instead.',
            ),
            backgroundColor: _expenseDeep,
          ),
        );
      }
    }
  }

  void _showImagePickerSheet(AppColors colors, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.disabledText.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera, color: _accentTeal),
                title: Text(
                  'Open Camera',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: colors.primaryText,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.browse_gallery, color: _accentTeal),
                title: Text(
                  'Open Gallery',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: colors.primaryText,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _updateProfile({required String name}) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) return false;

      final uri = Uri.parse(ApiConfig.updateProfile);
      final response = await http.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': name}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          context.read<ProfileViewModel>().updateName(name);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile updated successfully!'),
              backgroundColor: _accentTeal,
            ),
          );
        }
        return true;
      } else {
        final err = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err['message'] ?? 'Update failed'),
              backgroundColor: _expenseDeep,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Please try again.'),
            backgroundColor: _expenseDeep,
          ),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final themeManager = context.watch<AppThemeManager>();
    final colors = themeManager.colors;
    final isDark = themeManager.isDark;

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      body: vm.isLoading
          ? Center(child: CircularProgressIndicator(color: _accentTeal))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 40),
              child: Column(
                children: [
                  _buildProfileHeader(vm, colors, isDark),
                  const SizedBox(height: 32),
                  _buildMenuSection(context, vm, colors, themeManager, isDark),
                  const SizedBox(height: 30),
                  _buildLogoutButton(context, vm, colors),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _avatar(String url, double size) {
    final hasImage = url.startsWith('http') || url.startsWith('https');
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _defaultAvatarIcon(size),
              )
            : _defaultAvatarIcon(size),
      ),
    );
  }

  Widget _defaultAvatarIcon(double size) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(height: size * 0.18),
        Container(
          width: size * 0.36,
          height: size * 0.36,
          decoration: const BoxDecoration(
            color: Color(0xFF16213E),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: size * 0.74,
          height: size * 0.42,
          decoration: BoxDecoration(
            color: const Color(0xFF4A6FA5),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(size * 0.36),
              topRight: Radius.circular(size * 0.36),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(
    ProfileViewModel vm,
    AppColors colors,
    bool isDark,
  ) {
    return Column(
      children: [
        Stack(
          children: [
            _avatar(vm.profileImage, 110),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _isUploading
                    ? null
                    : () => _showImagePickerSheet(colors, isDark),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _accentTeal,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.backgroundColor, width: 2),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.edit, color: Colors.white, size: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Hey, ${vm.name}!',
          style: TextStyle(
            fontFamily: 'monospace',
            color: colors.primaryText,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        if (vm.email.isNotEmpty)
          Text(
            vm.email,
            style: TextStyle(
              fontFamily: 'monospace',
              color: colors.disabledText,
              fontSize: 13,
            ),
          ),
      ],
    );
  }

  void _showEditProfileSheet(
    BuildContext context,
    ProfileViewModel vm,
    AppColors colors,
    bool isDark,
  ) {
    final nameController = TextEditingController(text: vm.name);

    final inputBG = colors.containerBG;
    final textColor = colors.primaryText;
    final hintColor = colors.disabledText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  decoration: BoxDecoration(
                    color: colors.backgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: hintColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: hintColor),
                            onPressed: () => Navigator.pop(sheetCtx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Center(child: _avatar(vm.profileImage, 80)),
                      const SizedBox(height: 24),
                      _inputField(
                        controller: nameController,
                        label: 'Full Name',
                        icon: Icons.person_outline,
                        bgColor: inputBG,
                        textColor: textColor,
                        hintColor: hintColor,
                        labelColor: hintColor,
                      ),
                      const SizedBox(height: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email Address',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: hintColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: colors.disabledText.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: TextEditingController(text: vm.email),
                              enabled: false,
                              style: TextStyle(color: hintColor, fontSize: 15),
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: hintColor,
                                  size: 20,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Text(
                              'Email cannot be changed',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: hintColor,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentTeal,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final name = nameController.text.trim();
                                  if (name.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Name cannot be empty',
                                        ),
                                        backgroundColor: _expenseDeep,
                                      ),
                                    );
                                    return;
                                  }
                                  setSheetState(() => isSaving = true);
                                  final success = await _updateProfile(
                                    name: name,
                                  );
                                  if (success && sheetCtx.mounted) {
                                    Navigator.pop(sheetCtx);
                                  } else {
                                    setSheetState(() => isSaving = false);
                                  }
                                },
                          child: isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
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

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
    required Color hintColor,
    required Color labelColor,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            color: labelColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(color: textColor, fontSize: 15),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: hintColor, size: 20),
              hintText: hint ?? 'Enter $label',
              hintStyle: TextStyle(color: hintColor, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(
    BuildContext context,
    ProfileViewModel vm,
    AppColors colors,
    AppThemeManager themeManager,
    bool isDark,
  ) {
    return Column(
      children: [
        _menuItem(
          Icons.person_outline,
          "Personal Details",
          _accentTeal,
          colors,
          () {
            _showEditProfileSheet(context, vm, colors, isDark);
          },
        ),
        _menuItem(Icons.currency_exchange, "Currency", _accentTeal, colors, () {
          _showCurrencySheet(context, colors, isDark);
        }),
        _menuItem(
          Icons.savings_outlined,
          "Budget Limits",
          _accentTeal,
          colors,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BudgetManagementScreen(email: vm.email),
              ),
            );
          },
        ),
        _menuItem(
          Icons.download_outlined,
          "Export Data",
          _accentTeal,
          colors,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExportScreen(userEmail: vm.email),
              ),
            );
          },
        ),
        Consumer<NotificationViewModel>(
          builder: (_, notifVm, _) => ListTile(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ),
            leading: const Icon(
              Icons.notifications_active_outlined,
              color: _accentTeal,
            ),
            title: Text(
              "Notifications",
              style: TextStyle(
                fontFamily: 'monospace',
                color: colors.primaryText,
                fontSize: 16,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (notifVm.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _accentTeal,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      notifVm.unreadCount > 9 ? '9+' : '${notifVm.unreadCount}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: colors.disabledText,
                  size: 14,
                ),
              ],
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Divider(
            color: colors.disabledText.withOpacity(0.15),
            height: 1,
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            color: _accentTeal,
          ),
          title: Text(
            "Theme",
            style: TextStyle(
              fontFamily: 'monospace',
              color: colors.primaryText,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            isDark ? "Dark mode" : "Light mode",
            style: TextStyle(
              fontFamily: 'monospace',
              color: colors.disabledText,
              fontSize: 12,
            ),
          ),
          trailing: Switch(
            value: !isDark,
            activeThumbColor: _accentTeal,
            onChanged: (_) => themeManager.toggleTheme(),
            thumbIcon: WidgetStateProperty.resolveWith(
              (states) => Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.light_mode, color: _accentTeal),
          title: Text(
            "Auto Light Mode",
            style: TextStyle(
              fontFamily: 'monospace',
              color: colors.primaryText,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            themeManager.autoLight
                ? "Adjusts based on ambient light"
                : "Manual theme control",
            style: TextStyle(
              fontFamily: 'monospace',
              color: colors.disabledText,
              fontSize: 12,
            ),
          ),
          trailing: Switch(
            value: themeManager.autoLight,
            activeThumbColor: _accentTeal,
            onChanged: (_) => themeManager.toggleAutoLight(),
          ),
        ),
      ],
    );
  }

  Widget _menuItem(
    IconData icon,
    String title,
    Color iconColor,
    AppColors colors,
    VoidCallback onTap,
  ) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'monospace',
          color: colors.primaryText,
          fontSize: 16,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: colors.disabledText,
        size: 14,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildLogoutButton(
    BuildContext context,
    ProfileViewModel vm,
    AppColors colors,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.containerBG,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
        onPressed: () => _confirmLogout(context, vm, colors),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: _expenseDeep, size: 18),
            const SizedBox(width: 8),
            Text(
              "Logout",
              style: TextStyle(
                fontFamily: 'monospace',
                color: _expenseDeep,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencySheet(BuildContext context, AppColors colors, bool isDark) {
    final currencies = CurrencyProvider.supportedCurrencies;
    final current = context.read<CurrencyProvider>().code;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.backgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final maxHeight = MediaQuery.of(ctx).size.height * 0.75;

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colors.disabledText.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  'Select Currency',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.primaryText,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: currencies.length,
                    itemBuilder: (_, i) {
                      final c = currencies[i];
                      final isSelected = c['code'] == current;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _accentTeal.withOpacity(0.15)
                                : colors.disabledText.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            c['symbol']!,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: isSelected
                                  ? _accentTeal
                                  : colors.primaryText,
                            ),
                          ),
                        ),
                        title: Text(
                          c['name']!,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: colors.primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          c['code']!,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: colors.disabledText,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: _accentTeal,
                              )
                            : null,
                        onTap: () async {
                          await context.read<CurrencyProvider>().setCurrency(c);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmLogout(
    BuildContext context,
    ProfileViewModel vm,
    AppColors colors,
  ) {
    final notifVm = context.read<NotificationViewModel>();
    final txService = context.read<TransactionService>();
    final txVm = context.read<GetTransactionViewModel>();
    final profileVm = context.read<ProfileViewModel>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Logout",
          style: TextStyle(
            fontFamily: 'monospace',
            color: colors.primaryText,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          "Confirm logout from Walleta?",
          style: TextStyle(fontFamily: 'monospace', color: colors.disabledText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: TextStyle(
                fontFamily: 'monospace',
                color: colors.disabledText,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              await TokenService.clear();
              profileVm.clearProfile();
              txService.clearData();
              txVm.clearTransactions();
              notifVm.clearNotifications();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  // ignore: use_build_context_synchronously
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (r) => false,
                );
              }
            },
            child: const Text(
              "Logout",
              style: TextStyle(fontFamily: 'monospace', color: _expenseDeep),
            ),
          ),
        ],
      ),
    );
  }
}
