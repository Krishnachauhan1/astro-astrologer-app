
import 'package:astrosarthi_vendor/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _keyPush = 'astro_push_notifications';
  static const _keySound = 'astro_sound_effects';
  static const _keyAutoOnline = 'astro_show_online';

  bool _pushEnabled = true;
  bool _soundEnabled = true;
  bool _showOnline = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled = prefs.getBool(_keyPush) ?? true;
      _soundEnabled = prefs.getBool(_keySound) ?? true;
      _showOnline = prefs.getBool(_keyAutoOnline) ?? true;
      _loading = false;
    });
  }

  Future<void> _save(String key, bool value, void Function(bool) setter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() => setter(value));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _sectionTitle('Notifications'),
                _card([
                  SwitchListTile(
                    value: _pushEnabled,
                    onChanged: (v) => _save(_keyPush, v, (x) => _pushEnabled = x),
                    activeThumbColor: AppColors.primary,
                    title: const Text('Push notifications', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('New chat, call and live requests'),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _soundEnabled,
                    onChanged: (v) => _save(_keySound, v, (x) => _soundEnabled = x),
                    activeThumbColor: AppColors.primary,
                    title: const Text('Sound alerts', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Ringtone for incoming sessions'),
                  ),
                ]),
                const SizedBox(height: 20),
                _sectionTitle('Availability'),
                _card([
                  SwitchListTile(
                    value: _showOnline,
                    onChanged: (v) => _save(_keyAutoOnline, v, (x) => _showOnline = x),
                    activeThumbColor: AppColors.primary,
                    title: const Text('Show as available', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Let users see you when online'),
                  ),
                ]),
                const SizedBox(height: 20),
                _sectionTitle('Legal'),
                _card([
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                    title: const Text('Privacy policy', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                    onTap: () => _showText(
                      'Privacy policy',
                      'Your astrologer profile and earnings data are kept confidential and used only for platform operations.',
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                    title: const Text('Terms of service', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                    onTap: () => _showText(
                      'Terms of service',
                      'You agree to respond to paid sessions promptly and maintain professional conduct on live, chat and calls.',
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                _sectionTitle('About'),
                _card(const [
                  ListTile(
                    leading: Icon(Icons.info_outline, color: AppColors.primary),
                    title: Text('App version', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Text('1.0.0', style: TextStyle(color: AppColors.textHint)),
                  ),
                ]),
              ],
            ),
      );
  }

  void _showText(String title, String body) {
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [TextButton(onPressed: Get.back, child: const Text('Close'))],
      ),
      );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textHint,
        ),
      ),
      );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
      );
  }
}
