import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/leaves/leave_rules_provider.dart';
import '../../custom_widgets/app_drawer.dart';
import '../../custom_widgets/inkdrop_loader.dart';

class LeaveRulesScreen extends StatefulWidget {
  const LeaveRulesScreen({super.key});

  @override
  State<LeaveRulesScreen> createState() => _LeaveRulesScreenState();
}

class _LeaveRulesScreenState extends State<LeaveRulesScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers for input fields
  late TextEditingController _casualLeaveController;
  late TextEditingController _lateGraceController;
  late TextEditingController _latePartialMaxController;
  late TextEditingController _shortLeaveMaxHoursController;
  late TextEditingController _shortLeavesPerCasualController;
  late TextEditingController _halfDayMinController;
  late TextEditingController _halfDaysPerCasualController;
  late TextEditingController _earlyDispersalController;
  late TextEditingController _shortLeavesPerDeductionController;
  late TextEditingController _halfDaysPerDeductionController;
  late TextEditingController _lateGracePerDeductionController;
  late TextEditingController _latePartialPerDeductionController;
  late TextEditingController _allowanceLateGraceController;
  late TextEditingController _allowanceLatePartialController;
  late TextEditingController _allowanceHalfDayController;
  late TextEditingController _allowanceShortLeaveController;
  late TextEditingController _allowanceDayLeaveController;

  // Boolean state for switches
  bool _sandwichBeforeAndAfter = true;
  bool _sandwichBeforeOnly = true;
  bool _sandwichAfterOnly = true;
  bool _advanceApprovalRequired = true;
  String _unauthorizedAbsenceDeduction = 'full_day';

  @override
  void initState() {
    super.initState();
    
    // Initialize with defaults
    _casualLeaveController = TextEditingController(text: '10');
    _lateGraceController = TextEditingController(text: '15');
    _latePartialMaxController = TextEditingController(text: '120');
    _shortLeaveMaxHoursController = TextEditingController(text: '2.00');
    _shortLeavesPerCasualController = TextEditingController(text: '3');
    _halfDayMinController = TextEditingController(text: '120');
    _halfDaysPerCasualController = TextEditingController(text: '2');
    _earlyDispersalController = TextEditingController(text: '420');
    _shortLeavesPerDeductionController = TextEditingController(text: '3');
    _halfDaysPerDeductionController = TextEditingController(text: '2');
    _lateGracePerDeductionController = TextEditingController(text: '3');
    _latePartialPerDeductionController = TextEditingController(text: '2');
    _allowanceLateGraceController = TextEditingController(text: '2');
    _allowanceLatePartialController = TextEditingController(text: '2');
    _allowanceHalfDayController = TextEditingController(text: '1');
    _allowanceShortLeaveController = TextEditingController(text: '2');
    _allowanceDayLeaveController = TextEditingController(text: '1');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRules();
    });
  }

  @override
  void dispose() {
    _casualLeaveController.dispose();
    _lateGraceController.dispose();
    _latePartialMaxController.dispose();
    _shortLeaveMaxHoursController.dispose();
    _shortLeavesPerCasualController.dispose();
    _halfDayMinController.dispose();
    _halfDaysPerCasualController.dispose();
    _earlyDispersalController.dispose();
    _shortLeavesPerDeductionController.dispose();
    _halfDaysPerDeductionController.dispose();
    _lateGracePerDeductionController.dispose();
    _latePartialPerDeductionController.dispose();
    _allowanceLateGraceController.dispose();
    _allowanceLatePartialController.dispose();
    _allowanceHalfDayController.dispose();
    _allowanceShortLeaveController.dispose();
    _allowanceDayLeaveController.dispose();
    super.dispose();
  }

  Future<void> _loadRules() async {
    final provider = Provider.of<LeaveRulesProvider>(context, listen: false);
    await provider.fetchLeaveRules();
    
    if (provider.error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error!),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final rules = provider.leaveRules;
    setState(() {
      _casualLeaveController.text = rules.casualLeavePerYear.toString();
      _lateGraceController.text = rules.lateGraceMinutes.toString();
      _latePartialMaxController.text = rules.latePartialMaxMinutes.toString();
      _shortLeaveMaxHoursController.text = rules.shortLeaveMaxHours.toString();
      _shortLeavesPerCasualController.text = rules.shortLeavesPerCasual.toString();
      _halfDayMinController.text = rules.halfDayMinMinutes.toString();
      _halfDaysPerCasualController.text = rules.halfDaysPerCasual.toString();
      _earlyDispersalController.text = rules.earlyDispersalThresholdMinutes.toString();
      _shortLeavesPerDeductionController.text = rules.shortLeavesPerDeduction.toString();
      _halfDaysPerDeductionController.text = rules.halfDaysPerDeduction.toString();
      _lateGracePerDeductionController.text = rules.lateGracePerDeduction.toString();
      _latePartialPerDeductionController.text = rules.latePartialPerDeduction.toString();
      _allowanceLateGraceController.text = rules.allowanceLateGrace.toString();
      _allowanceLatePartialController.text = rules.allowanceLatePartial.toString();
      _allowanceHalfDayController.text = rules.allowanceHalfDay.toString();
      _allowanceShortLeaveController.text = rules.allowanceShortLeave.toString();
      _allowanceDayLeaveController.text = rules.allowanceDayLeave.toString();

      _sandwichBeforeAndAfter = rules.sandwichBeforeAndAfter;
      _sandwichBeforeOnly = rules.sandwichBeforeOnly;
      _sandwichAfterOnly = rules.sandwichAfterOnly;
      _advanceApprovalRequired = rules.advanceApprovalRequired;
      _unauthorizedAbsenceDeduction = rules.unauthorizedAbsenceDeduction == 'half_day' ? 'half_day' : 'full_day';
    });
  }

  void _resetLocalToDefaults() {
    setState(() {
      _casualLeaveController.text = '10';
      _lateGraceController.text = '15';
      _latePartialMaxController.text = '120';
      _shortLeaveMaxHoursController.text = '2.00';
      _shortLeavesPerCasualController.text = '3';
      _halfDayMinController.text = '120';
      _halfDaysPerCasualController.text = '2';
      _earlyDispersalController.text = '420';
      _shortLeavesPerDeductionController.text = '3';
      _halfDaysPerDeductionController.text = '2';
      _lateGracePerDeductionController.text = '3';
      _latePartialPerDeductionController.text = '2';
      _allowanceLateGraceController.text = '2';
      _allowanceLatePartialController.text = '2';
      _allowanceHalfDayController.text = '1';
      _allowanceShortLeaveController.text = '2';
      _allowanceDayLeaveController.text = '1';

      _sandwichBeforeAndAfter = true;
      _sandwichBeforeOnly = true;
      _sandwichAfterOnly = true;
      _advanceApprovalRequired = true;
      _unauthorizedAbsenceDeduction = 'full_day';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Form values reset to default'),
        backgroundColor: Color(0xFF007F70),
      ),
    );
  }

  Future<void> _saveRules() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<LeaveRulesProvider>(context, listen: false);

    // Save UI values back to provider properties
    provider.updateField('casual_leave_per_year', int.tryParse(_casualLeaveController.text) ?? 10);
    provider.updateField('sandwich_before_and_after', _sandwichBeforeAndAfter);
    provider.updateField('sandwich_before_only', _sandwichBeforeOnly);
    provider.updateField('sandwich_after_only', _sandwichAfterOnly);
    provider.updateField('late_grace_minutes', int.tryParse(_lateGraceController.text) ?? 15);
    provider.updateField('late_partial_max_minutes', int.tryParse(_latePartialMaxController.text) ?? 120);
    provider.updateField('short_leave_max_hours', double.tryParse(_shortLeaveMaxHoursController.text) ?? 2.0);
    provider.updateField('short_leaves_per_casual', int.tryParse(_shortLeavesPerCasualController.text) ?? 3);
    provider.updateField('half_day_min_minutes', int.tryParse(_halfDayMinController.text) ?? 120);
    provider.updateField('half_days_per_casual', int.tryParse(_halfDaysPerCasualController.text) ?? 2);
    provider.updateField('early_dispersal_threshold_minutes', int.tryParse(_earlyDispersalController.text) ?? 420);
    provider.updateField('short_leaves_per_deduction', int.tryParse(_shortLeavesPerDeductionController.text) ?? 3);
    provider.updateField('half_days_per_deduction', int.tryParse(_halfDaysPerDeductionController.text) ?? 2);
    provider.updateField('late_grace_per_deduction', int.tryParse(_lateGracePerDeductionController.text) ?? 3);
    provider.updateField('late_partial_per_deduction', int.tryParse(_latePartialPerDeductionController.text) ?? 2);
    provider.updateField('allowance_late_grace', int.tryParse(_allowanceLateGraceController.text) ?? 2);
    provider.updateField('allowance_late_partial', int.tryParse(_allowanceLatePartialController.text) ?? 2);
    provider.updateField('allowance_half_day', int.tryParse(_allowanceHalfDayController.text) ?? 1);
    provider.updateField('allowance_short_leave', int.tryParse(_allowanceShortLeaveController.text) ?? 2);
    provider.updateField('allowance_day_leave', int.tryParse(_allowanceDayLeaveController.text) ?? 1);
    provider.updateField('advance_approval_required', _advanceApprovalRequired);
    provider.updateField('unauthorized_absence_deduction', _unauthorizedAbsenceDeduction);

    final success = await provider.saveLeaveRules();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave rules updated successfully'),
          backgroundColor: Color(0xFF007F70),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to update leave rules'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LeaveRulesProvider>(context);
    final width = MediaQuery.of(context).size.width;
    const tealColor = Color(0xFF007F70);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      drawer: AppDrawer(activeRoute: '/leave-rules'),
      appBar: AppBar(
        backgroundColor: tealColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Leave Rules Config',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Poppins'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadRules,
          )
        ],
      ),
      body: provider.isLoading || (!provider.isInitialized && provider.error == null)
          ? const Center(child: InkDropLoader(color: tealColor))
          : provider.error != null
              ? _buildErrorState(provider.error!, tealColor)
              : Form(
                  key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Info
                        const Text(
                          'Configure Leave & Attendance Rules',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontFamily: 'Poppins'),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Set deductions triggers, grace periods, sandwich rules, and monthly allowances.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),

                        // Tab Header bar (static style representation matching screenshot)
                        _buildFakeTabBar(tealColor),
                        const SizedBox(height: 16),



                        // Section 2: Late Arrival Thresholds
                        _buildSectionCard(
                          icon: Icons.alarm,
                          title: 'Late Arrival Thresholds',
                          subtitle: 'Three-tier system: grace → partial → half day.',
                          tealColor: tealColor,
                          children: [
                            _buildResponsiveThreeFields(width, [
                              _buildNumberField(
                                label: 'Grace window',
                                controller: _lateGraceController,
                                unit: 'min',
                                helpText: 'Arrivals within this window = no deduction.',
                              ),
                              _buildNumberField(
                                label: 'Partial absent up to',
                                controller: _latePartialMaxController,
                                unit: 'min',
                                helpText: 'Late up to this → treated as ½ day absent.',
                              ),
                              _buildBeyondPartialCard(),
                            ]),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1),
                            ),
                            Text(
                              'DEDUCTION TRIGGERS (LATE ARRIVALS → 1 SALARY DAY DEDUCTED)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildResponsiveRow(width, [
                              _buildNumberField(
                                label: 'After N grace lates (≤ grace min)',
                                controller: _lateGracePerDeductionController,
                                unit: 'lates',
                                helpText: 'How many small lates accumulate before 1 day is deducted.',
                              ),
                              _buildNumberField(
                                label: 'After N partial lates (> grace min)',
                                controller: _latePartialPerDeductionController,
                                unit: 'lates',
                                helpText: 'How many longer lates accumulate before 1 day is deducted.',
                              ),
                            ]),
                          ],
                        ),

                        // Section 3: Short Leave
                        _buildSectionCard(
                          icon: Icons.hourglass_bottom_rounded,
                          title: 'Short Leave (Partial Day)',
                          subtitle: 'Leave of a few hours within working hours.',
                          tealColor: tealColor,
                          children: [
                            _buildResponsiveThreeFields(width, [
                              _buildNumberField(
                                label: 'Max short leave duration',
                                controller: _shortLeaveMaxHoursController,
                                unit: 'hrs',
                                helpText: 'Leave up to this counts as one short leave.',
                              ),
                              _buildNumberField(
                                label: 'Short leaves = 1 CL',
                                controller: _shortLeavesPerCasualController,
                                unit: 'leaves',
                                helpText: 'How many short leaves consume one casual leave.',
                              ),
                              _buildNumberField(
                                label: 'Short leaves → deduction',
                                controller: _shortLeavesPerDeductionController,
                                unit: 'leaves',
                                helpText: 'Short leaves that trigger a 1-day salary deduction.',
                              ),
                            ]),
                            const SizedBox(height: 12),
                            _buildNoteBox(
                              'Short leave is only allowed between arrival and dispersal time — not at the start or end of the office day.',
                            ),
                          ],
                        ),

                        // Section 4: Half-Day Leave
                        _buildSectionCard(
                          icon: Icons.hourglass_top,
                          title: 'Half-Day Leave',
                          subtitle: 'Absence threshold for half-day classification.',
                          tealColor: tealColor,
                          children: [
                            _buildResponsiveThreeFields(width, [
                              _buildNumberField(
                                label: 'Absence > N min = half day',
                                controller: _halfDayMinController,
                                unit: 'min',
                                helpText: 'Absences beyond this are treated as half-day leave.',
                              ),
                              _buildNumberField(
                                label: 'Half days = 1 CL',
                                controller: _halfDaysPerCasualController,
                                unit: 'days',
                                helpText: 'How many half-days consume one casual leave.',
                              ),
                              _buildNumberField(
                                label: 'Half days → deduction',
                                controller: _halfDaysPerDeductionController,
                                unit: 'days',
                                helpText: 'Half-days that trigger a 1-day salary deduction.',
                              ),
                            ]),
                          ],
                        ),

                        // Section 5: Early Dispersal
                        _buildSectionCard(
                          icon: Icons.run_circle_outlined,
                          title: 'Early Dispersal',
                          subtitle: 'Minimum working minutes before leaving is penalised.',
                          tealColor: tealColor,
                          children: [
                            _buildResponsiveRow(width, [
                              _buildNumberField(
                                label: 'Minimum working minutes (threshold)',
                                controller: _earlyDispersalController,
                                unit: 'min',
                                helpText: 'Leaving after threshold → ½ day. Leaving before → full day.',
                              ),
                              _buildEarlyDispersalSummaryCard(),
                            ]),
                          ],
                        ),

                        // Section 6: Monthly Allowances
                        _buildSectionCard(
                          icon: Icons.card_giftcard,
                          title: 'Monthly Allowances',
                          subtitle: 'Free buffer per month — reset every month, no deduction applied.',
                          tealColor: tealColor,
                          children: [
                            _buildResponsiveGrid5(width, [
                              _buildNumberField(
                                label: 'Grace lates',
                                controller: _allowanceLateGraceController,
                                unit: 'free',
                              ),
                              _buildNumberField(
                                label: 'Partial lates',
                                controller: _allowanceLatePartialController,
                                unit: 'free',
                              ),
                              _buildNumberField(
                                label: 'Half-day leaves',
                                controller: _allowanceHalfDayController,
                                unit: 'free',
                              ),
                              _buildNumberField(
                                label: 'Short leaves',
                                controller: _allowanceShortLeaveController,
                                unit: 'free',
                              ),
                              _buildNumberField(
                                label: 'Full day leaves',
                                controller: _allowanceDayLeaveController,
                                unit: 'free',
                              ),
                            ]),
                          ],
                        ),

                        // Section 7: General Policies
                        _buildSectionCard(
                          icon: Icons.security_outlined,
                          title: 'General Policies',
                          subtitle: 'Approval, biometric and absence handling.',
                          tealColor: tealColor,
                          children: [
                            _buildToggle(
                              title: 'Advance approval required',
                              subtitle: 'All leave applications must be approved before the leave date.',
                              value: _advanceApprovalRequired,
                              onChanged: (val) => setState(() => _advanceApprovalRequired = val),
                              tealColor: tealColor,
                            ),
                          ],
                        ),

                        // Form Action Buttons (Save / Reset)
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              onPressed: provider.isSaving ? null : _resetLocalToDefaults,
                              child: const Text(
                                'Reset to Defaults',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54, fontFamily: 'Poppins'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tealColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              ),
                              onPressed: provider.isSaving ? null : _saveRules,
                              child: Text(
                                provider.isSaving ? 'Updating...' : 'Update Leave Rules',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // WIDGET BUILDERS

  Widget _buildFakeTabBar(Color tealColor) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabButton('Attendance', false, tealColor),
          _buildTabButton('Leave Rules', true, tealColor),
          _buildTabButton('Camera', false, tealColor),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, bool isActive, Color tealColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? tealColor : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.white : Colors.grey[600],
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color tealColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tealColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: tealColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontFamily: 'Poppins'),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required String unit,
    String? helpText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey[500],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Required';
            if (double.tryParse(value) == null) return 'Invalid number';
            return null;
          },
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: Colors.grey[50],
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    unit,
                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF007F70), width: 1.5),
            ),
          ),
        ),
        if (helpText != null) ...[
          const SizedBox(height: 4),
          Text(
            helpText,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ],
    );
  }

  Widget _buildBeyondPartialCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!, style: BorderStyle.solid),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BEYOND PARTIAL LIMIT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '½ day absent',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54, fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 4),
          const Text(
            'Automatically applied when late exceeds the partial limit.',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEarlyDispersalSummaryCard() {
    final threshold = int.tryParse(_earlyDispersalController.text) ?? 420;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RULES SUMMARY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '≥ $threshold min worked → ½ day',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54, fontFamily: 'Poppins'),
          ),
          Text(
            '< $threshold min worked → Full day absent',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54, fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color tealColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: tealColor,
          activeTrackColor: tealColor.withAlpha(76),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoteBox(String note) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Amber-50
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFEF3C7)), // Amber-100
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              note,
              style: const TextStyle(fontSize: 11, color: Color(0xFFB45309), height: 1.3, fontWeight: FontWeight.w500, fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  // RESPONSIVE LAYOUT HELPERS (Media Query based spacing/wrapping)

  Widget _buildResponsiveRow(double screenWidth, List<Widget> children) {
    if (screenWidth > 600) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .map(
              (w) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: w,
                ),
              ),
            )
            .toList(),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: w,
              ),
            )
            .toList(),
      );
    }
  }

  Widget _buildResponsiveThreeFields(double screenWidth, List<Widget> children) {
    if (screenWidth > 700) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .map(
              (w) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: w,
                ),
              ),
            )
            .toList(),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: w,
              ),
            )
            .toList(),
      );
    }
  }

  Widget _buildResponsiveGrid5(double screenWidth, List<Widget> children) {
    if (screenWidth > 800) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .map(
              (w) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: w,
                ),
              ),
            )
            .toList(),
      );
    } else if (screenWidth > 500) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: Padding(padding: const EdgeInsets.all(4.0), child: children[0])),
              Expanded(child: Padding(padding: const EdgeInsets.all(4.0), child: children[1])),
              Expanded(child: Padding(padding: const EdgeInsets.all(4.0), child: children[2])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Padding(padding: const EdgeInsets.all(4.0), child: children[3])),
              Expanded(child: Padding(padding: const EdgeInsets.all(4.0), child: children[4])),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: children
            .map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: w,
              ),
            )
            .toList(),
      );
    }
  }

  Widget _buildErrorState(String error, Color tealColor) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDA4AF)), // Soft red border
          boxShadow: [
            BoxShadow(
              color: Colors.red.withAlpha(10),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF1F2), // Light pink/red
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFFE11D48), // Rose 600
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Server Connection Error',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                height: 1.4,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: tealColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _loadRules,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Retry Connection',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
