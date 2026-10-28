import 'package:flutter/material.dart';
import '../core/app_core.dart';
import '../core/legal_text.dart';
import '../widgets/checkout_widgets.dart';

/// key: 'terms' | 'privacy' | 'refund'
class LegalScreen extends StatelessWidget {
  final String keyName;
  const LegalScreen({super.key, required this.keyName});

  @override
  Widget build(BuildContext context) {
    final sections = legalText[keyName] ?? const [];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 20, 8),
              child: Row(children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.chevron_left, size: 30, color: kNavy),
                ),
                Expanded(
                  child: Text(context.tr(keyName),
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: kNavy)),
                ),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                children: [
                  for (final s in sections) ...[
                    Text(s[0],
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: kNavy)),
                    const SizedBox(height: 6),
                    Text(s[1],
                        style: const TextStyle(
                            fontSize: 14.5,
                            height: 1.5,
                            color: Color(0xFF55606B))),
                    const SizedBox(height: 18),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}