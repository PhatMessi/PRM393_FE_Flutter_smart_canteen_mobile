import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  void _handleSendRequest(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
<<<<<<< HEAD
        const SnackBar(content: Text("Vui lòng nhập địa chỉ email")),
=======
        const SnackBar(content: Text("Vui long nhap dia chi email")),
>>>>>>> e4d461e2e105481c2ac08024809f60dafe47eaf8
      );
      return;
    }

    // Ẩn bàn phím
    FocusScope.of(context).unfocus();

    bool success = await authProvider.forgotPassword(email);

    if (context.mounted) {
      if (success) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Kiem tra email"),
<<<<<<< HEAD
            content: const Text("Chúng tôi đã gửi hướng dẫn khôi phục mật khẩu đến email của bạn."),
=======
            content: const Text("Chung toi da gui huong dan khoi phuc mat khau den email cua ban."),
>>>>>>> e4d461e2e105481c2ac08024809f60dafe47eaf8
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(); // Đóng Dialog
                  Navigator.of(context).pop(); // Về màn hình Login
                },
                child: const Text("Dong", style: TextStyle(color: Color(0xFF00E676))),
              )
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? "Da xay ra loi"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandGreen = Color(0xFF00E676);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
<<<<<<< HEAD
          "Đặt lại mật khẩu",
=======
          "Dat lai mat khau",
>>>>>>> e4d461e2e105481c2ac08024809f60dafe47eaf8
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                // 1. Icon Circle (Ổ khóa xanh)
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: brandGreen.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ]
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Container(
                     decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: brandGreen, width: 2)
                     ),
                     child: const Icon(
                        Icons.lock_reset_outlined,
                        size: 35,
                        color: brandGreen,
                      ),
                  ),
                ),
                
                const SizedBox(height: 30),

                // 2. Tiêu đề & Mô tả
                const Text(
<<<<<<< HEAD
                  "Quên mật khẩu?",
=======
                  "Quen mat khau?",
>>>>>>> e4d461e2e105481c2ac08024809f60dafe47eaf8
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
<<<<<<< HEAD
                    "Đừng lo! Hay nhập email đã liên kết với tài khoản canteen của bạn.",
=======
                    "Dung lo! Hay nhap email da lien ket voi tai khoan canteen cua ban.",
>>>>>>> e4d461e2e105481c2ac08024809f60dafe47eaf8
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // 3. Input Email
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
<<<<<<< HEAD
                    "Địa chỉ email",
=======
                    "Dia chi email",
>>>>>>> e4d461e2e105481c2ac08024809f60dafe47eaf8
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white, // Nền xám nhạt như design
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: "student@school.edu.vn",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6), // Màu xám rất nhạt giống ảnh
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 4. Button Send
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : () => _handleSendRequest(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandGreen,
                          foregroundColor: Colors.white,
                          elevation: 5,
                          shadowColor: brandGreen.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: auth.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
<<<<<<< HEAD
                                "Gửi hướng dẫn",
=======
                                "Gui huong dan",
>>>>>>> e4d461e2e105481c2ac08024809f60dafe47eaf8
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 100),

                // 5. Footer Text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
<<<<<<< HEAD
                      "Cần hỗ trợ? ",
=======
                      "Can ho tro? ",
>>>>>>> e4d461e2e105481c2ac08024809f60dafe47eaf8
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Icon(Icons.open_in_new, size: 14, color: Colors.grey[800]),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}