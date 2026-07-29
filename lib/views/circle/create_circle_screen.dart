import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/validators.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/circle_viewmodel.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/common/loading_overlay.dart';


class CreateCircleScreen extends StatefulWidget {
  const CreateCircleScreen({super.key});

  @override
  State<CreateCircleScreen> createState() => _CreateCircleScreenState();
}

class _CreateCircleScreenState extends State<CreateCircleScreen> {
  int _step = 0;

  // Step 1 fields
  final _nameCtr = TextEditingController();
  final _descCtr = TextEditingController();
  final _amountCtr = TextEditingController();
  final _membersCtr = TextEditingController();
  String _frequency = 'monthly';

  // Step 2 fields
  String _payoutOrder = 'random';
  DateTime _startDate = DateTime.now(); // Always starts from today
  String _gracePeriod = '3days';
  String _penalty = '500';
  bool _vouching = true;

  final _step1Key = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtr.dispose();
    _descCtr.dispose();
    _amountCtr.dispose();
    _membersCtr.dispose();
    super.dispose();
  }

  int get _totalMembers => int.tryParse(_membersCtr.text.trim()) ?? 0;
  int get _amountKobo => (double.tryParse(_amountCtr.text.replaceAll(',', '').trim()) ?? 0).toInt() * 100;
  int get _poolKobo => _amountKobo * _totalMembers;

  String _formatNaira(int kobo) {
    final naira = kobo ~/ 100;
    return '₦${naira.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  String _payoutOrderLabel() {
    switch (_payoutOrder) {
      case 'random': return '🎲 Random Ballot';
      case 'manual': return '📋 Manual Assign';
      case 'bid': return '🏷️ Bid-Based';
      default: return '';
    }
  }

  String _startDateLabel() {
    return '${_startDate.month.toString().padLeft(2, '0')}/${_startDate.day.toString().padLeft(2, '0')}/${_startDate.year}';
  }

  String _penaltyLabel() {
    switch (_penalty) {
      case 'none': return 'None';
      case '500': return '₦500 after ${_gracePeriod == 'none' ? '0' : _gracePeriod == '3days' ? '3' : '7'} days';
      case '1000': return '₦1,000 after ${_gracePeriod == 'none' ? '0' : _gracePeriod == '3days' ? '3' : '7'} days';
      default: return '';
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(), // Prevents selecting dates before today
      lastDate: DateTime(2028),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF3DBFA8)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _submit(CircleViewModel vm, String uid) async {
    final success = await vm.createCircle(
      adminUid: uid,
      name: _nameCtr.text,
      amountNairaString: _amountCtr.text.replaceAll(',', ''),
      frequency: _frequency,
      totalMembersString: _membersCtr.text,
    );
    if (!mounted) return;
    if (success && vm.createdCircleId != null) {
      AppSnackbar.showSuccess(context, 'Circle created!');
      Navigator.of(context).pushReplacementNamed('/circle', arguments: vm.createdCircleId);
    } else {
      AppSnackbar.showError(context, vm.errorMessage ?? AppStrings.genericError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthViewModel>().currentUser?.uid ?? '';
    return Consumer<CircleViewModel>(
      builder: (context, vm, _) => LoadingOverlay(
        isLoading: vm.isLoading,
        message: 'Creating circle…',
        child: Scaffold(
          backgroundColor: const Color(0xFFF2F4F7),
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(step: _step, onCancel: () => Navigator.of(context).pop()),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildTitle(),
                        const SizedBox(height: 16),
                        _StepProgressBar(step: _step),
                        const SizedBox(height: 20),
                        if (_step == 0) _Step1(
                          formKey: _step1Key,
                          nameCtr: _nameCtr,
                          descCtr: _descCtr,
                          amountCtr: _amountCtr,
                          membersCtr: _membersCtr,
                          frequency: _frequency,
                          onFrequencyChanged: (v) => setState(() => _frequency = v),
                        ),
                        if (_step == 1) _Step2(
                          payoutOrder: _payoutOrder,
                          onPayoutOrderChanged: (v) => setState(() => _payoutOrder = v),
                          startDate: _startDateLabel(),
                          onPickDate: _pickDate,
                          gracePeriod: _gracePeriod,
                          onGracePeriodChanged: (v) => setState(() => _gracePeriod = v),
                          penalty: _penalty,
                          onPenaltyChanged: (v) => setState(() => _penalty = v),
                          vouching: _vouching,
                          onVouchingChanged: (v) => setState(() => _vouching = v),
                        ),
                        if (_step == 2) _Step3(
                          name: _nameCtr.text,
                          amount: _formatNaira(_amountKobo),
                          frequency: _frequency,
                          members: _totalMembers,
                          pool: _formatNaira(_poolKobo),
                          duration: '$_totalMembers months',
                          payoutOrder: _payoutOrderLabel(),
                          startDate: '${_monthName(_startDate.month)} ${_startDate.day}, ${_startDate.year}',
                          penalty: _penaltyLabel(),
                        ),
                        const SizedBox(height: 28),
                        _buildCta(vm, uid),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildTitle() {
    if (_step == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Review & Launch', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
          SizedBox(height: 4),
          Text('Confirm all details before creating your circle', style: TextStyle(fontSize: 13, color: Color(0xFF888899))),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Create Circle Group', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
        SizedBox(height: 4),
        Text('Tell us the basics about your savings circle', style: TextStyle(fontSize: 13, color: Color(0xFF888899))),
      ],
    );
  }

  Widget _buildCta(CircleViewModel vm, String uid) {
    if (_step == 0) {
      return _CtaButton(
        label: 'Continue to Rules →',
        onTap: () {
          if (_step1Key.currentState?.validate() ?? false) {
            setState(() => _step = 1);
          }
        },
      );
    }
    if (_step == 1) {
      return _CtaButton(
        label: 'Continue to Review →',
        onTap: () => setState(() => _step = 2),
      );
    }
    return _CtaButton(
      label: 'Launch Group & Get Invite Link',
      onTap: () => _submit(vm, uid),
    );
  }
}


class _TopBar extends StatelessWidget {
  const _TopBar({required this.step, required this.onCancel});
  final int step;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onCancel,
            child: const Row(
              children: [
                Icon(Icons.close, size: 16, color: Color(0xFF555566)),
                SizedBox(width: 4),
                Text('Cancel', style: TextStyle(fontSize: 14, color: Color(0xFF555566), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F9F4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF3DBFA8).withOpacity(0.4)),
            ),
            child: Text(
              'Step ${step + 1} of 3',
              style: const TextStyle(fontSize: 12, color: Color(0xFF3DBFA8), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final filled = i <= step;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: filled ? const Color(0xFF3DBFA8) : const Color(0xFFDDDDEE),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

class _StepBanner extends StatelessWidget {
  const _StepBanner({required this.emoji, required this.title, required this.subtitle});
  final String emoji;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFECF9F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF3DBFA8).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$emoji $title',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2A9D8F)),
          ),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF555566))),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF333344))),
  );
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    this.hint = '',
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.textInputAction = TextInputAction.next,
  });
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      textInputAction: textInputAction,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBBBBCC), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDDDDEE))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDDDDEE))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF3DBFA8), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE53935))),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5)),
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({required this.options, required this.selected, required this.onSelected});
  final List<Map<String, String>> options;
  final String selected;
  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.asMap().entries.map((e) {
        final isSelected = e.value['value'] == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelected(e.value['value']!),
            child: Container(
              margin: EdgeInsets.only(right: e.key < options.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE8F9F4) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? const Color(0xFF3DBFA8) : const Color(0xFFDDDDEE),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  if (e.value['emoji'] != null)
                    Text(e.value['emoji']!, style: const TextStyle(fontSize: 18)),
                  if (e.value['emoji'] != null) const SizedBox(height: 4),
                  Text(
                    e.value['label']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF2A9D8F) : const Color(0xFF555566),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF3DBFA8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }
}

// ─── Step 1 ──────────────────────────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  const _Step1({
    required this.formKey,
    required this.nameCtr,
    required this.descCtr,
    required this.amountCtr,
    required this.membersCtr,
    required this.frequency,
    required this.onFrequencyChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtr;
  final TextEditingController descCtr;
  final TextEditingController amountCtr;
  final TextEditingController membersCtr;
  final String frequency;
  final void Function(String) onFrequencyChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepBanner(
            emoji: '📌',
            title: 'Step 1 — Group Basics',
            subtitle: 'Name your group and set the core contribution details.',
          ),
          const SizedBox(height: 20),
          const _FieldLabel('Group Name'),
          _TextInput(
            controller: nameCtr,
            hint: 'OAU CS Alumni Circle',
            validator: Validators.validateCircleName,
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Group Description (optional)'),
          _TextInput(
            controller: descCtr,
            hint: 'e.g. Monthly savings for our alumni network',
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Contribution Amount per Member (₦)'),
          _TextInput(
            controller: amountCtr,
            hint: '50,000',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: Validators.validateContributionAmount,
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Contribution Frequency'),
          _ChipGroup(
            options: const [
              {'value': 'daily', 'label': 'Daily'},
              {'value': 'weekly', 'label': 'Weekly'},
              {'value': 'monthly', 'label': 'Monthly'},
            ],
            selected: frequency,
            onSelected: onFrequencyChanged,
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Number of Members (including you)'),
          _TextInput(
            controller: membersCtr,
            hint: '8',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
            validator: Validators.validateTotalMembers,
          ),
        ],
      ),
    );
  }
}

