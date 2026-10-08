import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/components/app_card.dart';

class TrendsScreen extends StatelessWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trends & Charts'),
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingAllLg,
          child: AppCard(
            title: 'Longitudinal Trends',
            subtitle: 'Personal baseline trajectories over 7, 14, 30, and 90 days',
            child: Text(
              'Your historical metrics are recorded locally and synchronized. Advanced trend visualization charts will display here as your baseline matures.',
            ),
          ),
        ),
      ),
    );
  }
}
