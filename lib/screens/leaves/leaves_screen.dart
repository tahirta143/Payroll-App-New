import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth/auth_provider.dart';
import '../../providers/leaves/leave_provider.dart';
import '../../models/leaves/leave_model.dart';
import '../../custom_widgets/inkdrop_loader.dart';
import '../../custom_widgets/app_drawer.dart';
import 'leaves_dialog.dart';

class LeavesScreen extends StatefulWidget {
  const LeavesScreen({super.key});

  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isEmployee = auth.user?.employeeId != null;
    Provider.of<LeaveProvider>(context, listen: false).fetchLeaves(
      employeeId: isEmployee ? auth.user!.employeeId : null,
    );
  }

  void _openAddEditDialog([LeaveModel? record]) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LeavesDialog(editRecord: record),
    );
    if (result == true) {
      _loadData();
    }
  }


  void _updateStatus(int id, String status) async {
    final success = await Provider.of<LeaveProvider>(context, listen: false).updateLeaveStatus(id, status);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Leave request status updated to $status'),
          backgroundColor: const Color(0xFF007F70),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update leave status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<LeaveProvider>(context);
    const tealColor = Color(0xFF007F70);
    final isEmployee = auth.user?.employeeId != null;

    final filteredLeaves = provider.leaves.where((record) {
      final name = record.employeeName?.toLowerCase() ?? '';
      final type = record.leaveType.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || type.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: AppDrawer(activeRoute: '/leaves'),
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
          isEmployee ? 'My Leaves' : 'Leaves Log Registry',
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
                  hintText: 'Search leaves by employee or type...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),

          // Leaves list
          Expanded(
            child: provider.isLoading
                ? const Center(child: InkDropLoader())
                : RefreshIndicator(
                    color: tealColor,
                    onRefresh: () async => _loadData(),
                    child: filteredLeaves.isEmpty
                        ? const Center(
                            child: Text(
                              'No employee leave logs found.',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredLeaves.length,
                            itemBuilder: (context, index) {
                              final record = filteredLeaves[index];
                              Color statusBg;
                              Color statusText;
                              String statusTextLabel = record.status.toUpperCase();
                              
                              if (record.status.toLowerCase() == 'approved') {
                                statusBg = const Color(0xFFD1FAE5); // emerald-50
                                statusText = const Color(0xFF065F46); // emerald-700
                              } else if (record.status.toLowerCase() == 'rejected') {
                                statusBg = const Color(0xFFFEE2E2); // rose-50
                                statusText = const Color(0xFF991B1B); // rose-700
                              } else {
                                statusBg = const Color(0xFFFEF3C7); // amber-50
                                statusText = const Color(0xFFB45309); // amber-700
                                statusTextLabel = 'PENDING';
                              }

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
                                                color: statusBg,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                statusTextLabel,
                                                style: TextStyle(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                  color: statusText,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Type: ${record.leaveType}',
                                              style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                            ),
                                            Text(
                                              'Days: ${record.days.toInt()}',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        if (!isEmployee && record.status.toLowerCase() == 'pending') ...[
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF059669),
                                                    foregroundColor: Colors.white,
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                  ),
                                                  onPressed: () => _updateStatus(record.id, 'approved'),
                                                  icon: const Icon(Icons.check, size: 14),
                                                  label: const Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFFE15353),
                                                    foregroundColor: Colors.white,
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                  ),
                                                  onPressed: () => _updateStatus(record.id, 'rejected'),
                                                  icon: const Icon(Icons.close, size: 14),
                                                  label: const Text('Reject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],

                                  ),
                                ),
                              ));
                            },
                            ),
                  ),
          ),
        ],
      ),
      floatingActionButton: (auth.hasPermission('can-add-leaves') || isEmployee)
          ? FloatingActionButton(
              backgroundColor: tealColor,
              onPressed: () => _openAddEditDialog(),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
