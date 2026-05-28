import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TournamentStatusBadge extends StatelessWidget {
  final String status;
  const TournamentStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusProps();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha:0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == 'live') ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.liveColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  (String, Color) _statusProps() {
    switch (status) {
      case 'upcoming':
        return ('UPCOMING', AppColors.upcomingColor);
      case 'live':
        return ('LIVE', AppColors.liveColor);
      case 'finished':
        return ('FINISHED', AppColors.finishedColor);
      case 'cancelled':
        return ('CANCELLED', AppColors.cancelledColor);
      default:
        return (status.toUpperCase(), AppColors.textSecondary);
    }
  }
}