// ─── Step 2 ──────────────────────────────────────────────────────────────────
class _Step2 extends StatelessWidget {
  const _Step2({
    required this.payoutOrder,
    required this.onPayoutOrderChanged,
    required this.startDate,
    required this.onPickDate,
    required this.gracePeriod,
    required this.onGracePeriodChanged,
    required this.penalty,
    required this.onPenaltyChanged,
    required this.vouching,
    required this.onVouchingChanged,
  });

  final String payoutOrder;
  final void Function(String) onPayoutOrderChanged;
  final String startDate;
  final VoidCallback onPickDate;
  final String gracePeriod;
  final void Function(String) onGracePeriodChanged;
  final String penalty;
  final void Function(String) onPenaltyChanged;
  final bool vouching;
  final void Function(bool) onVouchingChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepBanner(
          emoji: '⚙️',
          title: 'Step 2 — Rules & Payout Order',
          subtitle: 'These rules are locked once the group starts. All members will see them.',
        ),
        const SizedBox(height: 20),
        const _FieldLabel('Payout Order Method'),
        _ChipGroup(
          options: const [
            {'value': 'random', 'emoji': '🎲', 'label': 'Random\nBallot'},
            {'value': 'manual', 'emoji': '📋', 'label': 'Manual\nAssign'},
            {'value': 'bid', 'emoji': '🏷️', 'label': 'Bid-Based'},
          ],
          selected: payoutOrder,
          onSelected: onPayoutOrderChanged,
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            payoutOrder == 'random'
                ? 'Random Ballot: The system assigns turns fairly using a digital draw.'
                : payoutOrder == 'manual'
                ? 'Manual Assign: Admin manually assigns the payout order.'
                : 'Bid-Based: Members bid for earlier payout positions.',
            style: const TextStyle(fontSize: 11, color: Color(0xFF888899)),
          ),
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Start Date'),
        GestureDetector(
          onTap: onPickDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDDDDEE)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(startDate, style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E))),
                const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF888899)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Late Payment Grace Period'),
        _ChipGroup(
          options: const [
            {'value': 'none', 'label': 'None'},
            {'value': '3days', 'label': '3 Days'},
            {'value': '7days', 'label': '7 Days'},
          ],
          selected: gracePeriod,
          onSelected: onGracePeriodChanged,
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Late Payment Penalty'),
        _ChipGroup(
          options: const [
            {'value': 'none', 'label': 'None'},
            {'value': '500', 'label': '₦500 Fine'},
            {'value': '1000', 'label': '₦1,000 Fine'},
          ],
          selected: penalty,
          onSelected: onPenaltyChanged,
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Member Vouching Required?'),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => onVouchingChanged(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: vouching ? const Color(0xFFE8F9F4) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: vouching ? const Color(0xFF3DBFA8) : const Color(0xFFDDDDEE),
                      width: vouching ? 1.5 : 1,
                    ),
                  ),
                  child: const Column(
                    children: [
                      Text('✅', style: TextStyle(fontSize: 18)),
                      SizedBox(height: 4),
                      Text('Yes\n(Recommended)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2A9D8F))),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => onVouchingChanged(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !vouching ? const Color(0xFFFFF0F0) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: !vouching ? const Color(0xFFE53935) : const Color(0xFFDDDDEE),
                      width: !vouching ? 1.5 : 1,
                    ),
                  ),
                  child: const Column(
                    children: [
                      Text('❌', style: TextStyle(fontSize: 18)),
                      SizedBox(height: 4),
                      Text('No', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF555566))),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.only(left: 2),
          child: Text(
            'Vouching means each new member must be approved by 2 existing members — reduces default risk.',
            style: TextStyle(fontSize: 11, color: Color(0xFF888899)),
          ),
        ),
      ],
    );
  }
}

