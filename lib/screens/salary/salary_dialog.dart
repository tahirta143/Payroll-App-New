import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/salary/salary_provider.dart';
import '../../providers/auth/auth_provider.dart';
import '../../models/salary/salary_model.dart';
import '../../models/attendance/attendance_model.dart';
import '../../custom_widgets/inkdrop_loader.dart';

class SalaryDialog extends StatefulWidget {
  final SalaryModel? editRecord;

  const SalaryDialog({super.key, this.editRecord});

  @override
  State<SalaryDialog> createState() => _SalaryDialogState();
}

class _SalaryDialogState extends State<SalaryDialog> {
  final _formKey = GlobalKey<FormState>();

  EmployeeModel? _selectedEmployee;

  // Controllers for allowances (required for real-time calculations)
  final _basicController = TextEditingController(text: '');
  final _medicalController = TextEditingController(text: '');
  final _mobileController = TextEditingController(text: '');
  final _conveyanceController = TextEditingController(text: '');
  final _houseController = TextEditingController(text: '');
  final _utilityController = TextEditingController(text: '');
  final _miscController = TextEditingController(text: '');

  final _taxController = TextEditingController(text: '');
  bool _noTax = false;

  bool _salaryByCash = true;
  bool _salaryByCheque = false;
  bool _salaryByTransfer = false;
  final _accountController = TextEditingController(text: '');

  bool _allowOvertime = false;
  bool _lateComingDeduction = false;

  final _appointmentSalaryController = TextEditingController(text: '');
  final _incrementAmountController = TextEditingController(text: '');
  DateTime? _lastIncrementDate;

  double _grossSalary = 0.0;
  double _netSalary = 0.0;

  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    
    // Setup listeners for real-time calculations
    _basicController.addListener(_calculateTotals);
    _medicalController.addListener(_calculateTotals);
    _mobileController.addListener(_calculateTotals);
    _conveyanceController.addListener(_calculateTotals);
    _houseController.addListener(_calculateTotals);
    _utilityController.addListener(_calculateTotals);
    _miscController.addListener(_calculateTotals);
    _taxController.addListener(_calculateTotals);

    // Load employees
    final provider = Provider.of<SalaryProvider>(context, listen: false);
    provider.fetchEmployees();

    if (widget.editRecord != null) {
      final record = widget.editRecord!;
      _basicController.text = record.basicSalary.toStringAsFixed(2);
      _medicalController.text = record.medicalAllowance.toStringAsFixed(2);
      _mobileController.text = record.mobileAllowance.toStringAsFixed(2);
      _conveyanceController.text = record.conveyanceAllowance.toStringAsFixed(2);
      _houseController.text = record.houseAllowance.toStringAsFixed(2);
      _utilityController.text = record.utilityAllowance.toStringAsFixed(2);
      _miscController.text = record.miscellaneousAllowance.toStringAsFixed(2);

      _taxController.text = record.incomeTax.toStringAsFixed(2);
      _noTax = record.noTax;

      _salaryByCash = record.salaryByCash;
      _salaryByCheque = record.salaryByCheque;
      _salaryByTransfer = record.salaryByTransfer;
      _accountController.text = record.accountNumber ?? '';

      _allowOvertime = record.allowOvertime;
      _lateComingDeduction = record.lateComingDeduction;

      _appointmentSalaryController.text = record.salaryAtAppointment?.toStringAsFixed(2) ?? '';
      _incrementAmountController.text = record.incrementAmount?.toStringAsFixed(2) ?? '';
      _lastIncrementDate = record.lastIncrementDate != null
          ? DateTime.tryParse(record.lastIncrementDate!)
          : null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit && widget.editRecord != null) {
      final provider = Provider.of<SalaryProvider>(context, listen: false);
      provider.fetchEmployees().then((_) {
        if (!mounted) return;
        final matchedEmp = provider.employees.firstWhere(
          (e) => e.id == widget.editRecord!.employeeId,
          orElse: () => EmployeeModel(id: widget.editRecord!.employeeId, name: widget.editRecord!.employeeName ?? 'Employee'),
        );
        setState(() {
          _selectedEmployee = matchedEmp;
        });
      });
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _basicController.dispose();
    _medicalController.dispose();
    _mobileController.dispose();
    _conveyanceController.dispose();
    _houseController.dispose();
    _utilityController.dispose();
    _miscController.dispose();
    _taxController.dispose();
    _accountController.dispose();
    _appointmentSalaryController.dispose();
    _incrementAmountController.dispose();
    super.dispose();
  }

