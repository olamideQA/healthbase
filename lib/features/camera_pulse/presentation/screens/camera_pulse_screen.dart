import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/components/app_button.dart';
import '../../../../core/theme/components/app_card.dart';
import '../../../profile/data/profile_repository.dart';
import '../providers/camera_pulse_controller.dart';

class CameraPulseScreen extends ConsumerStatefulWidget {
  const CameraPulseScreen({super.key});

  @override
  ConsumerState<CameraPulseScreen> createState() => _CameraPulseScreenState();
}

class _CameraPulseScreenState extends ConsumerState<CameraPulseScreen> {
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cameraPulseControllerProvider.notifier).checkSupport();
    });
  }

  Future<void> _saveAndReturn(String profileId) async {
    setState(() => _isSaving = true);
    final success = await ref
        .read(cameraPulseControllerProvider.notifier)
        .saveResult(profileId);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pulse measurement saved to your health record.'),
            backgroundColor: AppColors.statusStable,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save measurement.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cameraPulseControllerProvider);
    final controller = ref.read(cameraPulseControllerProvider.notifier);
    final profileAsync = ref.watch(myProfileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Pulse (PPG)'),
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.paddingAllLg,
          children: [
            // Mandatory Non-Diagnostic Clinical Disclaimer Banner
            Container(
              padding: AppSpacing.paddingAllMd,
              decoration: BoxDecoration(
                color: isDark ? AppColors.neutral800 : AppColors.neutral100,
                borderRadius: AppSpacing.roundedSm,
                border: Border.all(
                  color: isDark ? AppColors.neutral700 : AppColors.neutral200,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: AppColors.primary600,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Camera Pulse is an experimental monitoring estimate. It is not a medical diagnostic device or FDA-cleared pulse oximeter. Do not rely on this estimate for acute medical emergencies.',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.neutral300 : AppColors.neutral700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // State-based body view
            switch (state.status) {
              CameraPulseStatus.unsupported => _buildUnsupportedView(state),
              CameraPulseStatus.initial => _buildInstructionsView(controller),
              CameraPulseStatus.measuring => _buildMeasuringView(state, controller),
              CameraPulseStatus.completed => _buildCompletedView(
                  state: state,
                  controller: controller,
                  profileId: profileAsync.value?.id ?? 'self',
                ),
              _ => _buildInstructionsView(controller),
            },
          ],
        ),
      ),
    );
  }

  Widget _buildUnsupportedView(CameraPulseState state) {
    return AppCard(
      child: Column(
        children: [
          const Icon(
            Icons.camera_alt_outlined,
            size: 48,
            color: AppColors.neutral400,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Hardware Not Supported',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            state.errorMessage ??
                'Camera Pulse requires a mobile device with a rear camera and torch/flash.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.neutral500),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Back to Dashboard',
            variant: AppButtonVariant.outline,
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsView(CameraPulseController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How Camera Pulse Works',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildInstructionStep(
                number: '1',
                title: 'Place your fingertip',
                description:
                    'Gently cover the rear camera lens and flash with the tip of your index finger.',
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildInstructionStep(
                number: '2',
                title: 'Do not press too firmly',
                description:
                    'Pressing hard stops capillary blood flow. Rest your finger lightly and comfortably.',
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildInstructionStep(
                number: '3',
                title: 'Remain seated and still',
                description:
                    'Avoid talking or moving for 20 seconds. Motion will invalidate the reading.',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Start Pulse Measurement',
          icon: Icons.favorite,
          onPressed: () => controller.startMeasuring(),
        ),
      ],
    );
  }

  Widget _buildInstructionStep({
    required String number,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.primary100,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.primary700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                description,
                style: AppTypography.bodySmall.copyWith(color: AppColors.neutral500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMeasuringView(CameraPulseState state, CameraPulseController controller) {
    return Column(
      children: [
        // Live finger contact badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: state.isFingerDetected
                ? AppColors.statusStable.withValues(alpha: 0.15)
                : AppColors.statusIncreased.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: state.isFingerDetected
                  ? AppColors.statusStable
                  : AppColors.statusIncreased,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                state.isFingerDetected ? Icons.check_circle : Icons.touch_app,
                size: 16,
                color: state.isFingerDetected
                    ? AppColors.statusStable
                    : AppColors.statusIncreased,
              ),
              const SizedBox(width: 8),
              Text(
                state.isFingerDetected
                    ? 'Good Contact · Measuring...'
                    : 'Cover Camera & Flash Gently',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: state.isFingerDetected
                      ? AppColors.statusStable
                      : AppColors.statusIncreased,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Circular progress countdown
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: CircularProgressIndicator(
                value: state.progress,
                strokeWidth: 8,
                backgroundColor: AppColors.neutral200,
                color: AppColors.primary600,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${state.secondsRemaining}',
                  style: AppTypography.headlineLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'seconds left',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.neutral500),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // Live PPG optical waveform painter
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LIVE OPTICAL SIGNAL',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: AppColors.neutral500,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 80,
                width: double.infinity,
                child: CustomPaint(
                  painter: _LiveWaveformPainter(points: state.waveformPoints),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        AppButton(
          label: 'Cancel Recording',
          variant: AppButtonVariant.outline,
          onPressed: () => controller.reset(),
        ),
      ],
    );
  }

  Widget _buildCompletedView({
    required CameraPulseState state,
    required CameraPulseController controller,
    required String profileId,
  }) {
    final result = state.result;
    if (result == null) return const SizedBox.shrink();

    if (result.isConfident && result.estimatedBpm != null) {
      return Column(
        children: [
          AppCard(
            child: Column(
              children: [
                const Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 40,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  result.estimatedBpm!.toStringAsFixed(0),
                  style: AppTypography.displayLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary700,
                  ),
                ),
                Text(
                  'Beats Per Minute (Estimated)',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.neutral500),
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      label: 'Signal Quality',
                      value: '${(result.qualityScore * 100).toStringAsFixed(0)}%',
                    ),
                    _buildStatItem(
                      label: 'Peak Method',
                      value: '${result.peakMethodBpm?.toStringAsFixed(0) ?? "--"} bpm',
                    ),
                    _buildStatItem(
                      label: 'Spectral Method',
                      value: '${result.spectralMethodBpm?.toStringAsFixed(0) ?? "--"} bpm',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Save Measurement',
                  icon: Icons.check,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : () => _saveAndReturn(profileId),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: 'Retake',
                  variant: AppButtonVariant.outline,
                  icon: Icons.refresh,
                  onPressed: () => controller.startMeasuring(),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Rejected / Low Confidence State
    return Column(
      children: [
        AppCard(
          child: Column(
            children: [
              const Icon(
                Icons.help_outline_rounded,
                color: AppColors.statusIncreased,
                size: 44,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Could Not Get a Clear Reading',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                result.rejectionReason ??
                    'The optical signal was too noisy or irregular. Please remain seated, ensure good lighting, and keep your finger steady.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: AppColors.neutral500),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Try Again',
          icon: Icons.refresh,
          onPressed: () => controller.startMeasuring(),
        ),
      ],
    );
  }

  Widget _buildStatItem({required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.neutral500),
        ),
      ],
    );
  }
}

class _LiveWaveformPainter extends CustomPainter {
  const _LiveWaveformPainter({required this.points});

  final List<double> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final minVal = points.reduce((a, b) => a < b ? a : b);
    final maxVal = points.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal).clamp(1.0, 1000.0);

    final stepX = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final normY = (points[i] - minVal) / range;
      final y = size.height - (normY * (size.height - 10) + 5);
      final x = i * stepX;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiveWaveformPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
