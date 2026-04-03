import 'package:astrosarthi_konnect_astrologer_app/app_theme.dart';
import 'package:astrosarthi_konnect_astrologer_app/authentication/auth_controller.dart';
import 'package:astrosarthi_konnect_astrologer_app/authentication/register_screen.dart';
import 'package:astrosarthi_konnect_astrologer_app/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _isRegister = false;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Logo area
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: const Icon(Icons.auto_awesome, color: AppColors.gold, size: 42),
                ),
                const SizedBox(height: 16),
                const Text('Astrosarthi konnect', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const Text('Your Cosmic Guide', style: TextStyle(color: AppColors.goldLight, fontSize: 14)),
                const SizedBox(height: 40),
                // Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: AppColors.primaryDark.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_isRegister ? 'Create Account' : 'Welcome Back', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(_isRegister ? 'Start your cosmic journey' : 'Sign in to continue', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 24),
                      if (_isRegister) ...[
                        _buildField(_nameCtrl, 'Full Name', Icons.person_outline),
                        const SizedBox(height: 14),
                        _buildField(_phoneCtrl, 'Phone Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
                        const SizedBox(height: 14),
                      ],
                      _buildField(_emailCtrl, 'Email Address', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 14),
                      _buildField(_passCtrl, 'Password', Icons.lock_outline,
                          obscure: _obscure,
                          suffix: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.textHint, size: 20),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          )),
                      const SizedBox(height: 24),
                      GetBuilder<AuthController>(
                        builder: (auth) => SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : () => _submit(auth),
                            child: auth.isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(_isRegister ? 'Create Account' : 'Sign In', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Get.to(()=>RegisterScreen());
                          },
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 13),
                              children: [
                                TextSpan(text: _isRegister ? 'Already have an account? ' : "Don't have an account? ", style: const TextStyle(color: AppColors.textSecondary)),
                                TextSpan(text: _isRegister ? 'Sign In' : 'Register', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon,
      {bool obscure = false, Widget? suffix, TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  Future<void> _submit(AuthController auth) async {
    bool success;
    // if (_isRegister) {
    //   success = await auth.register(_nameCtrl.text.trim(), _emailCtrl.text.trim(), _phoneCtrl.text.trim(), _passCtrl.text.trim(), name: '', email: '', phone: '', password: '');
    // } else {
      success = await auth.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
    // }
    if (success) {
      Get.offAll(() => const MainShell());
    } else {
      Get.snackbar('Error', 'Invalid credentials. Please try again.',
          backgroundColor: AppColors.busy, colorText: Colors.white);
    }
  }
}