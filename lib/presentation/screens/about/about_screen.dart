import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parallax/core/constants/app_colors.dart';
import 'package:parallax/core/constants/app_typography.dart';
import 'package:parallax/core/widgets/app_background.dart';
import 'package:parallax/data/models/analogs_data.dart';
import 'package:parallax/logic/bloc/analog_bloc.dart';
import 'package:parallax/logic/bloc/analog_states.dart';

const _defaultWeights = [
  ('Temperature', 0.30),
  ('Atmosphere', 0.25),
  ('Radiation', 0.25),
  ('Moisture', 0.15),
  ('Terrain', 0.05),
];

const _groupKeys = [
  'temperature',
  'atmosphere',
  'radiation',
  'moisture',
  'terrain',
];

const _groupTitles = {
  'temperature': 'Temperature',
  'atmosphere': 'Atmosphere',
  'radiation': 'Radiation',
  'moisture': 'Moisture',
  'terrain': 'Terrain',
};

List<(String, double)> _weightsFrom(AnalogsData? data) {
  final raw = data?.settings['group_weights'];
  if (raw is! Map) return _defaultWeights;

  final weights = <(String, double)>[];
  for (final key in _groupKeys) {
    final value = raw[key];
    if (value is num) {
      weights.add((_groupTitles[key]!, value.toDouble()));
    }
  }
  return weights.isEmpty ? _defaultWeights : weights;
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      imageOpacity: 0.08,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Text(
              'About Parallax',
              style: AppTypography.screenTitle.copyWith(fontSize: 30),
            ),
            const SizedBox(height: 6),
            Text(
              'A decision tool for finding Earth sites that best simulate the Moon or Mars.',
              style: AppTypography.body.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 20),
            const _AboutCard(
              title: 'What is an analog site?',
              icon: Icons.public_rounded,
              child: Text(
                'An analog is a place on Earth whose environment resembles another world. Researchers use analogs to train crews, test equipment, and study geology before a mission. Parallax compares measured conditions at each site with reference conditions for the Moon and Mars.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 11),
            const _ScoreWeightsCard(),
            const SizedBox(height: 11),
            const _AboutCard(
              title: 'How to use it',
              icon: Icons.explore_rounded,
              child: Column(
                children: [
                  _StepRow(
                    number: '1',
                    text: 'Choose a target and set your mission priorities.',
                  ),
                  _StepRow(
                    number: '2',
                    text: 'Explore ranked sites and inspect their trade-offs.',
                  ),
                  _StepRow(
                    number: '3',
                    text: 'Compare up to 3 sites and generate a mission brief.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 11),
            const _AboutCard(
              title: 'Data sources',
              icon: Icons.dataset_outlined,
              child: Text(
                'The prototype combines Earth-site measurements with reference conditions for the Moon and Mars. Planned and referenced sources include NASA POWER, USGS, NASA fact sheets, and elevation data.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 11),
            const _AboutCard(
              title: 'Important limitations',
              icon: Icons.info_outline_rounded,
              accent: AppColors.warningCaution,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bullet(
                    text: 'Most sites in the current set are impact craters, so terrain diversity is limited.',
                  ),
                  _Bullet(
                    text: 'Temperature data describes air temperature, not surface temperature.',
                  ),
                  _Bullet(
                    text: 'Reference values are global averages, not specific regions.',
                  ),
                  _Bullet(
                    text: 'Soil composition, site access, logistics, cost, and permits are not included.',
                  ),
                  _Bullet(
                    text: 'The reported weak conditions cover each site\'s worst mismatches, not every measured difference.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.surfaceLight.withValues(alpha: 0.4),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.science_outlined,
                    color: AppColors.accent,
                    size: 18,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Built for researchers and mission planners first, and for everyone curious about Earth\'s planetary analogs second.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        height: 1.45,
                      ),
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

class _ScoreWeightsCard extends StatelessWidget {
  const _ScoreWeightsCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalogBloc, AnalogStates>(
      builder: (context, state) {
        final data = state is FetchAnalogsSuccess ? state.data : null;
        final weights = _weightsFrom(data);
        return _AboutCard(
          title: 'How the score works',
          icon: Icons.tune_rounded,
          child: Column(
            children: [
              for (var index = 0; index < weights.length; index++) ...[
                _WeightRow(label: weights[index].$1, weight: weights[index].$2),
                if (index != weights.length - 1) const SizedBox(height: 10),
              ],
              const SizedBox(height: 12),
              const Text(
                'Weights are read from the dataset settings. Scores are relative to the dataset: a score of 100 means the closest match in this set, not a perfect environmental replica.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  height: 1.45,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AboutCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color accent;

  const _AboutCard({
    required this.title,
    required this.icon,
    required this.child,
    this.accent = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.surfaceLight.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          child,
        ],
      ),
    );
  }
}

class _WeightRow extends StatelessWidget {
  final String label;
  final double weight;

  const _WeightRow({required this.label, required this.weight});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
            Text(
              '${(weight * 100).round()}%',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: weight,
            minHeight: 5,
            backgroundColor: AppColors.surfaceLight.withValues(alpha: 0.4),
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
          ),
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String text;

  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.circle, color: AppColors.warningCaution, size: 5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
