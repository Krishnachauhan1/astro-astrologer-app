import 'package:astrosarthi_konnect_astrologer_app/authentication/auth_controller.dart';
import 'package:astrosarthi_konnect_astrologer_app/main.dart';
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

  bool isAstrologer = false;
  bool obscure = true;

  List<String> allSpecs = ['Vedic', 'Tarot', 'KP', 'Numerology'];
  List<String> selectedSpecs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: SingleChildScrollView(
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
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint,
      {bool obscure = false, TextInputType? type}) {
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
    bool success = await auth.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      password: _passCtrl.text.trim(),
      isAstrologer: isAstrologer,
    );

    if (success) {
      Get.snackbar("Success", "Registered successfully");
      Get.offAll(() => const MainShell());
    } else {
      Get.snackbar("Error", "Registration failed");
    }
  }
}
