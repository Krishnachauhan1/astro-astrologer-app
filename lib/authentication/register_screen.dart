import 'package:astrosarthi_vendor/authentication/auth_controller.dart';
import 'package:astrosarthi_vendor/authentication/login_screen.dart';
import 'package:astrosarthi_vendor/main.dart';
import 'package:astrosarthi_vendor/utils/app_snackbar.dart';
import 'package:astrosarthi_vendor/utils/safe_bottom.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _chatRateCtrl = TextEditingController();
  final _callRateCtrl = TextEditingController();
  final _videoRateCtrl = TextEditingController();
  final _expCtrl = TextEditingController();

  bool obscure = true;

  List<String> allSpecs = [
    'Vedic',
    'Vastu',
    'Tarot',
    'KP',
    'Numerology',
    'Palmistry',
    'Face Reading',
  ];
  List<String> selectedSpecs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
            _field(_nameCtrl, "Name"),
            _field(_emailCtrl, "Email"),
            _field(_phoneCtrl, "Phone"),
            _field(_passCtrl, "Password", obscure: true),

            const SizedBox(height: 10),

            // 🔥 Astrologer Fields
            _field(_bioCtrl, "Bio"),

            const SizedBox(height: 10),

            // 🔥 Specializations
            Align(
              alignment: Alignment.centerLeft,
              child: const Text("Specializations"),
            ),
            Wrap(
              spacing: 8,
              children: allSpecs.map((spec) {
                final selected = selectedSpecs.contains(spec);
                return FilterChip(
                  label: Text(spec),
                  selected: selected,
                  onSelected: (val) {
                    setState(() {
                      val
                          ? selectedSpecs.add(spec)
                          : selectedSpecs.remove(spec);
                    });
                  },
      );
              }).toList(),
            ),

            const SizedBox(height: 10),

            _field(_chatRateCtrl, "Chat Rate", type: TextInputType.number),
            _field(_callRateCtrl, "Call Rate", type: TextInputType.number),
            _field(_videoRateCtrl, "Video Rate", type: TextInputType.number),
            _field(_expCtrl, "Experience (years)", type: TextInputType.number),

            const SizedBox(height: 20),

            GetBuilder<AuthController>(
              builder: (auth) => ElevatedButton(
                onPressed: auth.isLoading ? null : () => _submit(auth),
                child: auth.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Register"),
              ),
            ),
            SafeBottom.spacer(context),
          ],
        ),
      ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    bool obscure = false,
    TextInputType? type,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: type,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      );
  }

  Future<void> _submit(AuthController auth) async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final password = _passCtrl.text.trim();
    final bio = _bioCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      AppSnackbar.show('Error', 'Name, email, phone and password are required');
      return;
    }
    if (bio.isEmpty) {
      AppSnackbar.show('Error', 'Please enter your bio');
      return;
    }
    if (selectedSpecs.isEmpty) {
      AppSnackbar.show('Error', 'Select at least one specialization');
      return;
    }

    final chatRate = int.tryParse(_chatRateCtrl.text.trim());
    final callRate = int.tryParse(_callRateCtrl.text.trim());
    final videoRate = int.tryParse(_videoRateCtrl.text.trim());
    final experienceYears = int.tryParse(_expCtrl.text.trim());

    if (chatRate == null || callRate == null || videoRate == null) {
      AppSnackbar.show('Error', 'Enter valid chat, call and video rates');
      return;
    }
    if (experienceYears == null || experienceYears < 0) {
      AppSnackbar.show('Error', 'Enter valid experience in years');
      return;
    }

    final success = await auth.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      isAstrologer: true,
      bio: bio,
      specializations: List<String>.from(selectedSpecs),
      chatRate: chatRate,
      callRate: callRate,
      videoRate: videoRate,
      experienceYears: experienceYears,
      );

    if (success) {
      AppSnackbar.show('Success', 'Registered successfully');
      Get.offAll(() => const LoginScreen());
    } else {
      AppSnackbar.show(
        'Error',
        auth.lastRegisterError ?? 'Registration failed',
      );
    }
  }
}
