import 'package:flutter/material.dart';
import 'package:unimate_huit/widgets/unimate_appbar.dart';

class UnderConstructionScreen extends StatelessWidget {
  final String title;
  const UnderConstructionScreen({
    super.key,
    this.title = "Tính năng đang phát triển",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UniMateAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 80, color: Colors.blue.shade900),
            const SizedBox(height: 16),
            const Text(
              "Tính năng này đang được phát triển!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Vui lòng quay lại sau.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
