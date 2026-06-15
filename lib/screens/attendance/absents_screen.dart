import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api_services/api_service.dart';
import '../../models/attendance/absent_model.dart';
import '../../custom_widgets/inkdrop_loader.dart';

class AbsentsScreen extends StatefulWidget {
  final DateTime? initialDate;
  const AbsentsScreen({super.key, this.initialDate});

  @override
  State<AbsentsScreen> createState() => _AbsentsScreenState();
}

class _AbsentsScreenState extends State<AbsentsScreen> {
  List<AbsentModel> _absents = [];
  bool _isLoading = false;
  String _searchQuery = '';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _isLoading = true;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService().get('/api/absents');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['absents'] as List? ?? [];
        setState(() {
          _absents = list.map((item) => AbsentModel.fromJson(item)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading absents: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF007F70),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const tealColor = Color(0xFF007F70);

    final filteredAbsents = _absents.where((absent) {
      final matchesSearch = absent.employeeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (absent.code?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      bool matchesDate = true;
      if (_selectedDate != null) {
        try {
          final absentDateObj = DateTime.parse(absent.absentDate);
          matchesDate = absentDateObj.year == _selectedDate!.year &&
              absentDateObj.month == _selectedDate!.month &&
              absentDateObj.day == _selectedDate!.day;
        } catch (_) {
          matchesDate = false;
        }
      }
      return matchesSearch && matchesDate;
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
          'Absent Logs',
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
          // Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search absents by employee name...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate == null
                          ? 'Showing All Dates'
                          : 'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Row(
                      children: [
                        if (_selectedDate != null)
                          TextButton(
                            onPressed: () => setState(() => _selectedDate = null),
                            child: const Text('Clear Date', style: TextStyle(color: Colors.red, fontSize: 12)),
                          ),
                        OutlinedButton.icon(
                          onPressed: () => _selectDate(context),
                          icon: const Icon(Icons.calendar_today_outlined, size: 14),
                          label: const Text('Filter Date', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: tealColor,
                            side: const BorderSide(color: tealColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Absents List
          Expanded(
            child: _isLoading
                ? const Center(child: InkDropLoader())
                : RefreshIndicator(
                    color: tealColor,
                    onRefresh: _loadData,
                    child: filteredAbsents.isEmpty
                        ? const Center(
                            child: Text(
                              'No absent logs found.',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredAbsents.length,
                            itemBuilder: (context, index) {
                              final absent = filteredAbsents[index];
                              final initials = absent.employeeName.trim().split(RegExp(r'\s+'));
                              final avatarLabel = initials.length > 1
                                  ? '${initials[0][0]}${initials[1][0]}'.toUpperCase()
                                  : initials[0][0].toUpperCase();

                              String formattedDate = '';
                              try {
                                formattedDate = DateFormat('dd MMM yyyy')
                                    .format(DateTime.parse(absent.absentDate));
                              } catch (_) {
                                formattedDate = absent.absentDate;
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.red.withOpacity(0.08),
                                          radius: 20,
                                          child: Text(
                                            avatarLabel,
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                absent.employeeName,
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                absent.departmentName,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[500],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'ABSENT',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Date: $formattedDate',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        if (absent.designation != null && absent.designation!.isNotEmpty)
                                          Text(
                                            'Designation: ${absent.designation}',
                                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                          ),
                                      ],
                                    ),
                                    if (absent.reason != null && absent.reason!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Reason: ${absent.reason}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
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
