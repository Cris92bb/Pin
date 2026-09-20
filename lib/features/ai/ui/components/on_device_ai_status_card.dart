import 'package:flutter/material.dart';
import '../../../../shared/ui/pin_button.dart';
import '../../../../shared/ui/pin_tokens.dart';
import '../../services/on_device_ai_service.dart';

/// Interactive status card displaying the state of On-Device Gemini Nano
/// via Android AICore (for Pixel 9+ and flagship Samsung Galaxy devices).
class OnDeviceAiStatusCard extends StatelessWidget {
  final OnDeviceAiCapability? capability;
  final bool isChecking;
  final VoidCallback onRefresh;
  final VoidCallback? onDownload;
  final VoidCallback? onTest;

  const OnDeviceAiStatusCard({
    super.key,
    required this.capability,
    required this.isChecking,
    required this.onRefresh,
    this.onDownload,
    this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cap = capability;
    final isReady = cap?.isReady == true;
    final isDownloadable = cap?.status == OnDeviceAiStatus.downloadable;
    final isDownloading = cap?.status == OnDeviceAiStatus.downloading;

    final Color statusColor;
    final IconData statusIcon;
    final String title;
    final String subtitle;

    if (isChecking) {
      statusColor = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;
      statusIcon = Icons.hourglass_top_rounded;
      title = 'Checking On-Device AI...';
      subtitle = 'Querying Android AICore runtime status...';
    } else if (isReady) {
      statusColor = isDark ? PinTokens.darkEnergyLowText : PinTokens.lightActiveFocus;
      statusIcon = Icons.bolt_rounded;
      title = 'On-Device Gemini Nano Ready';
      final modelInfo = cap?.deviceModel != null ? ' on ${cap!.deviceModel}' : '';
      subtitle = 'Hardware accelerated via Android AICore$modelInfo. 100% private and offline.';
    } else if (isDownloadable) {
      statusColor = isDark ? PinTokens.darkEnergyMediumText : PinTokens.energyMediumAccentText;
      statusIcon = Icons.downloading_rounded;
      title = 'Gemini Nano Ready to Download';
      subtitle = 'Supported on your hardware. Model must be downloaded via AICore to enable on-device inference.';
    } else if (isDownloading) {
      statusColor = isDark ? PinTokens.googleBlue : PinTokens.googleBlue;
      statusIcon = Icons.sync_rounded;
      title = 'Downloading Gemini Nano Model';
      subtitle = 'AICore is currently downloading the on-device model in the background.';
    } else {
      statusColor = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;
      statusIcon = Icons.cloud_outlined;
      title = 'On-Device AI Unavailable';
      subtitle = cap?.message.isNotEmpty == true
          ? cap!.message
          : 'Requires Pixel 9+ or flagship Samsung with Android AICore. Pin will use Cloud Gemini API instead.';
    }

    final cardBg = isDark ? PinTokens.darkCardBg : PinTokens.lightCardBg;
    final borderColor = isDark ? PinTokens.darkBorder : PinTokens.lightBorder;
    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: PinTokens.radiusCard,
        border: Border.all(
          color: isReady ? statusColor.withValues(alpha: 0.45) : borderColor,
          width: isReady ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (isReady)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'NPU',
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (cap?.deviceModel != null && cap!.deviceModel!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.smartphone_rounded, size: 14, color: textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${cap.manufacturer ?? "Device"}: ${cap.deviceModel}',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (cap.isKnownSupportedDevice) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: PinTokens.googleBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Flagship Supported',
                      style: TextStyle(
                        color: PinTokens.googleBlue,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: isChecking ? null : onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Check Status', style: TextStyle(fontSize: 12)),
              ),
              if (isDownloadable && onDownload != null) ...[
                const SizedBox(width: 8),
                PinButton(
                  text: 'Download Model',
                  icon: Icons.download_rounded,
                  isCompact: true,
                  onPressed: onDownload,
                ),
              ],
              if (isReady && onTest != null) ...[
                const SizedBox(width: 8),
                PinButton(
                  text: 'Test On-Device',
                  icon: Icons.play_arrow_rounded,
                  isCompact: true,
                  onPressed: onTest,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
