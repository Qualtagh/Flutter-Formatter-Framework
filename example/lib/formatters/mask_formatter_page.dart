import 'package:flutter/material.dart';
import 'package:flutter_formatter_framework/formatters/mask_formatter.dart';

class MaskFormatterPage extends StatelessWidget {
  const MaskFormatterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Formatter Framework Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter Phone Number:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                hintText: '+1 (555) 123-4567',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [MaskFormatter(mask: '+1 (###) ###-####')],
            ),
            const SizedBox(height: 16),
            const Text(
              'Try typing numbers - they will be automatically formatted as a US phone number.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
