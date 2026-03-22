import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/menu_item.dart';
import '../models/parent_control_models.dart';
import '../services/menu_service.dart';
import '../services/parent_control_service.dart';
import '../utils/money.dart';
import '../utils/vn_time.dart';

class ParentChildManagementScreen extends StatefulWidget {
  const ParentChildManagementScreen({super.key});

  @override
  State<ParentChildManagementScreen> createState() =>
      _ParentChildManagementScreenState();
}

class _ParentChildManagementScreenState
    extends State<ParentChildManagementScreen> {
  final ParentControlService _service = ParentControlService();
  final MenuService _menuService = MenuService();
  final TextEditingController _studentEmailCtrl = TextEditingController();
  final TextEditingController _dailyLimitCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  List<LinkedStudent> _students = [];
  List<MenuItem> _menuItems = [];

  int? _selectedStudentId;
  ParentWalletControlSnapshot? _snapshot;

  bool _guardianMode = false;
  final Set<int> _blockedItemIds = <int>{};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _studentEmailCtrl.dispose();
    _dailyLimitCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);

    final students = await _service.getLinkedStudents();
    final menuItems = await _menuService.getMenuItems();

    int? selectedStudentId;
    ParentWalletControlSnapshot? snapshot;

    if (students.isNotEmpty) {
      selectedStudentId = students.first.userId;
      snapshot = await _service.getSnapshot(selectedStudentId);
    }

    if (!mounted) return;

    setState(() {
      _students = students;
      _menuItems = menuItems;
      _selectedStudentId = selectedStudentId;
      _snapshot = snapshot;
      _applySnapshot(snapshot);
      _loading = false;
    });
  }

  void _applySnapshot(ParentWalletControlSnapshot? snapshot) {
    _guardianMode = snapshot?.isGuardianWalletEnabled ?? false;
    _blockedItemIds
      ..clear()
      ..addAll(snapshot?.blockedItemIds ?? const <int>[]);
    _dailyLimitCtrl.text = snapshot?.dailySpendingLimit == null
        ? ''
        : snapshot!.dailySpendingLimit!.toStringAsFixed(0);
  }

  Future<void> _loadSnapshotFor(int studentId) async {
    setState(() => _loading = true);

    final snapshot = await _service.getSnapshot(studentId);
    if (!mounted) return;

    setState(() {
      _selectedStudentId = studentId;
      _snapshot = snapshot;
      _applySnapshot(snapshot);
      _loading = false;
    });
  }

  Future<void> _saveControl() async {
    final studentId = _selectedStudentId;
    if (studentId == null) return;

    final parsedLimit = _dailyLimitCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_dailyLimitCtrl.text.trim());

    if (_dailyLimitCtrl.text.trim().isNotEmpty && parsedLimit == null) {
      _showToast('Hạn mức không hợp lệ', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final ok = await _service.updateControl(
        studentId: studentId,
        isGuardianWalletEnabled: _guardianMode,
        dailySpendingLimit: parsedLimit,
        blockedItemIds: _blockedItemIds.toList(),
      );

      if (!mounted) return;
      if (!ok) {
        _showToast('Lưu cài đặt thất bại', error: true);
        setState(() => _saving = false);
        return;
      }

      final snapshot = await _service.getSnapshot(studentId);
      if (!mounted) return;

      setState(() {
        _snapshot = snapshot;
        _applySnapshot(snapshot);
      });
      _showToast('Đã lưu chế độ Ví giám hộ');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _topUpForChild() async {
    final studentId = _selectedStudentId;
    if (studentId == null) return;

    final amountCtrl = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Nạp tiền cho con'),
          content: TextField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Số tiền',
              hintText: 'Ví dụ: 50000',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final v = double.tryParse(amountCtrl.text.trim());
                if (v == null || v <= 0) {
                  return;
                }
                Navigator.pop(ctx, v);
              },
              child: const Text('Nạp'),
            ),
          ],
        );
      },
    );
    amountCtrl.dispose();

    if (amount == null) return;

    setState(() => _saving = true);
    try {
      final ok = await _service.topUpForStudent(
        studentId: studentId,
        amount: amount,
      );
      if (!mounted) return;

      if (!ok) {
        _showToast('Nạp tiền thất bại', error: true);
        return;
      }

      final snapshot = await _service.getSnapshot(studentId);
      if (!mounted) return;

      setState(() => _snapshot = snapshot);
      _showToast('Nạp tiền thành công');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _linkStudentByEmail() async {
    final email = _studentEmailCtrl.text.trim();
    if (email.isEmpty) {
      _showToast('Vui lòng nhập email của con', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final result = await _service.linkStudentByEmail(email);
      if (!mounted) return;

      final success = result['success'] == true;
      final message = (result['message'] ?? '').toString();
      _showToast(
        message.isEmpty
            ? (success ? 'Liên kết thành công' : 'Liên kết thất bại')
            : message,
        error: !success,
      );

      if (success) {
        _studentEmailCtrl.clear();
        await _bootstrap();
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showToast(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.redAccent : const Color(0xFF2ED162),
      ),
    );
  }

  Widget _buildStudentSelector() {
    if (_students.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Text('Bạn chưa liên kết học sinh nào.'),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: _selectedStudentId,
      decoration: const InputDecoration(
        labelText: 'Chọn học sinh',
        border: OutlineInputBorder(),
      ),
      items: _students
          .map(
            (s) => DropdownMenuItem<int>(
              value: s.userId,
              child: Text('${s.fullName} (${s.email})'),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) {
          _loadSnapshotFor(v);
        }
      },
    );
  }

  Widget _buildLinkStudentCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Liên kết tài khoản con',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nhập email học sinh để liên kết vào tài khoản phụ huynh.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _studentEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email của con',
                      hintText: 'student@school.edu.vn',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _linkStudentByEmail,
                  icon: const Icon(Icons.link),
                  label: const Text('Liên kết'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2ED162),
                    foregroundColor: Colors.black,
                    minimumSize: const Size(108, 52),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    final snapshot = _snapshot;
    if (snapshot == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2418), Color(0xFF163E2B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            snapshot.studentName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Số dư ví: ${Money.vnd(snapshot.currentBalance)}',
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            'Đã chi hôm nay: ${Money.vnd(snapshot.todaySpent)}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _saving ? null : _topUpForChild,
            icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
            label: const Text(
              'Nạp tiền cho con',
              style: TextStyle(color: Colors.white),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardianCard() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ví giám hộ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bật chế độ Ví giám hộ'),
              subtitle: const Text(
                'Khóa món không lành mạnh và áp hạn mức chi tiêu',
              ),
              value: _guardianMode,
              onChanged: (v) => setState(() => _guardianMode = v),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _dailyLimitCtrl,
              enabled: _guardianMode,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Hạn mức chi tiêu ngày (VND)',
                hintText: 'Ví dụ: 50000',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Khóa món (có thể chọn nhiều món):',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: ListView.builder(
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  final checked = _blockedItemIds.contains(item.itemId);
                  return CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(item.name),
                    subtitle: Text('Giá: ${Money.vnd(item.price)}'),
                    value: checked,
                    onChanged: _guardianMode
                        ? (v) {
                            setState(() {
                              if (v == true) {
                                _blockedItemIds.add(item.itemId);
                              } else {
                                _blockedItemIds.remove(item.itemId);
                              }
                            });
                          }
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_saving || _selectedStudentId == null)
                    ? null
                    : _saveControl,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: const Text('Lưu cài đặt giám hộ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ED162),
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders() {
    final snapshot = _snapshot;
    if (snapshot == null) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lịch sử đơn gần đây',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (snapshot.recentOrders.isEmpty)
              const Text('Chưa có đơn hàng nào.'),
            ...snapshot.recentOrders.take(5).map((o) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Đơn #${o.orderId} • ${Money.vnd(o.totalPrice)}'),
                subtitle: Text(
                  '${DateFormat('dd/MM HH:mm').format(VnTime.toVn(o.orderDate))} • ${o.status}',
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final snapshot = _snapshot;
    if (snapshot == null) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lịch sử giao dịch ví',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (snapshot.recentTransactions.isEmpty)
              const Text('Chưa có giao dịch nào.'),
            ...snapshot.recentTransactions.take(6).map((t) {
              final isPayment = t.type.toLowerCase() == 'payment';
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.description.isEmpty ? t.type : t.description),
                subtitle: Text(
                  DateFormat(
                    'dd/MM HH:mm',
                  ).format(VnTime.toVn(t.transactionDate)),
                ),
                trailing: Text(
                  '${isPayment ? '-' : '+'}${Money.vnd(t.amount)}',
                  style: TextStyle(
                    color: isPayment ? Colors.black87 : const Color(0xFF2ED162),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(title: const Text('Quản lí con'), centerTitle: true),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2ED162)),
            )
          : RefreshIndicator(
              onRefresh: _bootstrap,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildLinkStudentCard(),
                  const SizedBox(height: 12),
                  _buildStudentSelector(),
                  const SizedBox(height: 12),
                  _buildOverviewCard(),
                  const SizedBox(height: 12),
                  _buildGuardianCard(),
                  const SizedBox(height: 12),
                  _buildRecentOrders(),
                  const SizedBox(height: 12),
                  _buildRecentTransactions(),
                ],
              ),
            ),
    );
  }
}