  void _calculateTotals() {
    double parse(String text) => double.tryParse(text) ?? 0.0;

    final basic = parse(_basicController.text);
    final med = parse(_medicalController.text);
    final mob = parse(_mobileController.text);
    final conv = parse(_conveyanceController.text);
    final house = parse(_houseController.text);
    final util = parse(_utilityController.text);
    final misc = parse(_miscController.text);
    final tax = parse(_taxController.text);

    final gross = basic + med + mob + conv + house + util + misc;
    final net = gross - (_noTax ? 0.0 : tax);

    setState(() {
      _grossSalary = gross;
      _netSalary = net;
    });
  }

  Future<void> _selectIncrementDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _lastIncrementDate ?? DateTime.now(),
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
        _lastIncrementDate = picked;
      });
    }
  }

  void _onEmployeeChanged(EmployeeModel? emp) {
    setState(() {
      _selectedEmployee = emp;
      if (emp != null && _salaryByTransfer) {
        _accountController.text = emp.bankAccountNumber ?? '';
      }
    });
  }

  void _deleteRecord() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this salary configuration?'),
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
      final provider = Provider.of<SalaryProvider>(context, listen: false);
      final success = await provider.deleteSalary(widget.editRecord!.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salary configuration deleted successfully'),
            backgroundColor: Color(0xFF007F70),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to delete salary configuration'),
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
          const SnackBar(
            content: Text('Please select an employee'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_salaryByTransfer && _accountController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account number is required for bank transfer'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      double parse(String text) => double.tryParse(text) ?? 0.0;
      final dateStr = _lastIncrementDate != null
          ? DateFormat('yyyy-MM-dd').format(_lastIncrementDate!)
          : null;

      final payload = SalaryModel(
        id: widget.editRecord?.id ?? 0,
        employeeId: _selectedEmployee!.id,
        basicSalary: parse(_basicController.text),
        medicalAllowance: parse(_medicalController.text),
        mobileAllowance: parse(_mobileController.text),
        conveyanceAllowance: parse(_conveyanceController.text),
        houseAllowance: parse(_houseController.text),
        utilityAllowance: parse(_utilityController.text),
        miscellaneousAllowance: parse(_miscController.text),
        incomeTax: _noTax ? 0.0 : parse(_taxController.text),
        noTax: _noTax,
        salaryByCash: _salaryByCash,
        salaryByCheque: _salaryByCheque,
        salaryByTransfer: _salaryByTransfer,
        accountNumber: _salaryByTransfer ? _accountController.text.trim() : null,
        allowOvertime: _allowOvertime,
        lateComingDeduction: _lateComingDeduction,
        salaryAtAppointment: _appointmentSalaryController.text.isNotEmpty
            ? parse(_appointmentSalaryController.text)
            : null,
        lastIncrementDate: dateStr,
        incrementAmount: _incrementAmountController.text.isNotEmpty
            ? parse(_incrementAmountController.text)
            : null,
        grossSalary: _grossSalary,
        netSalary: _netSalary,
      );

      final provider = Provider.of<SalaryProvider>(context, listen: false);
      final isEdit = widget.editRecord != null;

      bool success = isEdit
          ? await provider.updateSalary(widget.editRecord!.id, payload)
          : await provider.createSalary(payload);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Salary updated' : 'Salary record saved'),
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
    final provider = Provider.of<SalaryProvider>(context);
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
                              isEdit ? 'Edit Salary Setup' : 'New Salary Setup',
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
                              // Employee Details Card
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
                                        'Employee Details',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: tealColor),
                                      ),
                                      const SizedBox(height: 16),
                                      DropdownButtonFormField<EmployeeModel>(
                                        isExpanded: true,
                                        value: provider.employees.contains(_selectedEmployee) ? _selectedEmployee : null,
                                        hint: const Text('Select employee', style: TextStyle(fontSize: 13)),
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
                                        onChanged: _onEmployeeChanged,
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _basicController,
                                        decoration: const InputDecoration(
                                          labelText: 'Basic Salary *',
                                          labelStyle: TextStyle(fontSize: 12),
                                          prefixText: 'Rs ',
                                        ),
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(fontSize: 13),
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Basic salary is required';
                                          if (double.tryParse(val) == null) return 'Enter a valid amount';
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Allowances Card
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
                                        'Allowances',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: tealColor),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildNumberField(_medicalController, 'Medical Allowance'),
                                      _buildNumberField(_mobileController, 'Mobile Allowance'),
                                      _buildNumberField(_conveyanceController, 'Conveyance Allowance'),
                                      _buildNumberField(_houseController, 'House Allowance'),
                                      _buildNumberField(_utilityController, 'Utility Allowance'),
                                      _buildNumberField(_miscController, 'Miscellaneous Allowance'),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Increments details Card
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
                                        'Increment Details',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: tealColor),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildNumberField(_appointmentSalaryController, 'Salary at Appointment'),
                                      _buildNumberField(_incrementAmountController, 'Increment Amount'),
                                      const SizedBox(height: 8),
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text('Last Increment Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                        subtitle: Text(
                                            _lastIncrementDate != null
                                                ? DateFormat('yyyy-MM-dd').format(_lastIncrementDate!)
                                                : 'Not Set',
                                            style: const TextStyle(fontSize: 13)),
                                        trailing: const Icon(Icons.calendar_today, size: 16, color: tealColor),
                                        onTap: _selectIncrementDate,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Totals / Tax Card
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
                                        'Salary Summary & Tax',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: tealColor),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Gross Salary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          Text('Rs ${_grossSalary.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      SwitchListTile.adaptive(
                                        contentPadding: EdgeInsets.zero,
                                        activeColor: tealColor,
                                        title: const Text('No Tax on Salary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        value: _noTax,
                                        onChanged: (val) {
                                          setState(() {
                                            _noTax = val;
                                          });
                                          _calculateTotals();
                                        },
                                      ),
                                      if (!_noTax) ...[
                                        TextFormField(
                                          controller: _taxController,
                                          decoration: const InputDecoration(
                                            labelText: 'Income Tax',
                                            labelStyle: TextStyle(fontSize: 12),
                                            prefixText: 'Rs ',
                                          ),
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                      const Divider(height: 24),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Net Salary', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                          Text(
                                            'Rs ${_netSalary.toStringAsFixed(2)}',
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tealColor),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Payment Mode Card
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
                                        'Payment Mode',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: tealColor),
                                      ),
                                      const SizedBox(height: 8),
                                      SwitchListTile.adaptive(
                                        contentPadding: EdgeInsets.zero,
                                        activeColor: tealColor,
                                        title: const Text('Pay by Cash', style: TextStyle(fontSize: 12)),
                                        value: _salaryByCash,
                                        onChanged: (val) => setState(() => _salaryByCash = val),
                                      ),
                                      SwitchListTile.adaptive(
                                        contentPadding: EdgeInsets.zero,
                                        activeColor: tealColor,
                                        title: const Text('Pay by Cheque', style: TextStyle(fontSize: 12)),
                                        value: _salaryByCheque,
                                        onChanged: (val) => setState(() => _salaryByCheque = val),
                                      ),
                                      SwitchListTile.adaptive(
                                        contentPadding: EdgeInsets.zero,
                                        activeColor: tealColor,
                                        title: const Text('Bank Transfer', style: TextStyle(fontSize: 12)),
                                        value: _salaryByTransfer,
                                        onChanged: (val) {
                                          setState(() {
                                            _salaryByTransfer = val;
                                            if (val && _selectedEmployee != null) {
                                              _accountController.text = _selectedEmployee!.bankAccountNumber ?? '';
                                            }
                                          });
                                        },
                                      ),
                                      if (_salaryByTransfer) ...[
                                        TextFormField(
                                          controller: _accountController,
                                          decoration: const InputDecoration(
                                            labelText: 'Account Number *',
                                            labelStyle: TextStyle(fontSize: 12),
                                          ),
                                          style: const TextStyle(fontSize: 13),
                                          validator: (val) {
                                            if (_salaryByTransfer && (val == null || val.trim().isEmpty)) {
                                              return 'Account number is required';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Rules Card
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
                                        'Salary Rules',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: tealColor),
                                      ),
                                      const SizedBox(height: 8),
                                      SwitchListTile.adaptive(
                                        contentPadding: EdgeInsets.zero,
                                        activeColor: tealColor,
                                        title: const Text('Allow Overtime', style: TextStyle(fontSize: 12)),
                                        value: _allowOvertime,
                                        onChanged: (val) => setState(() => _allowOvertime = val),
                                      ),
                                      SwitchListTile.adaptive(
                                        contentPadding: EdgeInsets.zero,
                                        activeColor: tealColor,
                                        title: const Text('Late Coming Deduction', style: TextStyle(fontSize: 12)),
                                        value: _lateComingDeduction,
                                        onChanged: (val) => setState(() => _lateComingDeduction = val),
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
                      // Actions at the bottom
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            if (isEdit && auth.hasPermission('can-delete-salary'))
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
                                isEdit ? 'Update Salary Setup' : 'Save Salary Setup',
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

  Widget _buildNumberField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        prefixText: 'Rs ',
      ),
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 13),
    );
  }
}
