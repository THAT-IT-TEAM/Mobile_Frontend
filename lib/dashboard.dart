import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:it_team_app/file_upload.dart';
import 'package:it_team_app/auth_service.dart';
import 'package:it_team_app/landing_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF181818),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Colors.white, width: 2),
      ),
      title: const Text(
        'Confirm Logout',
        style: TextStyle(
        fontFamily: 'EudoxusSans',
        color: Colors.white,
        fontWeight: FontWeight.w600,
        ),
      ),
      content: const Text(
        'Are you sure you want to log out?',
        style: TextStyle(
        fontFamily: 'EudoxusSans',
        color: Colors.white70,
        ),
      ),
      actions: [
        TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white70,
          textStyle: const TextStyle(fontFamily: 'EudoxusSans'),
        ),
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Cancel'),
        ),
        TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
          fontFamily: 'EudoxusSans',
          fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('Logout'),
        ),
      ],
      ),
    );
    if (confirmed == true) {
      await AuthService().clearToken();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LandingLoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkBackground = Color(0xFF121212);
    const placeholderColor = Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard('Current Expenditure', '₹1,20,000'),
            _buildCard('Budget', '₹2,50,000'),
            _buildCard('Vendors', '12 Active'),
            _buildCard('Audit Sync Rate', '85%'),
            _buildCard('Active Projects', '5'),
            const SizedBox(height: 24),
            _buildSectionTitle('Expenditure Graph'),
            const SizedBox(height: 12),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 600,
                    minWidth: 200,
                    minHeight: 220,
                    maxHeight: 280,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 240,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                                if (value % 1 == 0 && value >= 0 && value < months.length) {
                                  return Text(
                                    months[value.toInt()],
                                    style: const TextStyle(color: Colors.white),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              reservedSize: 0,
                              showTitles: true,
                              getTitlesWidget: (value, _) => Text(
                                '',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true, border: Border.all(color: Colors.white)),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            spots: [
                              FlSpot(0, 100),
                              FlSpot(1, 200),
                              FlSpot(2, 150),
                              FlSpot(3, 180),
                              FlSpot(4, 240),
                              FlSpot(5, 300),
                            ],
                            color: Colors.white,
                            barWidth: 3,
                            dotData: FlDotData(show: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Expense Table'),
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: placeholderColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Center(
                child: Text('Table will go here', style: TextStyle(color: Colors.white70)),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF333333),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.white, width: 1.5),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FileUploadPage()),
                  );
                },
                child: const Text(
                  'Upload New Expense',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
