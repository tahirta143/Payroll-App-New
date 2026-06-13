import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/auth/auth_provider.dart';
import '../../providers/leaves/short_leave_provider.dart';
import '../../models/leaves/short_leave_model.dart';
import '../../models/attendance/attendance_model.dart';
import '../../custom_widgets/inkdrop_loader.dart';

class ShortLeavesDialog extends StatefulWidget {
  final ShortLeaveModel? editRecord;

  const ShortLeavesDialog({super.key, this.editRecord});

  @override
  State<ShortLeavesDialog> createState() => _ShortLeavesDialogState();
}

class _ShortLeavesDialogState extends State<ShortLeavesDialog> {
  final _formKey = GlobalKey<FormState>();

  final _leaveDateController = TextEditingController();
  final _fromTimeController = TextEditingController();
  final _toTimeController = TextEditingController();
  final _leaveTypeController = TextEditingController();
  final _reasonController = TextEditingController();

  EmployeeModel? _selectedEmployee;
  TimeOfDay? _fromTime;
  TimeOfDay? _toTime;
  int _totalMinutes = 0;
  bool _isPaid = true;
  String _status = 'pending';
  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    _leaveDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (widget.editRecord != null) {
      final record = widget.editRecord!;
      _leaveDateController.text = record.leaveDate;
      _leaveTypeController.text = record.leaveType;
      _reasonController.text = record.reason ?? '';
      _isPaid = record.isPaid;
      _status = record.status;
      _totalMinutes = record.totalMinutes;

      try {
        final fromParts = record.fromTime.split(':');
        _fromTime = TimeOfDay(hour: int.parse(fromParts[0]), minute: int.parse(fromParts[1]));
        _fromTimeController.text = _formatTimeOfDayToShow(_fromTime!);
      } catch (_) {}

      try {
        final toParts = record.toTime.split(':');
        _toTime = TimeOfDay(hour: int.parse(toParts[0]), minute: int.parse(toParts[1]));
        _toTimeController.text = _formatTimeOfDayToShow(_toTime!);
      } catch (_) {}
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final isEmployee = auth.user?.employeeId != null;
      final provider = Provider.of<ShortLeaveProvider>(context, listen: false);

      provider.fetchEmployees();

      if (isEmployee) {
        setState(() {
          _selectedEmployee = EmployeeModel(
            id: auth.user!.employeeId!,
            name: auth.user!.name.isNotEmpty ? auth.user!.name : auth.user!.username,
            empId: auth.user!.username,
            designationName: auth.user!.roleLabel,
          );
        });
      } else {
        if (widget.editRecord != null) {
          final record = widget.editRecord!;
          provider.fetchEmployees().then((_) {
            if (!mounted) return;
            final matched = provider.employees.firstWhere(
              (e) => e.id == record.employeeId,
              orElse: () => EmployeeModel(id: record.employeeId, name: record.employeeName ?? 'Employee'),
            );
            setState(() {
              _selectedEmployee = matched;
            });
          });
        }
      }
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _leaveDateController.dispose();
    _fromTimeController.dispose();
    _toTimeController.dispose();
    _leaveTypeController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  int _timeToMinutes(TimeOfDay? time) {
    if (time == null) return 0;
    return time.hour * 60 + time.minute;
  }

  void _calculateDuration() {
    if (_fromTime != null && _toTime != null) {
      final fromMin = _timeToMinutes(_fromTime);
      final toMin = _timeToMinutes(_toTime);
      final diff = toMin - fromMin;
      setState(() {
        _totalMinutes = diff > 0 ? diff : 0;
      });
    } else {
      setState(() {
        _totalMinutes = 0;
      });
    }
  }

  String _fmtMinutes(int mins) {
    if (mins <= 0) return '0m';
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  String _formatTimeOfDayToShow(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return DateFormat('hh:mm A').format(dt);
  }

  String _formatTimeOfDayToApi(TimeOfDay tod) {
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
        _leaveDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isFrom) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isFrom ? (_fromTime ?? const TimeOfDay(hour: 9, minute: 0)) : (_toTime ?? const TimeOfDay(hour: 17, minute: 0)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF007F70)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromTime = picked;
          _fromTimeController.text = _formatTimeOfDayToShow(picked);
        } else {
          _toTime = picked;
          _toTimeController.text = _formatTimeOfDayToShow(picked);
        }
        _calculateDuration();
      });
    }
  }

  void _deleteRecord() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this short leave record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final provider = Provider.of<ShortLeaveProvider>(context, listen: false);
      final success = await provider.deleteShortLeave(widget.editRecord!.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Short leave record deleted successfully'),
            backgroundColor: Color(0xFF007F70),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to delete short leave record'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedEmployee == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an employee'), backgroundColor: Colors.red),
        );
        return;
      }
      if (_fromTime == null || _toTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select from and to times'), backgroundColor: Colors.red),
        );
        return;
      }
      if (_totalMinutes <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('To time must be after from time'), backgroundColor: Colors.red),
        );
        return;
      }

      final payload = ShortLeaveModel(
        id: widget.editRecord?.id ?? 0,
        employeeId: _selectedEmployee!.id,
        employeeName: _selectedEmployee!.name,
        leaveDate: _leaveDateController.text.trim(),
        fromTime: _formatTimeOfDayToApi(_fromTime!),
        toTime: _formatTimeOfDayToApi(_toTime!),
        totalMinutes: _totalMinutes,
        leaveType: _leaveTypeController.text.trim(),
        reason: _reasonController.text.trim().isNotEmpty ? _reasonController.text.trim() : null,
        isPaid: _isPaid,
        status: _status,
      );

      final provider = Provider.of<ShortLeaveProvider>(context, listen: false);
      final isEdit = widget.editRecord != null;

      bool success = isEdit
          ? await provider.updateShortLeave(widget.editRecord!.id, payload)
          : await provider.createShortLeave(payload);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Short leave updated' : 'Short leave request saved'),
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
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<ShortLeaveProvider>(context);
    const tealColor = Color(0xFF007F70);
    final isEdit = widget.editRecord != null;
    final isEmployee = auth.user?.employeeId != null;

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
                              isEdit ? 'Edit Short Leave' : 'Create Short Leave',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
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
                      // Form
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Identity Card
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
                                      const Row(
                                        children: [
                                          Icon(Icons.badge_outlined, size: 16, color: tealColor),
                                          SizedBox(width: 8),
                                          Text(
                                            'Employee & Date',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      if (isEmployee) ...[
                                        TextFormField(
                                          initialValue: _selectedEmployee?.name ?? '',
                                          decoration: const InputDecoration(
                                            labelText: 'Employee Name',
                                            labelStyle: TextStyle(fontSize: 12),
                                          ),
                                          enabled: false,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ] else ...[
                                        DropdownButtonFormField<EmployeeModel>(
                                          isExpanded: true,
                                          value: provider.employees.contains(_selectedEmployee) ? _selectedEmployee : null,
                                          hint: const Text('Select Employee', style: TextStyle(fontSize: 13)),
                                          decoration: const InputDecoration(
                                            labelText: 'Employee *',
                                            labelStyle: TextStyle(fontSize: 12),
                                          ),
                                          items: provider.employees.map((emp) {
                                            return DropdownMenuItem<EmployeeModel>(
                                              value: emp,
                                              child: Text(emp.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            setState(() {
                                              _selectedEmployee = val;
                                            });
                                          },
                                          validator: (val) => val == null ? 'Employee is required' : null,
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _leaveDateController,
                                        decoration: const InputDecoration(
                                          labelText: 'Leave Date *',
                                          labelStyle: TextStyle(fontSize: 12),
                                          suffixIcon: Icon(Icons.calendar_today, size: 16),
                                        ),
                                        readOnly: true,
                                        onTap: () => _selectDate(context),
                                        style: const TextStyle(fontSize: 13),
                                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Date is required' : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Time Range Card
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
                                      const Row(
                                        children: [
                                          Icon(Icons.alarm_on_outlined, size: 16, color: tealColor),
                                          SizedBox(width: 8),
                                          Text(
                                            'Time Range',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: _fromTimeController,
                                              decoration: const InputDecoration(
                                                labelText: 'From Time *',
                                                labelStyle: TextStyle(fontSize: 12),
                                                suffixIcon: Icon(Icons.access_time, size: 16),
                                              ),
                                              readOnly: true,
                                              onTap: () => _selectTime(context, true),
                                              style: const TextStyle(fontSize: 13),
                                              validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: TextFormField(
                                              controller: _toTimeController,
                                              decoration: const InputDecoration(
                                                labelText: 'To Time *',
                                                labelStyle: TextStyle(fontSize: 12),
                                                suffixIcon: Icon(Icons.access_time, size: 16),
                                              ),
                                              readOnly: true,
                                              onTap: () => _selectTime(context, false),
                                              style: const TextStyle(fontSize: 13),
                                              validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_fromTime != null && _toTime != null) ...[
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: _totalMinutes > 0 ? tealColor.withOpacity(0.08) : Colors.red[50],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.schedule,
                                                size: 16,
                                                color: _totalMinutes > 0 ? tealColor : Colors.red,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _totalMinutes > 0
                                                    ? 'Duration: ${_fmtMinutes(_totalMinutes)}'
                                                    : 'Invalid range (To time must be after From time)',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: _totalMinutes > 0 ? tealColor : Colors.red,
                                                ),
                                              ),
                                              if (_totalMinutes > 0) ...[
                                                const Spacer(),
                                                Text(
                                                  '$_totalMinutes mins',
                                                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Details Card
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
                                      const Row(
                                        children: [
                                          Icon(Icons.notes, size: 16, color: tealColor),
                                          SizedBox(width: 8),
                                          Text(
                                            'Leave Details',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _leaveTypeController,
                                        decoration: const InputDecoration(
                                          labelText: 'Leave Type *',
                                          labelStyle: TextStyle(fontSize: 12),
                                          hintText: 'e.g. Personal, Medical',
                                        ),
                                        style: const TextStyle(fontSize: 13),
                                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Leave type is required' : null,
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _reasonController,
                                        decoration: const InputDecoration(
                                          labelText: 'Reason',
                                          labelStyle: TextStyle(fontSize: 12),
                                          hintText: 'Optional leave reason...',
                                        ),
                                        maxLines: 2,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Pay & Status Card
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
                                      const Row(
                                        children: [
                                          Icon(Icons.monetization_on_outlined, size: 16, color: tealColor),
                                          SizedBox(width: 8),
                                          Text(
                                            'Pay & Status',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Pay Type',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        height: 40,
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[200]!),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _isPaid = true;
                                                  });
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: _isPaid ? Colors.white : Colors.transparent,
                                                    borderRadius: BorderRadius.circular(6),
                                                    boxShadow: _isPaid
                                                        ? [
                                                            BoxShadow(
                                                              color: Colors.black.withOpacity(0.05),
                                                              blurRadius: 2,
                                                              offset: const Offset(0, 1),
                                                            )
                                                          ]
                                                        : null,
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    'Paid',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                      color: _isPaid ? tealColor : Colors.grey[600],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _isPaid = false;
                                                  });
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: !_isPaid ? Colors.white : Colors.transparent,
                                                    borderRadius: BorderRadius.circular(6),
                                                    boxShadow: !_isPaid
                                                        ? [
                                                            BoxShadow(
                                                              color: Colors.black.withOpacity(0.05),
                                                              blurRadius: 2,
                                                              offset: const Offset(0, 1),
                                                            )
                                                          ]
                                                        : null,
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    'Unpaid',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                      color: !_isPaid ? tealColor : Colors.grey[600],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!isEmployee) ...[
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Status',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                                        ),
                                        DropdownButtonFormField<String>(
                                          value: _status,
                                          items: const [
                                            DropdownMenuItem(value: 'pending', child: Text('Pending', style: TextStyle(fontSize: 13))),
                                            DropdownMenuItem(value: 'approved', child: Text('Approved', style: TextStyle(fontSize: 13))),
                                            DropdownMenuItem(value: 'rejected', child: Text('Rejected', style: TextStyle(fontSize: 13))),
                                          ],
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() {
                                                _status = val;
                                              });
                                            }
                                          },
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
                      // Actions
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            if (isEdit && auth.hasPermission('can-delete-short-leaves'))
                              TextButton.icon(
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                onPressed: _deleteRecord,
                                icon: const Icon(Icons.delete_outline, size: 18),
                                label: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            const Spacer(),
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
                                isEdit ? 'Update Leave' : 'Submit Leave',
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
