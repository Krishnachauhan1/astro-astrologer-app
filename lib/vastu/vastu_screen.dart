import 'package:astrosarthi_vendor/utils/app_snackbar.dart';
import 'package:astrosarthi_vendor/vastu/vastu_attachment_helper.dart';
import 'package:astrosarthi_vendor/vastu/vastu_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
class VastuScreen extends StatelessWidget {
  const VastuScreen({super.key});

  bool _isLayout(Map item) => item['request_type'] == 'layout';

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
            return const Center(child: Text('No Requests Found'));
          }

          return RefreshIndicator(
            onRefresh: ctrl.getVastuRequest,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ctrl.vastuRequests.length,
              itemBuilder: (context, index) {
                final item = ctrl.vastuRequests[index];
                final isLayout = _isLayout(item);
                final homeMap = item['home_map'] as Map?;

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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item['name'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isLayout
                                    ? Colors.blue.withOpacity(0.15)
                                    : (item['status'] == 'pending'
                                        ? Colors.orange.withOpacity(0.2)
                                        : Colors.green.withOpacity(0.2)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isLayout ? 'Map Layout' : (item['status'] ?? ''),
                                style: TextStyle(
                                  color: isLayout
                                      ? Colors.blue.shade700
                                      : (item['status'] == 'pending'
                                          ? Colors.orange
                                          : Colors.green),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('📍 ${item['city'] ?? ''}'),
                        if (isLayout) ...[
                          const SizedBox(height: 6),
                          Text(
                            '🏗️ Layout fee: ₹${item['layout_fee_paid'] ?? 0}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'User ke paas map nahi hai — location + attachment se layout banana hai.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              height: 1.35,
                            ),
                          ),
                        ],
                        if (!isLayout) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Problems: ${(item['problems'] as List?)?.join(', ') ?? ''}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          if (item['consult_charge'] != null)
                            Text(
                              '💰 Consult: ₹${item['consult_charge']} (${item['duration_minutes'] ?? '—'} min)',
                            ),
                          Text('📹 ${item['consult_type'] ?? ''}'),
                          Text('⏰ ${item['preferred_time'] ?? ''}'),
                        ],
                        if (homeMap != null) ...[
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          Text(
                            '📎 ${homeMap['attachment_name'] ?? 'Home attachment'}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (homeMap['address'] != null &&
                              homeMap['address'].toString().isNotEmpty)
                            Text(
                              homeMap['address'].toString(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          Text(
                            'Lat: ${homeMap['latitude']}, Lng: ${homeMap['longitude']}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                          if (homeMap['id'] != null) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  final mapId = homeMap['id'];
                                  final id = mapId is int
                                      ? mapId
                                      : int.tryParse('$mapId');
                                  if (id == null) {
                                    AppSnackbar.show(
                                      'Attachment',
                                      'Map ID not available',
      );
                                    return;
                                  }
                                  openVastuAttachment(
                                    context,
                                    homeMapId: id,
                                    attachmentType:
                                        homeMap['attachment_type']?.toString(),
                                    fileName: homeMap['attachment_name']
                                            ?.toString() ??
                                        'Home attachment',
      );
                                },
                                icon: Icon(
                                  homeMap['attachment_type'] == 'pdf'
                                      ? Icons.picture_as_pdf_outlined
                                      : Icons.image_outlined,
                                ),
                                label: Text(
                                  homeMap['attachment_type'] == 'pdf'
                                      ? 'Open PDF'
                                      : 'View image',
                                ),
                              ),
                            ),
                          ],
                        ],
                        if (!isLayout &&
                            item['additional_notes'] != null &&
                            item['additional_notes'].toString().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('📝 ${item['additional_notes']}'),
                        ],
                      ],
                    ),
                  ),
      );
              },
            ),
      );
        },
      ),
      );
  }

}
