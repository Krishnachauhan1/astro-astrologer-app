import 'package:astrosarthi_vendor/app_theme.dart';
import 'package:astrosarthi_vendor/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  static const _email = 'Astrosarathikonnect12@gmail.com';
  static const _phone = '+91 91791 24535';

  final _issueCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _issueCtrl.dispose();
    super.dispose();
  }

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    AppSnackbar.show('Copied', '$label copied');
  }

  Future<void> _submit() async {
    final text = _issueCtrl.text.trim();
    if (text.isEmpty) {
      AppSnackbar.show('Help', 'Please describe your issue');
      return;
    }
    setState(() => _sending = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _sending = false);
    _issueCtrl.clear();
    AppSnackbar.show('Submitted', 'Support will reach out within 24 hours.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.headset_mic_rounded, color: Colors.white, size: 34),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Astrologer support\nMon–Sat, 9 AM – 9 PM',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _contact(Icons.email_outlined, 'Email', _email),
          _contact(Icons.phone_outlined, 'Phone', _phone),
          const SizedBox(height: 16),
          _faq(
            'When do I get paid?',
            'Earnings are settled as per the payout schedule shown in My Earnings. Completed sessions appear after the user session ends.',
          ),
          _faq(
            'Live not starting?',
            'Allow camera and microphone permissions, check internet, and ensure no other app is using the camera.',
          ),
          _faq(
            'Missed a chat request?',
            'Keep notifications on in Settings. Pending requests show as a banner while you are live.',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Report an issue',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _issueCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Describe the problem…',
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _sending ? null : _submit,
                    child: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contact(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(value),
        trailing: const Icon(Icons.copy_rounded, size: 18),
        onTap: () => _copy(title, value),
      ),
    );
  }

  Widget _faq(String q, String a) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          q,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              a,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
