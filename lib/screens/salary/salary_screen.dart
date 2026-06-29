import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth/auth_provider.dart';
import '../../providers/salary/salary_provider.dart';
import '../../models/salary/salary_model.dart';
import '../../custom_widgets/inkdrop_loader.dart';
import '../../custom_widgets/app_drawer.dart';
import 'salary_dialog.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    Provider.of<SalaryProvider>(context, listen: false).fetchSalaries();
  }

  void _openAddEditDialog([SalaryModel? record]) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SalaryDialog(editRecord: record),
    );
    if (result == true) {
      _loadData();
    }
  }


  String _getPaymentModesText(SalaryModel record) {
    final modes = <String>[];
    if (record.salaryByCash) modes.add('Cash');
    if (record.salaryByCheque) modes.add('Cheque');
    if (record.salaryByTransfer) modes.add('Transfer');
    return modes.isNotEmpty ? modes.join(', ') : '-';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<SalaryProvider>(context);
    const tealColor = Color(0xFF007F70);
    final isEmployee = auth.user?.employeeId != null;

    final filteredSalaries = provider.salaries.where((record) {
      if (isEmployee && record.employeeId != auth.user?.employeeId) {
        return false;
      }
      final name = record.employeeName?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: AppDrawer(activeRoute: '/salary'),
      appBar: AppBar(
        backgroundColor: tealColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          isEmployee ? 'My Salary' : 'Salaries',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Search Bar - hide for employees
          if (!isEmployee)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search salary by employee name...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),

          // Salaries list
          Expanded(
            child: provider.isLoading
                ? const Center(child: InkDropLoader())
                : RefreshIndicator(
                    color: tealColor,
                    onRefresh: () async => _loadData(),
                    child: filteredSalaries.isEmpty
                        ? const Center(
                            child: Text(
                              'No salary configuration logs found.',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredSalaries.length,
                            itemBuilder: (context, index) {
                              final record = filteredSalaries[index];
                              return GestureDetector(
                                onTap: () => _openAddEditDialog(record),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              record.employeeName ?? 'Employee Name',
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: tealColor.withOpacity(0.08),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                _getPaymentModesText(record).toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                  color: tealColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        
                                        // Salary breakdowns
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            _buildAmountCol('Basic', record.basicSalary),
                                            _buildAmountCol('Gross', record.grossSalary),
                                            _buildAmountCol('Net Salary', record.netSalary, isBold: true),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          record.bankName != null ? 'Bank: ${record.bankName}' : 'No bank set',
                                          style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: auth.hasPermission('can-add-salary')
          ? FloatingActionButton(
              backgroundColor: tealColor,
              onPressed: () => _openAddEditDialog(),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildAmountCol(String label, double val, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          'Rs ${val.toInt().toString()}',
          style: TextStyle(
            fontSize: isBold ? 13 : 11,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? const Color(0xFF007F70) : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
