import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:it_team_app/file_upload.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

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
              child: SizedBox(
              height: 200,
              width: 300,
              child: LineChart(
                LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) => Text(
                    ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'][value.toInt()],
                    style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  ),
                  leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    reservedSize: 50,
                    showTitles: true,
                    getTitlesWidget: (value, _) => Text(
                    '₹${value.toInt()}',
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
