import 'dart:convert';
import 'package:astrosarthi_konnect_astrologer_app/app_theme.dart';
import 'package:astrosarthi_konnect_astrologer_app/authentication/auth_controller.dart';
import 'package:astrosarthi_konnect_astrologer_app/authentication/login_screen.dart';
import 'package:astrosarthi_konnect_astrologer_app/chat/chat_list_controller.dart';
import 'package:astrosarthi_konnect_astrologer_app/chat/chat_list.dart';
import 'package:astrosarthi_konnect_astrologer_app/chat/chat_screen.dart';
import 'package:astrosarthi_konnect_astrologer_app/home/home_screen.dart';
import 'package:astrosarthi_konnect_astrologer_app/live_stream/live_controller.dart';
import 'package:astrosarthi_konnect_astrologer_app/live_stream/live_screen.dart';
import 'package:astrosarthi_konnect_astrologer_app/notification/notification_service.dart';
import 'package:astrosarthi_konnect_astrologer_app/profile/profile_screen.dart';
import 'package:astrosarthi_konnect_astrologer_app/servicess/api_service.dart';
import 'package:astrosarthi_konnect_astrologer_app/vastu/vastu_controller.dart';
import 'package:astrosarthi_konnect_astrologer_app/vastu/vastu_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


import 'firebase_options.dart';

class NavController extends GetxController {
  int currentIndex = 0;

  void changePage(int i) {
    currentIndex = i;
    update();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await ApiService.loadToken();

  await NotificationService().initialize();

  runApp(const AstrologyApp());
}

class AstrologyApp extends StatelessWidget {
  const AstrologyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Astrosarthi Konnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialBinding: BindingsBuilder(() {
        Get.put(AuthController());
        Get.put(NavController());
        // Get.put(ChatController());
        Get.put(VastuController());
        Get.put(LiveController());
        Get.put(VastuController());
      }),
      home: GetBuilder<AuthController>(
        builder: (auth) => auth.isLoggedIn ? const MainShell() : const LoginScreen(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MAIN SHELL
// ─────────────────────────────────────────────
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _pages = [
    HomeScreen(),
    ChatList(),
    LiveScreen(),
    VastuScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NavController>(
      builder: (nav) => Scaffold(
        body: IndexedStack(index: nav.currentIndex, children: _pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: nav.currentIndex,
          onTap: nav.changePage,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.live_tv_rounded), label: 'Live'),
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Vastu'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// LOGIN SCREEN
// ─────────────────────────────────────────────


// ─────────────────────────────────────────────
// HOME SCREEN
// ─────────────────────────────────────────────





// ─────────────────────────────────────────────
// CART SCREEN
// ─────────────────────────────────────────────
// class CartScreen extends StatelessWidget {
//   const CartScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<ShopController>(
//       builder: (ctrl) => Scaffold(
//         appBar: AppBar(title: const Text('My Cart')),
//         body: ctrl.cart.isEmpty
//             ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.textHint), SizedBox(height: 12), Text('Cart is empty', style: TextStyle(color: AppColors.textSecondary))]))
//             : Column(
//           children: [
//             Expanded(
//               child: ListView.builder(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: ctrl.cart.length,
//                 itemBuilder: (_, i) {
//                   final item = ctrl.cart[i];
//                   final p = item['product'] as ProductModel;
//                   final qty = item['qty'] as int;
//                   return Card(
//                     margin: const EdgeInsets.only(bottom: 10),
//                     child: ListTile(
//                       leading: const CircleAvatar(backgroundColor: AppColors.primarySurface, child: Icon(Icons.diamond_outlined, color: AppColors.primary)),
//                       title: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
//                       subtitle: Text('₹${p.price.toInt()} × $qty', style: const TextStyle(color: AppColors.primary, fontSize: 12)),
//                       trailing: Text('₹${(p.price * qty).toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
//                     ),
//                   );
//                 },
//               ),
//             ),
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))]),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                       Text('₹${ctrl.cartTotal.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
//                     ],
//                   ),
//                   const SizedBox(height: 14),
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: () => Get.to(() => const CheckoutScreen()),
//                       child: const Text('Proceed to Checkout', style: TextStyle(fontSize: 15)),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
//
// class CheckoutScreen extends StatefulWidget {
//   const CheckoutScreen({super.key});
//
//   @override
//   State<CheckoutScreen> createState() => _CheckoutScreenState();
// }
//
// class _CheckoutScreenState extends State<CheckoutScreen> {
//   final _nameCtrl = TextEditingController();
//   final _phoneCtrl = TextEditingController();
//   final _addressCtrl = TextEditingController();
//   final _cityCtrl = TextEditingController();
//   final _pincodeCtrl = TextEditingController();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Checkout')),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: GetBuilder<ShopController>(
//           builder: (ctrl) => Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text('Shipping Address', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
//               const SizedBox(height: 16),
//               _field(_nameCtrl, 'Full Name'),
//               _field(_phoneCtrl, 'Phone'),
//               _field(_addressCtrl, 'Address'),
//               _field(_cityCtrl, 'City'),
//               _field(_pincodeCtrl, 'Pincode', keyboard: TextInputType.number),
//               const SizedBox(height: 24),
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(14)),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text('Order Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
//                     Text('₹${ctrl.cartTotal.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16)),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 20),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () async {
//                     final success = await ctrl.placeOrder({
//                       'name': _nameCtrl.text,
//                       'phone': _phoneCtrl.text,
//                       'address': _addressCtrl.text,
//                       'city': _cityCtrl.text,
//                       'pincode': _pincodeCtrl.text,
//                     });
//                     if (success) {
//                       Get.back();
//                       Get.back();
//                       Get.snackbar('Order Placed!', 'Your order has been placed successfully 🎉', backgroundColor: AppColors.online, colorText: Colors.white);
//                     }
//                   },
//                   child: const Text('Place Order', style: TextStyle(fontSize: 16)),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _field(TextEditingController c, String hint, {TextInputType? keyboard}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: TextField(
//         controller: c,
//         keyboardType: keyboard,
//         decoration: InputDecoration(
//           hintText: hint,
//           filled: true,
//           fillColor: AppColors.surfaceVariant,
//           hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
//           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
//         ),
//       ),
//     );
//   }
// }

// ─────────────────────────────────────────────
// LIVE SCREEN
// ─────────────────────────────────────────────


// ─────────────────────────────────────────────
// VASTU SCREEN
// ─────────────────────────────────────────────


// ─────────────────────────────────────────────
// PROFILE SCREEN
// ─────────────────────────────────────────────
