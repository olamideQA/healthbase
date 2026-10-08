import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/components/app_card.dart';

class WhatChangedScreen extends StatelessWidget {
  const WhatChangedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('What Changed?'),
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingAllLg,
          child: AppCard(
            title: 'Metric Delta Comparison',
            subtitle: 'Comparing recent vitals against historical baselines',
            child: Text(
              'Automated longitudinal metric comparisons identify statistically meaningful deviations from your personal baseline.',
            ),
          ),
        ),
      ),
    );
  }
}
