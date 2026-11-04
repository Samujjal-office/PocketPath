import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class OfflineBanner extends StatelessWidget {
  final String? message;
  const OfflineBanner({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.warningOchreLight,
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 16,
            color: AppColors.warningOchre,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message ??
                  'Showing cached data. Connect to internet to sync latest updates.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

