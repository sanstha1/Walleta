import 'package:flutter/material.dart';
import 'package:walleta/common/ui/custom_ui_helper.dart';
import 'package:walleta/theme/app_colors.dart';

class ModelDownloadWidget extends StatelessWidget {
  final bool isModelLoaded;
  final bool isDownloading;
  final double downloadProgress;
  final VoidCallback onDownload;

  const ModelDownloadWidget({
    super.key,
    required this.isModelLoaded,
    required this.isDownloading,
    required this.downloadProgress,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    if (isModelLoaded) {
      return _buildReadyState(context);
    }
    if (isDownloading) {
      return _buildDownloadingState(context);
    }
    return _buildDownloadPrompt(context);
  }

  Widget _buildReadyState(BuildContext context) {
    return Container(
      margin: lXPadding,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.of(context).success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.of(context).success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: AppColors.of(context).success,
          ),
          sWSpan,
          Text(
            "AI Model Ready",
            style: bodySmall(
              context,
            )?.copyWith(color: AppColors.of(context).success),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadingState(BuildContext context) {
    final percent = (downloadProgress * 100).toInt();
    return Container(
      margin: lXPadding,
      padding: mPadding,
      decoration: BoxDecoration(
        color: AppColors.of(context).containerBG,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.of(context).primary,
                  ),
                ),
              ),
              sWSpan,
              Text('Downloading AI Model $percent%', style: bodySmall(context)),
            ],
          ),
          sHSpan,
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: downloadProgress,
              backgroundColor: AppColors.of(
                context,
              ).primaryText.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.of(context).primary,
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadPrompt(BuildContext context) {
    return GestureDetector(
      onTap: onDownload,
      child: Container(
        margin: lXPadding,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.of(context).containerBG,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.of(context).primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.download_rounded,
              size: 18,
              color: AppColors.of(context).primary,
            ),
            sWSpan,
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Enable AI Features",
                    style: bodySmallB(
                      context,
                    )?.copyWith(color: AppColors.of(context).primary),
                  ),
                  Text(
                    "AI Model Size:",
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.of(
                        context,
                      ).primaryText.withValues(alpha: 0.5),
                    ),
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
