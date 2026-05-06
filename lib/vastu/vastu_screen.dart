import 'package:astrosarthi_konnect_astrologer_app/vastu/vastu_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VastuScreen extends StatelessWidget {
  const VastuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vastu Consultation')),
      body: GetBuilder<VastuController>(
        init: VastuController()..getVastuRequest(),
        builder: (ctrl) {
          if (ctrl.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (ctrl.vastuRequests.isEmpty) {
            return const Center(child: Text("No Requests Found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ctrl.vastuRequests.length,
            itemBuilder: (context, index) {
              final item = ctrl.vastuRequests[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// Name + Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item['name'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: item['status'] == 'pending'
                                  ? Colors.orange.withOpacity(0.2)
                                  : Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item['status'] ?? '',
                              style: TextStyle(
                                color: item['status'] == 'pending'
                                    ? Colors.orange
                                    : Colors.green,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text("📞 ${item['phone'] ?? ''}"),
                      Text("📍 ${item['city'] ?? ''}"),

                      const SizedBox(height: 6),

                      /// Problems (IMPORTANT)
                      Text(
                        "Problems: ${(item['problems'] as List?)?.join(', ') ?? ''}",
                        style: const TextStyle(fontSize: 13),
                      ),

                      const SizedBox(height: 6),

                      Text("💰 Budget: ${item['budget'] ?? ''}"),
                      Text("📹 ${item['consult_type'] ?? ''}"),
                      Text("⏰ ${item['preferred_time'] ?? ''}"),

                      if (item['additional_notes'] != null &&
                          item['additional_notes'].toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text("📝 ${item['additional_notes']}"),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}