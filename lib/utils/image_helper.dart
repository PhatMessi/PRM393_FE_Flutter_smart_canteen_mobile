// Helper widget to handle image loading logic
import 'package:flutter/material.dart';

Widget buildProductImage(String? imageUrl,
    {double? width, double? height, BoxFit fit = BoxFit.cover}) {
  if (imageUrl == null || imageUrl.isEmpty) {
    return Container(
      width: width, height: height,
      color: Colors.grey[200],
      child: const Icon(Icons.fastfood, color: Colors.grey),
    );
  }

  // [FIX] Nếu backend đang trả link demo `example.com` thì map sang asset local
  // (vì `example.com` sẽ bị CORS/không có ảnh thật -> Flutter Web sẽ không load)
  String normalized = imageUrl;
  if (normalized.startsWith('http') && normalized.contains('example.com')) {
    final uri = Uri.tryParse(normalized);
    final lastSegment = (uri != null && uri.pathSegments.isNotEmpty)
        ? uri.pathSegments.last
        : normalized.split('/').last;
    const mapping = {
      'comsuon.jpg': 'com_suon.png',
      'trasua.jpg': 'tra_sua.png',
    };
    normalized = mapping[lastSegment] ?? mapping[lastSegment.toLowerCase()] ?? normalized;
  }

  // Nếu là URL online
  if (normalized.startsWith('http')) {
    return Image.network(
      normalized,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (ctx, err, stack) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  } 
  
  // Nếu là local asset (tên file)
  return Image.asset(
    'assets/images/$normalized',
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (ctx, err, stack) {
      // Fallback nếu không tìm thấy ảnh local
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    },
  );
}
