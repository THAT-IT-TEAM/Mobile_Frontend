import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:it_team_app/file_upload.dart';
import 'package:it_team_app/auth_service.dart';
import 'package:it_team_app/landing_page.dart';
import 'package:it_team_app/expense_service.dart';

// Replace with your actual API base URL
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String API_BASE_URL = dotenv.env['API_BASE_URL'] ?? '';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? _summary;
  List<dynamic> _expenses = [];
  bool _loading = true;
  String? _error;
  final ExpenseService _expenseService = ExpenseService();

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    await Future.wait([
      _fetchDashboardSummary(),
      _fetchExpenses(),
    ]);
  }

  Future<void> _fetchExpenses() async {
    try {
      final expenses = await _expenseService.getExpensesByEmail();
      setState(() {
        _expenses = expenses;
      });
    } catch (e) {
      print('Error fetching expenses: $e');
      // Don't set error state as this is secondary data
    }
  }

  Future<void> _fetchDashboardSummary() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final headers = await AuthService().getAuthHeaders();
      final response = await http.get(
        Uri.parse('$API_BASE_URL/api/dashboard/user-summary'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        setState(() {
          print('Dashboard Summary Response: ${response.body}');
          _summary = json.decode(response.body);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load dashboard data';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCard('Current Expenditure', _formatCurrency(_summary?['currentExpenditure'])),
                      _buildCard('Budget', _formatCurrency(_summary?['budget'])),
                      _buildCard('Vendors', '${_summary?['vendors'] ?? '-'} Active'),
                      _buildCard('Audit Sync Rate', '${_summary?['auditSyncRate'] ?? '-'}%'),
                      _buildCard('Active Projects', '${_summary?['activeProjects'] ?? '-'}'),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Expense Table'),
                      Container(
                        height: 300,
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          color: placeholderColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: _expenses.isEmpty
                            ? const Center(
                                child: Text('No expenses found',
                                    style: TextStyle(color: Colors.white70)))
                            : SingleChildScrollView(
                                child: DataTable(
                                  columnSpacing: 20,
                                  columns: const [
                                    DataColumn(
                                      label: Text('Vendor',
                                          style: TextStyle(color: Colors.white)),
                                    ),
                                    DataColumn(
                                      label: Text('Amount',
                                          style: TextStyle(color: Colors.white)),
                                    ),
                                    DataColumn(
                                      label: Text('Category',
                                          style: TextStyle(color: Colors.white)),
                                    ),
                                    DataColumn(
                                      label: Text('Date',
                                          style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                  rows: _expenses.map<DataRow>((expense) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(
                                            expense['vendor_name'] ?? 'Unknown',
                                            style: const TextStyle(
                                                color: Colors.white))),
                                        DataCell(Text(
                                            '${expense['currency'] ?? 'USD'} ${_formatCurrency(expense['amount'])}',
                                            style: const TextStyle(
                                                color: Colors.white))),
                                        DataCell(Text(
                                            expense['category'] ?? 'Uncategorized',
                                            style: const TextStyle(
                                                color: Colors.white))),
                                        DataCell(Text(
                                            _formatDate(expense['transaction_date']),
                                            style: const TextStyle(
                                                color: Colors.white))),
                                      ],
                                    );
                                  }).toList(),
                                ),
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

  String _formatCurrency(dynamic value) {
    if (value == null) return '-';
    return '₹${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString; // Return the original string in case of error
    }
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
