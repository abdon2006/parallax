import 'package:flutter/material.dart';
import 'package:parallax/core/constants/app_colors.dart';
import 'package:parallax/core/constants/condition_catalog.dart';
import 'package:parallax/core/utils/mission_utils.dart';
import 'package:parallax/core/widgets/status_pill.dart';
import 'package:parallax/data/models/site_model.dart';

class SiteCard extends StatelessWidget {
  final SiteModel site;
  final VoidCallback onTap;
  final bool showScore;

  const SiteCard({
    super.key,
    required this.site,
    required this.onTap,
    this.showScore = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = statusColor(site.status);
    final weak = site.weakConditions.isEmpty ? null : site.weakConditions.first;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.surfaceLight.withValues(alpha: 0.55),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 13, 13, 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _RankBadge(rank: site.rank),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    site.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    site.analogType,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (showScore) ...[
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatScore(site.similarityScore),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Text(
                                    'relative',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 7,
                          runSpacing: 6,
                          children: [
                            StatusPill(status: site.status),
                            if (site.warningLevel == 'high')
                              const WarningPill(level: 'high')
                            else if (site.warningLevel == 'caution')
                              const WarningPill(level: 'caution'),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Icon(
                              weak == null
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.warning_amber_rounded,
                              color: weak == null
                                  ? AppColors.recommended
                                  : warningColor(site.warningLevel),
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                weak == null
                                    ? 'No reported weakness'
                                    : 'Weak: ${conditionLabel(weak.feature)} '
                                          '(${formatConditionValue(weak.feature, weak.siteValue)} vs '
                                          '${formatConditionValue(weak.feature, weak.referenceValue)})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textMuted,
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final isTop = rank <= 10;
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isTop
            ? AppColors.accent.withValues(alpha: 0.16)
            : AppColors.surfaceLight.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(11),
        border: isTop
            ? Border.all(color: AppColors.accent.withValues(alpha: 0.45))
            : null,
      ),
      child: Text(
        '#$rank',
        style: TextStyle(
          color: isTop ? AppColors.accent : AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
