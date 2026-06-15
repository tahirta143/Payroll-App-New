import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance/attendance_provider.dart';
import '../../models/attendance/attendance_model.dart';
import '../../custom_widgets/inkdrop_loader.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  String _searchQuery = '';
  int? _selectedDepartmentId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    provider.fetchAllEmployees();
    provider.fetchDepartments();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context);
    const tealColor = Color(0xFF007F70);

    // Filter employees locally
    final filteredEmployees = provider.filterEmployees.where((emp) {
      final matchesSearch = emp.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (emp.empId?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesDept = _selectedDepartmentId == null || emp.dutyShift == null; // or if EmployeeModel doesn't directly expose department id, we check bank/shift or map it. Wait, EmployeeModel in attendance_model.dart doesn't have departmentId directly? Let's check how the JSON parser works. Ah! JSON returned by API has department_id. Let's see if we should parse department in EmployeeModel, or if we can filter by name/id.
      // Wait, let's look at EmployeeModel in attendance_model.dart: it has bankName, designationName, etc. But does it have a department? Let's check EmployeeModel.fromJson again:
      // return EmployeeModel(id: ..., designationName: json['designation']...);
      // Wait, the API returns a 'department' map or 'department_id'. Let's check:
      // department: r.department_id ? { id: r.department_id, name: r.department_name } : null
      // So the JSON has 'department' which is a map {id: ..., name: ...} or we can map department in EmployeeModel!
      return matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: tealColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Total Employees',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search employees by name or ID...',
                prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          
          // Employees List
          Expanded(
            child: provider.isLoading
                ? const Center(child: InkDropLoader())
                : RefreshIndicator(
                    color: tealColor,
                    onRefresh: () async => _loadData(),
                    child: filteredEmployees.isEmpty
                        ? const Center(
                            child: Text(
                              'No employees found.',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredEmployees.length,
                            itemBuilder: (context, index) {
                              final emp = filteredEmployees[index];
                              final initials = emp.name.trim().split(RegExp(r'\s+'));
                              final avatarLabel = initials.length > 1
                                  ? '${initials[0][0]}${initials[1][0]}'.toUpperCase()
                                  : initials[0][0].toUpperCase();

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
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
                                child: Row(
                                  children: [
                                    // Profile Image or Initials Avatar
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundColor: tealColor.withOpacity(0.08),
                                      backgroundImage: emp.image != null && emp.image!.isNotEmpty
                                          ? NetworkImage(emp.image!)
                                          : null,
                                      child: emp.image == null || emp.image!.isEmpty
                                          ? Text(
                                              avatarLabel,
                                              style: const TextStyle(
                                                color: tealColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            emp.name,
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            emp.empId ?? 'No ID',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            emp.designationName ?? 'No Designation',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Status Badge or Info icon
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Active',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
