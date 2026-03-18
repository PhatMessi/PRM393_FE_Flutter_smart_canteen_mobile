import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';
import '../services/auth_service.dart';

class WalletTopUpScreen extends StatefulWidget {
  const WalletTopUpScreen({super.key});

  @override
  State<WalletTopUpScreen> createState() => _WalletTopUpScreenState();
}

class _WalletTopUpScreenState extends State<WalletTopUpScreen> {
  final _amountController = TextEditingController(text: '50000');
  bool _isSubmitting = false;
  Timer? _statusTimer;

  static const _quickAmounts = <int>[50000, 100000, 200000, 500000];

  @override
  void dispose() {
    _statusTimer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _openCheckoutUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  Future<void> _showPayosDialog({
    required int amount,
    required int orderCode,
    required String checkoutUrl,
    required String qrCode,
  }) async {
    final statusText = ValueNotifier<String>('Dang cho thanh toan...');
    bool dialogShown = false;

    Future<void> poll() async {
      try {
        final token = await AuthService().getToken();
        if (token == null) return;

        final url = Uri.parse(
          '${ApiConfig.baseUrl}/wallet/topup/payos/$orderCode/status?sync=true',
        );
        final resp = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (resp.statusCode != 200) return;

        final data = jsonDecode(resp.body);
        final status = (data['status'] ?? '').toString();
        final processed = (data['isProcessed'] ?? false) == true;

        if (!mounted) return;

        if (status.toLowerCase() == 'paid' && processed) {
          statusText.value = 'Trang thai: Paid';
          _statusTimer?.cancel();
          if (dialogShown &&
              Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop(true);
          }
        } else {
          statusText.value = 'Trang thai: $status';
        }
      } catch (_) {}
    }

    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (_) => poll());
    await poll();

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        dialogShown = true;
        return AlertDialog(
          title: const Text('Thanh toan PayOS'),
          content: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('So tien: ${amount.toString()} d'),
                const SizedBox(height: 12),
                if (qrCode.isNotEmpty)
                  SizedBox.square(
                    dimension: 220,
                    child: QrImageView(data: qrCode, version: QrVersions.auto),
                  )
                else
                  const Text('Khong co du lieu QR'),
                const SizedBox(height: 12),
                ValueListenableBuilder<String>(
                  valueListenable: statusText,
                  builder: (context, value, _) => Text(value),
                ),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        _statusTimer?.cancel();
                        Navigator.pop(dialogContext, false);
                      },
                      child: const Text('Dong'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _openCheckoutUrl(checkoutUrl),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Mo trang thanh toan'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    _statusTimer?.cancel();
    statusText.dispose();

    if (result == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nap tien thanh cong')));
      Navigator.pop(context, true);
    }
  }

  Future<void> _submit() async {
    final amount =
        int.tryParse(
          _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui long nhap so tien hop le')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final token = await AuthService().getToken();
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui long dang nhap truoc')),
        );
        return;
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/wallet/topup/payos');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'amount': amount}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final orderCode = (data['orderCode'] as num).toInt();
        final checkoutUrl = (data['checkoutUrl'] ?? '').toString();
        final qrCode = (data['qrCode'] ?? '').toString();

        if (!mounted) return;
        await _showPayosDialog(
          amount: amount,
          orderCode: orderCode,
          checkoutUrl: checkoutUrl,
          qrCode: qrCode,
        );
      } else {
        String message = response.body;
        try {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            message =
                (data['message'] ??
                        data['Message'] ??
                        data['error'] ??
                        data['Error'] ??
                        response.body)
                    .toString();
          }
        } catch (_) {}

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Nap tien that bai: $message')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandGreen = Color(0xFF2ED162);
    const Color scaffoldBg = Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        title: const Text(
          'Nap tien',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'So tien',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Vi du: 50000',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _quickAmounts
                  .map(
                    (v) => OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => setState(
                              () => _amountController.text = v.toString(),
                            ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text('${v.toString()} đ'),
                    ),
                  )
                  .toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Nap tien ngay',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
