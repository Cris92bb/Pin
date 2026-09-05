import 'package:flutter/material.dart';
import 'pin_tokens.dart';

/// Dynamic indicator badge displaying Work-In-Progress (WIP) status.
class WipBadge extends StatelessWidget {
  final int count;
  final int limit;

  const WipBadge({
    super.key,
    required this.count,
    required this.limit,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAtLimit = count >= limit;
    final bool isNearLimit = count == limit - 1 && limit > 1;

    Color badgeColor;
    String statusLabel;

    if (isAtLimit) {
      badgeColor = PinTokens.accentAmber;
      statusLabel = 'MAX';
    } else if (isNearLimit) {
      badgeColor = PinTokens.accentSky;
      statusLabel = 'WIP';
    } else {
      badgeColor = PinTokens.accentEmerald;
      statusLabel = 'WIP';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: PinTokens.radiusFull,
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.7),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badgeColor,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$count / $limit $statusLabel',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: badgeColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
