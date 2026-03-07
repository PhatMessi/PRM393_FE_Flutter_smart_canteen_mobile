import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  static const Color brandGreen = Color(0xFF2ED162);

  // Demo location (change to your school/canteen coordinate)
  static const double lat = 10.762622;
  static const double lon = 106.660172;

  String get _osmStaticMapUrl {
    // No API key required
    return 'https://staticmap.openstreetmap.de/staticmap.php?center=$lat,$lon&zoom=16&size=800x400&maptype=mapnik&markers=$lat,$lon,lightgreen1';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Store Location',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                _osmStaticMapUrl,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 220,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.map_outlined, size: 48, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Smart Canteen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 6),
                  Text(
                    'Canteen A • Campus',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 18, color: brandGreen),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Tap "Track Order" to view this location',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
