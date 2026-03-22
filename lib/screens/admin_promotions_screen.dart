import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/promotion_model.dart';
import '../services/admin_promotions_service.dart';

class AdminPromotionsScreen extends StatefulWidget {
  const AdminPromotionsScreen({super.key});

  @override
  State<AdminPromotionsScreen> createState() => _AdminPromotionsScreenState();
}

class _AdminPromotionsScreenState extends State<AdminPromotionsScreen> {
  final AdminPromotionsService _service = AdminPromotionsService();
  late Future<List<PromotionModel>> _future;

  final TextEditingController _codeCtl = TextEditingController();
  final TextEditingController _descCtl = TextEditingController();
  final TextEditingController _discountPercentCtl = TextEditingController(
    text: '0',
  );
  final TextEditingController _discountAmountCtl = TextEditingController();
  final TextEditingController _minOrderCtl = TextEditingController();
  final TextEditingController _maxDiscountCtl = TextEditingController();

  String _createType = 'PercentBill';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _createActive = true;

  String _prettyError(Object err) {
    final s = err.toString();
    if (s.startsWith('Exception: ')) return s.substring('Exception: '.length);
    return s;
  }

  @override
  void initState() {
    super.initState();
    _future = _service.listPromotions();
  }

  @override
  void dispose() {
    _codeCtl.dispose();
    _descCtl.dispose();
    _discountPercentCtl.dispose();
    _discountAmountCtl.dispose();
    _minOrderCtl.dispose();
    _maxDiscountCtl.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _future = _service.listPromotions();
    });
  }

  num? _tryParseNum(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return num.tryParse(t.replaceAll(',', '.'));
  }

  Future<void> _pickDate({required bool isStart}) async {
    final current = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (!mounted || picked == null) return;
    setState(() {
      final merged = DateTime(
        picked.year,
        picked.month,
        picked.day,
        current.hour,
        current.minute,
      );
      if (isStart) {
        _startDate = merged;
      } else {
        _endDate = merged;
      }
    });
  }

  Future<void> _openCreateDialog() async {
    _codeCtl.clear();
    _descCtl.clear();
    _discountPercentCtl.text = '0';
    _discountAmountCtl.clear();
    _minOrderCtl.clear();
    _maxDiscountCtl.clear();
    setState(() {
      _createType = 'PercentBill';
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 30));
      _createActive = true;
    });

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final fmt = DateFormat('dd/MM/yyyy');
        return AlertDialog(
          title: const Text('Thêm voucher'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _codeCtl,
                  decoration: const InputDecoration(labelText: 'Code *'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descCtl,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _createType,
                  items: const [
                    DropdownMenuItem(
                      value: 'PercentBill',
                      child: Text(' % bill'),
                    ),
                    DropdownMenuItem(
                      value: 'AmountBill',
                      child: Text('Giảm số tiền bill'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _createType = v);
                  },
                  decoration: const InputDecoration(labelText: 'Loại'),
                ),
                const SizedBox(height: 8),
                if (_createType == 'PercentBill')
                  TextField(
                    controller: _discountPercentCtl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Discount %'),
                  ),
                if (_createType == 'AmountBill')
                  TextField(
                    controller: _discountAmountCtl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Discount amount',
                    ),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: _minOrderCtl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Min order (optional)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _maxDiscountCtl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Max discount (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text('Start: ${fmt.format(_startDate)}')),
                    TextButton(
                      onPressed: () => _pickDate(isStart: true),
                      child: const Text('Chọn'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: Text('End: ${fmt.format(_endDate)}')),
                    TextButton(
                      onPressed: () => _pickDate(isStart: false),
                      child: const Text('Chọn'),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _createActive,
                  onChanged: (v) => setState(() => _createActive = v),
                  title: const Text('Kích hoạt'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final code = _codeCtl.text.trim();
                if (code.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập code.')),
                  );
                  return;
                }

                final percent = _tryParseNum(_discountPercentCtl.text) ?? 0;
                final amount = _tryParseNum(_discountAmountCtl.text);
                final minOrder = _tryParseNum(_minOrderCtl.text);
                final maxDiscount = _tryParseNum(_maxDiscountCtl.text);

                final (ok, msg) = await _service.createPromotion(
                  code: code,
                  description: _descCtl.text.trim(),
                  type: _createType,
                  discountPercentage: percent,
                  discountAmount: amount,
                  minOrderAmount: minOrder,
                  maxDiscountAmount: maxDiscount,
                  startDate: _startDate,
                  endDate: _endDate,
                  isActive: _createActive,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(msg)));
                if (ok) {
                  Navigator.of(ctx).pop();
                  _refresh();
                }
              },
              child: const Text('Tạo'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleActive(PromotionModel promo, bool value) async {
    final updated = PromotionModel(
      promotionId: promo.promotionId,
      code: promo.code,
      description: promo.description,
      type: promo.type,
      discountPercentage: promo.discountPercentage,
      discountAmount: promo.discountAmount,
      minOrderAmount: promo.minOrderAmount,
      maxDiscountAmount: promo.maxDiscountAmount,
      buyItemId: promo.buyItemId,
      buyQuantity: promo.buyQuantity,
      getItemId: promo.getItemId,
      getQuantity: promo.getQuantity,
      comboRequirements: promo.comboRequirements,
      startDate: promo.startDate,
      endDate: promo.endDate,
      isActive: value,
    );

    final (ok, msg) = await _service.updatePromotion(updated);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    if (ok) _refresh();
  }

  Future<void> _showQr(PromotionModel promo) async {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final (ok, payload, msg) = await _service.getQrPayload(promo.promotionId);

    if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    if (!mounted) return;

    if (!ok || payload == null || payload.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    final validation = QrValidator.validate(
      data: payload,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
    if (validation.status != QrValidationStatus.valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tạo QR: ${validation.error}')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('QR payload: ${promo.code}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SizedBox.square(
                    dimension: 220,
                    child: QrImageView(
                      data: payload,
                      version: QrVersions.auto,
                      gapless: false,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: SingleChildScrollView(child: SelectableText(payload)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: payload));
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã copy payload.')),
                );
              },
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  String _discountText(PromotionModel p) {
    final type = p.type;
    if (type == 'AmountBill' && p.discountAmount != null) {
      return '-${p.discountAmount}';
    }
    if (type == 'PercentBill') {
      return '-${p.discountPercentage}%';
    }
    return type;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Quản lý voucher'),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _openCreateDialog, icon: const Icon(Icons.add)),
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<PromotionModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(_prettyError(snap.error!)));
          }
          final data = snap.data ?? [];
          if (data.isEmpty) {
            return const Center(child: Text('Không có voucher nào.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (ctx, i) {
              final p = data[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.code,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Switch(
                          value: p.isActive,
                          onChanged: (v) => _toggleActive(p, v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.description,
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Hết hạn: ${fmt.format(p.endDate.toLocal())} • ${_discountText(p)}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showQr(p),
                          child: const Text('QR'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
