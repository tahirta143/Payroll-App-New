import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/attendance/attendance_provider.dart';
import '../../models/attendance/attendance_model.dart';
import '../../custom_widgets/inkdrop_loader.dart';

class AttendanceDialog extends StatefulWidget {
  final AttendanceModel? editRecord;

  const AttendanceDialog({super.key, this.editRecord});

  @override
  State<AttendanceDialog> createState() => _AttendanceDialogState();
}

class _AttendanceDialogState extends State<AttendanceDialog> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  DepartmentModel? _selectedDepartment;
  EmployeeModel? _selectedEmployee;
  
  String _machineCode = '';
  String _dutyShiftText = '';
  int? _dutyShiftId;

  bool _hasTimeIn = true;
  TimeOfDay _timeIn = const TimeOfDay(hour: 9, minute: 0);
  
  bool _hasTimeOut = false;
  TimeOfDay _timeOut = const TimeOfDay(hour: 17, minute: 0);

  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    
    // Load initial dropdowns
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    provider.fetchDepartments();

    if (widget.editRecord != null) {
      final record = widget.editRecord!;
      _selectedDate = DateTime.tryParse(record.date) ?? DateTime.now();
      _machineCode = record.machineCode ?? '';
      _dutyShiftText = record.dutyShiftName ?? '';
      _dutyShiftId = record.dutyShiftId;
      
      _hasTimeIn = record.timeIn != null;
      if (_hasTimeIn) {
        final parts = record.timeIn!.split(':');
        _timeIn = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }

      _hasTimeOut = record.timeOut != null;
      if (_hasTimeOut) {
        final parts = record.timeOut!.split(':');
        _timeOut = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit && widget.editRecord != null) {
      final record = widget.editRecord!;
      final provider = Provider.of<AttendanceProvider>(context, listen: false);
      
      // Wait for departments to load, then match department
      provider.fetchDepartments().then((_) {
        if (!mounted) return;
        final matchedDept = provider.departments.firstWhere(
          (d) => d.id == record.departmentId,
          orElse: () => DepartmentModel(id: record.departmentId, name: record.departmentName ?? 'Dept'),
        );
        setState(() {
          _selectedDepartment = matchedDept;
        });

        // Load employees for this department, then match employee
        provider.fetchEmployeesForDepartment(matchedDept.id).then((_) {
          if (!mounted) return;
          final matchedEmp = provider.employees.firstWhere(
            (e) => e.id == record.employeeId,
            orElse: () => EmployeeModel(id: record.employeeId, name: record.employeeName ?? 'Employee'),
          );
          setState(() {
            _selectedEmployee = matchedEmp;
          });
        });
      });
      _isInit = false;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF007F70)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(bool isTimeIn) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isTimeIn ? _timeIn : _timeOut,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF007F70)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isTimeIn) {
          _timeIn = picked;
        } else {
          _timeOut = picked;
        }
      });
    }
  }

  void _onDepartmentChanged(DepartmentModel? dept) {
    setState(() {
      _selectedDepartment = dept;
      _selectedEmployee = null;
      _machineCode = '';
      _dutyShiftText = '';
      _dutyShiftId = null;
    });

    if (dept != null) {
      Provider.of<AttendanceProvider>(context, listen: false)
          .fetchEmployeesForDepartment(dept.id);
    }
  }

  void _onEmployeeChanged(EmployeeModel? emp) {
    setState(() {
      _selectedEmployee = emp;
      if (emp != null) {
        _machineCode = emp.machineCode ?? '';
        _dutyShiftId = emp.dutyShift?.id;
        _dutyShiftText = emp.dutyShift?.displayText ?? '';
      } else {
        _machineCode = '';
        _dutyShiftId = null;
        _dutyShiftText = '';
      }
    });
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDepartment == null || _selectedEmployee == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select department and employee'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (!_hasTimeIn && !_hasTimeOut) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable Time In and/or Time Out'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final timeInStr = _hasTimeIn ? _formatTimeOfDay(_timeIn) : null;
      final timeOutStr = _hasTimeOut ? _formatTimeOfDay(_timeOut) : null;

      final provider = Provider.of<AttendanceProvider>(context, listen: false);
      final isEdit = widget.editRecord != null;
      
      bool success;
      if (isEdit) {
        success = await provider.updateAttendance(
          id: widget.editRecord!.id,
          date: dateStr,
          departmentId: _selectedDepartment!.id,
          employeeId: _selectedEmployee!.id,
          dutyShiftId: _dutyShiftId,
          machineCode: _machineCode.isNotEmpty ? _machineCode : null,
          dutyShiftText: _dutyShiftText.isNotEmpty ? _dutyShiftText : null,
          timeIn: timeInStr,
          timeOut: timeOutStr,
        );
      } else {
        success = await provider.createAttendance(
          date: dateStr,
          departmentId: _selectedDepartment!.id,
          employeeId: _selectedEmployee!.id,
          dutyShiftId: _dutyShiftId,
          machineCode: _machineCode.isNotEmpty ? _machineCode : null,
          dutyShiftText: _dutyShiftText.isNotEmpty ? _dutyShiftText : null,
          timeIn: timeInStr,
          timeOut: timeOutStr,
        );
      }

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Attendance updated' : 'Attendance saved'),
            backgroundColor: const Color(0xFF007F70),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'An error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context);
    const tealColor = Color(0xFF007F70);
    final isEdit = widget.editRecord != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 480),
          color: Colors.white,
          child: provider.isLoading
              ? const SizedBox(
                  height: 300,
                  child: Center(child: InkDropLoader()),
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isEdit ? 'Edit Attendance' : 'Mark Attendance',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Scrollable form
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Form fields card
                              Container(
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
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const Text(
                                        'Attendance Logs',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: tealColor),
                                      ),
                                      const SizedBox(height: 16),
                                      // Date
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text('Date *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                        subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate), style: const TextStyle(fontSize: 14, color: Colors.black)),
                                        trailing: const Icon(Icons.calendar_today, size: 18, color: tealColor),
                                        onTap: _selectDate,
                                      ),
                                      const Divider(),

                                      // Department
                                      const SizedBox(height: 8),
                                      const Text('Department *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                      DropdownButtonFormField<DepartmentModel>(
                                        isExpanded: true,
                                        value: provider.departments.contains(_selectedDepartment) ? _selectedDepartment : null,
                                        hint: const Text('Select department', style: TextStyle(fontSize: 13)),
                                        items: provider.departments.map((dept) {
                                          return DropdownMenuItem<DepartmentModel>(
                                            value: dept,
                                            child: Text(
                                              dept.name,
                                              style: const TextStyle(fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: _onDepartmentChanged,
                                      ),
                                      const SizedBox(height: 16),

                                      // Employee
                                      const Text('Employee *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                      DropdownButtonFormField<EmployeeModel>(
                                        isExpanded: true,
                                        value: provider.employees.contains(_selectedEmployee) ? _selectedEmployee : null,
                                        hint: const Text('Select employee', style: TextStyle(fontSize: 13)),
                                        disabledHint: const Text('Select department first', style: TextStyle(fontSize: 13)),
                                        items: provider.employees.map((emp) {
                                          return DropdownMenuItem<EmployeeModel>(
                                            value: emp,
                                            child: Text(
                                              emp.name,
                                              style: const TextStyle(fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: _selectedDepartment == null ? null : _onEmployeeChanged,
                                      ),
                                      const SizedBox(height: 16),

                                      // Machine Code
                                      TextFormField(
                                        controller: TextEditingController(text: _machineCode),
                                        decoration: const InputDecoration(
                                          labelText: 'Machine Code',
                                          labelStyle: TextStyle(fontSize: 12),
                                          helperText: 'Auto-filled from employee',
                                        ),
                                        enabled: false,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(height: 16),

                                      // Duty Shift
                                      TextFormField(
                                        controller: TextEditingController(text: _dutyShiftText),
                                        decoration: const InputDecoration(
                                          labelText: 'Duty Shift',
                                          labelStyle: TextStyle(fontSize: 12),
                                          helperText: 'Auto-filled from employee',
                                        ),
                                        enabled: false,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Time entry card
                              Container(
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
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const Text(
                                        'Time Entry',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: tealColor),
                                      ),
                                      const SizedBox(height: 16),

                                      // Time In
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Time In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                              Text('Set arrival time', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                                            ],
                                          ),
                                          Switch.adaptive(
                                            activeColor: tealColor,
                                            value: _hasTimeIn,
                                            onChanged: (val) => setState(() => _hasTimeIn = val),
                                          ),
                                        ],
                                      ),
                                      if (_hasTimeIn) ...[
                                        const SizedBox(height: 8),
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: Colors.grey[200]!),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            foregroundColor: Colors.grey[800],
                                          ),
                                          onPressed: () => _selectTime(true),
                                          icon: const Icon(Icons.access_time, size: 16, color: tealColor),
                                          label: Text(_timeIn.format(context), style: const TextStyle(fontSize: 13)),
                                        ),
                                      ],
                                      const Divider(height: 24),

                                      // Time Out
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Time Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                              Text('Set departure time', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                                            ],
                                          ),
                                          Switch.adaptive(
                                            activeColor: tealColor,
                                            value: _hasTimeOut,
                                            onChanged: (val) => setState(() => _hasTimeOut = val),
                                          ),
                                        ],
                                      ),
                                      if (_hasTimeOut) ...[
                                        const SizedBox(height: 8),
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: Colors.grey[200]!),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            foregroundColor: Colors.grey[800],
                                          ),
                                          onPressed: () => _selectTime(false),
                                          icon: const Icon(Icons.access_time, size: 16, color: tealColor),
                                          label: Text(_timeOut.format(context), style: const TextStyle(fontSize: 13)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      // Actions at the bottom
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tealColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              onPressed: _submit,
                              child: Text(
                                isEdit ? 'Update Record' : 'Save Record',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
