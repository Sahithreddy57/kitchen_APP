import 'package:flutter/material.dart';
import '../core/app_core.dart';
import '../widgets/checkout_widgets.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                    color: Color(0xFFE3F4E8), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    size: 56, color: Color(0xFF2E9E57)),
              ),
              const SizedBox(height: 24),
              Text(context.tr('orderPlaced'),
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800, color: kNavy)),
              const SizedBox(height: 8),
              Text(context.tr('orderPlacedSub'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15, height: 1.4, color: Color(0xFF55606B))),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.pop(context), // back to MainShell
                  child: Text(context.tr('backHome'),
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}