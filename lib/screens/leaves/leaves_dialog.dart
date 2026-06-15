import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/auth/auth_provider.dart';
import '../../providers/leaves/leave_provider.dart';
import '../../providers/attendance/attendance_provider.dart';
import '../../models/leaves/leave_model.dart';
import '../../models/attendance/attendance_model.dart';
import '../../custom_widgets/inkdrop_loader.dart';

class LeavesDialog extends StatefulWidget {
  final LeaveModel? editRecord;

  const LeavesDialog({super.key, this.editRecord});

  @override
  State<LeavesDialog> createState() => _LeavesDialogState();
}

class _LeavesDialogState extends State<LeavesDialog> {
  final _formKey = GlobalKey<FormState>();

  final _leaveIdController = TextEditingController();
  final _dateController = TextEditingController();
  final _codeController = TextEditingController();
  final _designationController = TextEditingController();
  final _fromDateController = TextEditingController();
  final _toDateController = TextEditingController();
  final _daysController = TextEditingController();
  final _reasonController = TextEditingController();

  DepartmentModel? _selectedDepartment;
  EmployeeModel? _selectedEmployee;
  LeaveTypeModel? _selectedLeaveType;

  bool _allowed = true;
  String _pay = 'with_pay';
  String _mode = 'expire';
  String _leaveSource = 'regular';

  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    
    if (widget.editRecord != null) {
      final record = widget.editRecord!;
      _leaveIdController.text = record.leaveId ?? '';
      _dateController.text = record.date ?? '';
      _codeController.text = record.code ?? '';
      _designationController.text = record.designation ?? '';
      _fromDateController.text = record.fromDate ?? '';
      _toDateController.text = record.toDate ?? '';
      _daysController.text = record.days.toInt().toString();
      _reasonController.text = record.reason ?? '';
      _allowed = record.allowed;
      _pay = record.pay;
      _mode = record.mode;
      final isCpl = RegExp(r'cpl|compensatory', caseSensitive: false).hasMatch(record.leaveType);
      _leaveSource = record.leaveSource != null
          ? (record.leaveSource!.toLowerCase() == 'cpl' ? 'cpl' : 'regular')
          : (isCpl ? 'cpl' : 'regular');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final isEmployee = auth.user?.employeeId != null;
      
      final attProvider = Provider.of<AttendanceProvider>(context, listen: false);
      attProvider.fetchDepartments();
      
      final leaveProvider = Provider.of<LeaveProvider>(context, listen: false);
      leaveProvider.fetchLeaveTypes();

      if (isEmployee) {
        setState(() {
          _selectedEmployee = EmployeeModel(
            id: auth.user!.employeeId!,
            name: auth.user!.name.isNotEmpty ? auth.user!.name : auth.user!.username,
            empId: auth.user!.username,
            designationName: auth.user!.roleLabel,
          );
          _codeController.text = auth.user!.username;
          _designationController.text = auth.user!.roleLabel ?? '';
          _allowed = false; // Employees cannot self-approve leaves
        });
      } else {
        if (widget.editRecord != null) {
          final record = widget.editRecord!;
          attProvider.fetchDepartments().then((_) {
            if (!mounted) return;
            final matchedDept = attProvider.departments.firstWhere(
              (d) => d.id == record.departmentId,
              orElse: () => DepartmentModel(id: record.departmentId ?? 0, name: record.departmentName ?? 'Dept'),
            );
            setState(() {
              _selectedDepartment = matchedDept;
            });
            attProvider.fetchEmployeesForDepartment(matchedDept.id).then((_) {
              if (!mounted) return;
              final matchedEmp = attProvider.employees.firstWhere(
                (e) => e.id == record.employeeId,
                orElse: () => EmployeeModel(id: record.employeeId, name: record.employeeName ?? 'Employee'),
              );
              setState(() {
                _selectedEmployee = matchedEmp;
                _codeController.text = matchedEmp.empId ?? '';
                _designationController.text = matchedEmp.designationName ?? '';
              });
            });
          });
        }
      }

      // Pre-select leave type if editing
      if (widget.editRecord != null) {
        final record = widget.editRecord!;
        leaveProvider.fetchLeaveTypes().then((_) {
          if (!mounted) return;
          final matchedType = leaveProvider.leaveTypes.firstWhere(
            (lt) => lt.id == record.leaveTypeId || lt.name.toLowerCase() == record.leaveType.toLowerCase(),
            orElse: () => LeaveTypeModel(id: record.leaveTypeId ?? 0, name: record.leaveType, code: ''),
          );
          setState(() {
            _selectedLeaveType = matchedType;
          });
        });
      }

      // Generate leave ID on new application
      if (widget.editRecord == null) {
        _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
        leaveProvider.fetchNextLeaveId().then((id) {
          if (id != null && mounted) {
            setState(() {
              _leaveIdController.text = id;
            });
          }
        });
      }

      _isInit = false;
    }
  }

  @override
  void dispose() {
    _leaveIdController.dispose();
    _dateController.dispose();
    _codeController.dispose();
    _designationController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    _daysController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _calculateDays() {
    if (_fromDateController.text.isEmpty || _toDateController.text.isEmpty) {
      return;
    }
    try {
      final start = DateTime.parse(_fromDateController.text);
      final end = DateTime.parse(_toDateController.text);
      final diff = end.difference(start).inDays + 1;
      if (diff > 0) {
        _daysController.text = diff.toString();
      } else {
        _daysController.text = '';
      }
    } catch (_) {
      // ignore parse issues
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller, {bool calcDays = false}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF007F70),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
        if (calcDays) {
          _calculateDays();
        }
      });
    }
  }

  void _deleteRecord() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this leave request?'),
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
      final provider = Provider.of<LeaveProvider>(context, listen: false);
      final success = await provider.deleteLeave(widget.editRecord!.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave request deleted successfully'),
            backgroundColor: Color(0xFF007F70),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to delete leave request'),
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
      if (_selectedLeaveType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a leave type'), backgroundColor: Colors.red),
        );
        return;
      }

      final payload = LeaveModel(
        id: widget.editRecord?.id ?? 0,
        leaveId: _leaveIdController.text.trim(),
        date: _dateController.text.trim(),
        code: _codeController.text.trim(),
        departmentId: _selectedDepartment?.id,
        departmentName: _selectedDepartment?.name,
        employeeId: _selectedEmployee!.id,
        employeeName: _selectedEmployee!.name,
        designation: _designationController.text.trim(),
        leaveTypeId: _selectedLeaveType!.id,
        leaveType: _selectedLeaveType!.name,
        fromDate: _fromDateController.text.trim(),
        toDate: _toDateController.text.trim(),
        days: double.tryParse(_daysController.text.trim()) ?? 1.0,
        requestedDays: double.tryParse(_daysController.text.trim()) ?? 1.0,
        reason: _reasonController.text.trim(),
        status: _allowed ? 'approved' : 'pending',
        allowed: _allowed,
        pay: _pay,
        mode: _mode,
        leaveSource: _leaveSource,
      );

      final provider = Provider.of<LeaveProvider>(context, listen: false);
      final isEdit = widget.editRecord != null;

      bool success = isEdit
          ? await provider.updateLeave(widget.editRecord!.id, payload)
          : await provider.createLeave(payload);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Leave request updated' : 'Leave request saved'),
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

  Widget _buildLeaveFromToggle() {
    const tealColor = Color(0xFF007F70);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.list_alt, size: 14, color: Colors.grey),
            SizedBox(width: 6),
            Text(
              'Leave From *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            ),
          ],
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
                  onTap: _selectedEmployee == null
                      ? null
                      : () {
                          setState(() {
                            _leaveSource = 'regular';
                            if (_selectedLeaveType?.code.toUpperCase() == 'CPL') {
                              _selectedLeaveType = null;
                            }
                          });
                        },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _leaveSource == 'regular' ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: _leaveSource == 'regular'
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
                      'Regular',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _leaveSource == 'regular'
                            ? tealColor
                            : (_selectedEmployee == null ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _selectedEmployee == null
                      ? null
                      : () {
                          setState(() {
                            _leaveSource = 'cpl';
                            // Find and preselect CPL leave type
                            final leaveProvider = Provider.of<LeaveProvider>(context, listen: false);
                            try {
                              _selectedLeaveType = leaveProvider.leaveTypes.firstWhere(
                                (lt) => lt.code.toUpperCase() == 'CPL',
                              );
                            } catch (_) {
                              // Fallback if not found
                            }
                          });
                        },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _leaveSource == 'cpl' ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: _leaveSource == 'cpl'
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
                      'CPL',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _leaveSource == 'cpl'
                            ? tealColor
                            : (_selectedEmployee == null ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose regular balance or monthly CPL.',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<LeaveProvider>(context);
    final attProvider = Provider.of<AttendanceProvider>(context);
    const tealColor = Color(0xFF007F70);
    final isEdit = widget.editRecord != null;
    final isEmployee = auth.user?.employeeId != null;
    final isWideDialog = MediaQuery.of(context).size.width > 480;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 480),
          color: Colors.white,
          child: provider.isLoading || attProvider.isLoading
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
                              isEdit ? 'Edit Leave Application' : 'Create Employee Leave',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isEdit && auth.hasPermission('can-delete-leaves')) ...[
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: _deleteRecord,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Delete Request',
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.pop(context),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
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
                              // Card 1: Leave Identity
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
                                            'Leave Identity',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      if (isWideDialog)
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller: _leaveIdController,
                                                decoration: const InputDecoration(
                                                  labelText: 'Leave ID *',
                                                  labelStyle: TextStyle(fontSize: 12),
                                                  hintText: 'Auto generating...',
                                                ),
                                                readOnly: true,
                                                style: const TextStyle(fontSize: 13),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: TextFormField(
                                                controller: _dateController,
                                                decoration: const InputDecoration(
                                                  labelText: 'Date *',
                                                  labelStyle: TextStyle(fontSize: 12),
                                                  suffixIcon: Icon(Icons.calendar_today, size: 16),
                                                ),
                                                readOnly: true,
                                                onTap: () => _selectDate(context, _dateController),
                                                style: const TextStyle(fontSize: 13),
                                                validator: (val) {
                                                  if (val == null || val.trim().isEmpty) return 'Date is required';
                                                  return null;
                                                },
                                              ),
                                            ),
                                          ],
                                        )
                                      else ...[
                                        TextFormField(
                                          controller: _leaveIdController,
                                          decoration: const InputDecoration(
                                            labelText: 'Leave ID *',
                                            labelStyle: TextStyle(fontSize: 12),
                                            hintText: 'Auto generating...',
                                          ),
                                          readOnly: true,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _dateController,
                                          decoration: const InputDecoration(
                                            labelText: 'Date *',
                                            labelStyle: TextStyle(fontSize: 12),
                                            suffixIcon: Icon(Icons.calendar_today, size: 16),
                                          ),
                                          readOnly: true,
                                          onTap: () => _selectDate(context, _dateController),
                                          style: const TextStyle(fontSize: 13),
                                          validator: (val) {
                                            if (val == null || val.trim().isEmpty) return 'Date is required';
                                            return null;
                                          },
                                        ),
                                      ],
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
                                        const SizedBox(height: 16),
                                      ] else ...[
                                        DropdownButtonFormField<DepartmentModel>(
                                          isExpanded: true,
                                          value: attProvider.departments.contains(_selectedDepartment) ? _selectedDepartment : null,
                                          hint: const Text('Select Department', style: TextStyle(fontSize: 13)),
                                          decoration: const InputDecoration(
                                            labelText: 'Department *',
                                            labelStyle: TextStyle(fontSize: 12),
                                          ),
                                          items: attProvider.departments.map((dept) {
                                            return DropdownMenuItem<DepartmentModel>(
                                              value: dept,
                                              child: Text(dept.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            setState(() {
                                              _selectedDepartment = val;
                                              _selectedEmployee = null;
                                              _codeController.text = '';
                                              _designationController.text = '';
                                            });
                                            if (val != null) {
                                              attProvider.fetchEmployeesForDepartment(val.id);
                                            }
                                          },
                                          validator: (val) => val == null ? 'Department is required' : null,
                                        ),
                                        const SizedBox(height: 16),
                                        DropdownButtonFormField<EmployeeModel>(
                                          isExpanded: true,
                                          value: attProvider.employees.contains(_selectedEmployee) ? _selectedEmployee : null,
                                          hint: const Text('Select Employee', style: TextStyle(fontSize: 13)),
                                          decoration: const InputDecoration(
                                            labelText: 'Employee *',
                                            labelStyle: TextStyle(fontSize: 12),
                                          ),
                                          items: attProvider.employees.map((emp) {
                                            return DropdownMenuItem<EmployeeModel>(
                                              value: emp,
                                              child: Text(emp.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            setState(() {
                                              _selectedEmployee = val;
                                              _codeController.text = val?.empId ?? '';
                                              _designationController.text = val?.designationName ?? '';
                                            });
                                          },
                                          validator: (val) => val == null ? 'Employee is required' : null,
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                      if (isWideDialog)
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller: _codeController,
                                                decoration: const InputDecoration(
                                                  labelText: 'Code',
                                                  labelStyle: TextStyle(fontSize: 12),
                                                ),
                                                readOnly: true,
                                                style: const TextStyle(fontSize: 13),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: TextFormField(
                                                controller: _designationController,
                                                decoration: const InputDecoration(
                                                  labelText: 'Designation',
                                                  labelStyle: TextStyle(fontSize: 12),
                                                ),
                                                readOnly: true,
                                                style: const TextStyle(fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        )
                                      else ...[
                                        TextFormField(
                                          controller: _codeController,
                                          decoration: const InputDecoration(
                                            labelText: 'Code',
                                            labelStyle: TextStyle(fontSize: 12),
                                          ),
                                          readOnly: true,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _designationController,
                                          decoration: const InputDecoration(
                                            labelText: 'Designation',
                                            labelStyle: TextStyle(fontSize: 12),
                                          ),
                                          readOnly: true,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Card 2: Leave Details
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
                                      _buildLeaveFromToggle(),
                                      const SizedBox(height: 16),
                                      DropdownButtonFormField<LeaveTypeModel>(
                                        isExpanded: true,
                                        value: _selectedLeaveType != null &&
                                                (_leaveSource == 'cpl' ||
                                                    provider.leaveTypes.where((lt) => lt.code.toUpperCase() != 'CPL').contains(_selectedLeaveType))
                                            ? _selectedLeaveType
                                            : null,
                                        hint: const Text('Select Leave Type', style: TextStyle(fontSize: 13)),
                                        decoration: InputDecoration(
                                          labelText: 'Leave Type *',
                                          labelStyle: const TextStyle(fontSize: 12),
                                          helperText: _leaveSource == 'cpl'
                                              ? 'CPL is selected from weekly holiday attendance balance.'
                                              : 'Leave types are managed from Leave Types module.',
                                          helperStyle: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                        ),
                                        items: _leaveSource == 'cpl'
                                            ? (_selectedLeaveType != null
                                                ? [
                                                    DropdownMenuItem(
                                                      value: _selectedLeaveType,
                                                      child: Text(_selectedLeaveType!.displayText, style: const TextStyle(fontSize: 13)),
                                                    )
                                                  ]
                                                : [])
                                            : provider.leaveTypes.where((lt) => lt.code.toUpperCase() != 'CPL').map((type) {
                                                return DropdownMenuItem<LeaveTypeModel>(
                                                  value: type,
                                                  child: Text(type.displayText, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                                );
                                              }).toList(),
                                        onChanged: _leaveSource == 'cpl'
                                            ? null
                                            : (val) {
                                                setState(() {
                                                  _selectedLeaveType = val;
                                                });
                                              },
                                        validator: (val) => val == null ? 'Leave type is required' : null,
                                      ),
                                      const SizedBox(height: 16),
                                      if (isWideDialog)
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller: _fromDateController,
                                                decoration: const InputDecoration(
                                                  labelText: 'From *',
                                                  labelStyle: TextStyle(fontSize: 12),
                                                  suffixIcon: Icon(Icons.date_range, size: 16),
                                                ),
                                                readOnly: true,
                                                onTap: () => _selectDate(context, _fromDateController, calcDays: true),
                                                style: const TextStyle(fontSize: 13),
                                                validator: (val) {
                                                  if (val == null || val.trim().isEmpty) return 'Required';
                                                  return null;
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextFormField(
                                                controller: _toDateController,
                                                decoration: const InputDecoration(
                                                  labelText: 'To *',
                                                  labelStyle: TextStyle(fontSize: 12),
                                                  suffixIcon: Icon(Icons.date_range, size: 16),
                                                ),
                                                readOnly: true,
                                                onTap: () => _selectDate(context, _toDateController, calcDays: true),
                                                style: const TextStyle(fontSize: 13),
                                                validator: (val) {
                                                  if (val == null || val.trim().isEmpty) return 'Required';
                                                  return null;
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextFormField(
                                                controller: _daysController,
                                                decoration: const InputDecoration(
                                                  labelText: 'Days *',
                                                  labelStyle: TextStyle(fontSize: 12),
                                                ),
                                                keyboardType: TextInputType.number,
                                                style: const TextStyle(fontSize: 13),
                                                validator: (val) {
                                                  if (val == null || val.trim().isEmpty) return 'Required';
                                                  final parsed = double.tryParse(val);
                                                  if (parsed == null || parsed <= 0) return 'Invalid';
                                                  return null;
                                                },
                                              ),
                                            ),
                                          ],
                                        )
                                      else ...[
                                        TextFormField(
                                          controller: _fromDateController,
                                          decoration: const InputDecoration(
                                            labelText: 'From *',
                                            labelStyle: TextStyle(fontSize: 12),
                                            suffixIcon: Icon(Icons.date_range, size: 16),
                                          ),
                                          readOnly: true,
                                          onTap: () => _selectDate(context, _fromDateController, calcDays: true),
                                          style: const TextStyle(fontSize: 13),
                                          validator: (val) {
                                            if (val == null || val.trim().isEmpty) return 'Required';
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _toDateController,
                                          decoration: const InputDecoration(
                                            labelText: 'To *',
                                            labelStyle: TextStyle(fontSize: 12),
                                            suffixIcon: Icon(Icons.date_range, size: 16),
                                          ),
                                          readOnly: true,
                                          onTap: () => _selectDate(context, _toDateController, calcDays: true),
                                          style: const TextStyle(fontSize: 13),
                                          validator: (val) {
                                            if (val == null || val.trim().isEmpty) return 'Required';
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _daysController,
                                          decoration: const InputDecoration(
                                            labelText: 'Days *',
                                            labelStyle: TextStyle(fontSize: 12),
                                          ),
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(fontSize: 13),
                                          validator: (val) {
                                            if (val == null || val.trim().isEmpty) return 'Required';
                                            final parsed = double.tryParse(val);
                                            if (parsed == null || parsed <= 0) return 'Invalid';
                                            return null;
                                          },
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _reasonController,
                                        decoration: const InputDecoration(
                                          labelText: 'Reason',
                                          labelStyle: TextStyle(fontSize: 12),
                                          hintText: 'Write leave reason...',
                                        ),
                                        maxLines: 3,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      // Actions at bottom
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
                                isEdit ? 'Update Leave' : 'Submit Leave Request',
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