// ─── Step 3 ──────────────────────────────────────────────────────────────────

class _Step3 extends StatelessWidget {
  const _Step3({
    required this.name,
    required this.amount,
    required this.frequency,
    required this.members,
    required this.pool,
    required this.duration,
    required this.payoutOrder,
    required this.startDate,
    required this.penalty,
  });

  final String name;
  final String amount;
  final String frequency;
  final int members;
  final String pool;
  final String duration;
  final String payoutOrder;
  final String startDate;
  final String penalty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepBanner(
          emoji: '📊',
          title: 'Step 3 — Review & Confirm',
          subtitle: 'Once launched, the group rules cannot be changed.',
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A6B72), Color(0xFF3DBFA8)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('GROUP NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white60, letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text(name.isEmpty ? 'Unnamed Circle' : name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _ReviewRow(label: 'Contribution per member', value: '$amount / $frequency'),
                    _ReviewDivider(),
                    _ReviewRow(label: 'Number of members', value: '$members members'),
                    _ReviewDivider(),
                    _ReviewRow(label: '💰 Pool per cycle', value: pool, valueColor: const Color(0xFF2A9D8F)),
                    _ReviewDivider(),
                    _ReviewRow(label: 'Duration', value: duration),
                    _ReviewDivider(),
                    _ReviewRow(label: 'Payout order', value: payoutOrder),
                    _ReviewDivider(),
                    _ReviewRow(label: 'Start date', value: startDate),
                    _ReviewDivider(),
                    _ReviewRow(label: 'Late penalty', value: penalty.isEmpty || penalty == 'None' ? 'None' : penalty),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8EC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFA726).withOpacity(0.4)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🔒', style: TextStyle(fontSize: 18)),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('What happens next?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFE65100))),
                    SizedBox(height: 4),
                    Text(
                      'A unique invite link will be generated. Share it with other members. Once all members join and link their wallets, the circle starts automatically.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF555566), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF888899))),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Divider(height: 1, color: Color(0xFFF0F0F8));
}