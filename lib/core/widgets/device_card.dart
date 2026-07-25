import 'package:flutter/material.dart';

import '../../models/smart_device.dart';
import '../constants/app_colors.dart';

class DeviceCard extends StatelessWidget {
  const DeviceCard({
    required this.device,
    required this.icon,
    required this.onToggle,
    super.key,
  });

  final SmartDevice device;
  final IconData icon;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isActive = device.isOn;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(26),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryDark
                : Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isActive
                  ? AppColors.primaryDark
                  : Colors.white.withValues(alpha: 0.9),
            ),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? AppColors.primaryDark.withValues(
                  alpha: 0.18,
                )
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 22,
                offset: const Offset(0, 11),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: isActive
                        ? Colors.white
                        : AppColors.primaryDark,
                  ),
                  const Spacer(),
                  Switch.adaptive(
                    value: isActive,
                    onChanged: (_) => onToggle(),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                device.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                  color: isActive
                      ? Colors.white
                      : AppColors.lightText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.16)
                      : AppColors.primaryLight.withValues(
                    alpha: 0.55,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  device.connectionLabel,
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : AppColors.primaryDark,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}