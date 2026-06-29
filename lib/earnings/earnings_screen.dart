import 'package:astrosarthi_konnect_astrologer_app/app_theme.dart';
import 'package:astrosarthi_konnect_astrologer_app/earnings/earnings_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EarningsController>(
      init: EarningsController(),
      builder: (ctrl) {
        final today = ctrl.bucket('today');
        final month = ctrl.bucket('this_month');

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: const Text('My Earnings'),
          ),
          body: ctrl.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : RefreshIndicator(
                  onRefresh: ctrl.loadAll,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _infoCard(
                        '50% revenue share with 10% TDS on your share. Net amount is credited to wallet after ITR compliance.',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              'Today',
                              ctrl.money(today['net_amount']),
                              'Gross ${ctrl.money(today['gross_amount'])}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statCard(
                              'This Month',
                              ctrl.money(month['net_amount']),
                              'Gross ${ctrl.money(month['gross_amount'])}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _breakdownCard('Today breakdown', today, ctrl),
                      const SizedBox(height: 12),
                      _breakdownCard('This month breakdown', month, ctrl),
                      const SizedBox(height: 20),
                      const Text(
                        'Daily earnings (30 days)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      if (ctrl.daily.isEmpty)
                        const Text('No earnings yet', style: TextStyle(color: AppColors.textSecondary))
                      else
                        ...ctrl.daily.map(
                          (row) => Card(
                            child: ListTile(
                              title: Text('${row['date']}'),
                              subtitle: Text('${row['transactions']} sessions'),
                              trailing: Text(
                                ctrl.money(row['net_amount']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      const Text(
                        'Monthly earnings',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      if (ctrl.monthly.isEmpty)
                        const Text('No monthly data', style: TextStyle(color: AppColors.textSecondary))
                      else
                        ...ctrl.monthly.map(
                          (row) => Card(
                            child: ListTile(
                              title: Text('${row['month_label']}'),
                              subtitle: Text('TDS ${ctrl.money(row['tds_amount'])}'),
                              trailing: Text(
                                ctrl.money(row['net_amount']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
      );
      },
      );
  }

  Widget _infoCard(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, height: 1.4)),
      );
  }

  Widget _statCard(String label, String value, String sub) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
      );
  }

  Widget _breakdownCard(String title, Map<String, dynamic> data, EarningsController ctrl) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            _row('Gross', ctrl.money(data['gross_amount'])),
            _row('Your 50% share', ctrl.money(data['astrologer_gross'])),
            _row('TDS (10%)', ctrl.money(data['tds_amount'])),
            _row('Net credited', ctrl.money(data['net_amount'])),
            _row('Sessions', '${data['transactions'] ?? 0}'),
          ],
        ),
      ),
      );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
      );
  }
}
