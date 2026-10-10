import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:healthbase/core/theme/app_colors.dart';
import 'package:healthbase/core/theme/app_spacing.dart';
import 'package:healthbase/core/theme/app_typography.dart';
import 'package:healthbase/core/theme/components/app_button.dart';
import 'package:healthbase/core/theme/components/app_card.dart';
import 'package:healthbase/core/theme/components/app_loading_state.dart';
import 'package:healthbase/features/profile/data/profile_repository.dart';
import 'package:healthbase/features/reports/data/report_repository.dart';
import 'package:healthbase/features/reports/domain/models/health_report_data.dart';

class HealthReportsScreen extends ConsumerStatefulWidget {
  const HealthReportsScreen({super.key});

  @override
  ConsumerState<HealthReportsScreen> createState() => _HealthReportsScreenState();
}

class _HealthReportsScreenState extends ConsumerState<HealthReportsScreen> {
  ReportPeriod _selectedPeriod = ReportPeriod.days30;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _isExporting = false;

  Future<void> _exportPdf(HealthReportData data) async {
    setState(() => _isExporting = true);
    try {
      final service = ref.read(reportGeneratorServiceProvider);
      final pdfBytes = await service.generatePdfBytes(data);

      await Printing.layoutPdf(
        name: 'HealthBase_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
        onLayout: (format) async => pdfBytes,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _sharePdf(HealthReportData data) async {
    setState(() => _isExporting = true);
    try {
      final service = ref.read(reportGeneratorServiceProvider);
      final pdfBytes = await service.generatePdfBytes(data);

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'HealthBase_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileAsync = ref.watch(myProfileProvider);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Reports'),
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const AppLoadingState(message: 'Preparing health report data...'),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Profile not found.'));
            }

            final queryArgs = (
              profileId: profile.id,
              period: _selectedPeriod,
              customStart: _customStartDate,
              customEnd: _customEndDate,
            );
            final reportAsync = ref.watch(reportDataProvider(queryArgs));

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(reportDataProvider);
              },
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
                          Icons.medical_services_outlined,
                          size: 20,
                          color: AppColors.primary600,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'HealthBase is a health monitoring and record-keeping tool. This report is not a medical diagnosis. '
                            'Share with your qualified healthcare provider for clinical review.',
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

                  // Period Selection Chips
                  Text(
                    'SELECT REPORT PERIOD',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.neutral500,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 8.0,
                    children: [
                      ...[ReportPeriod.days7, ReportPeriod.days30, ReportPeriod.days90].map((period) {
                        final isSelected = _selectedPeriod == period;
                        return ChoiceChip(
                          label: Text(period.displayName),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedPeriod = period);
                            }
                          },
                        );
                      }),
                      ChoiceChip(
                        label: const Text('Custom...'),
                        selected: _selectedPeriod == ReportPeriod.custom,
                        onSelected: (selected) async {
                          if (selected) {
                            final pickedRange = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (pickedRange != null) {
                              setState(() {
                                _selectedPeriod = ReportPeriod.custom;
                                _customStartDate = pickedRange.start;
                                _customEndDate = pickedRange.end;
                              });
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  if (_selectedPeriod == ReportPeriod.custom && _customStartDate != null && _customEndDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Custom range: ${dateFormat.format(_customStartDate!)} - ${dateFormat.format(_customEndDate!)}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.primary600),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),

                  // Report Body
                  reportAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, _) => Center(child: Text('Error generating report: $err')),
                    data: (data) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Export Action Card
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Healthcare Provider Report',
                                            style: AppTypography.titleMedium.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${dateFormat.format(data.startDate)} to ${dateFormat.format(data.endDate)}',
                                            style: AppTypography.bodySmall.copyWith(
                                              color: AppColors.neutral500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                const Divider(),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppButton(
                                        label: 'Preview & Print',
                                        icon: Icons.print_outlined,
                                        isLoading: _isExporting,
                                        onPressed: _isExporting ? null : () => _exportPdf(data),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: AppButton(
                                        label: 'Share PDF',
                                        variant: AppButtonVariant.outline,
                                        icon: Icons.share_outlined,
                                        isLoading: _isExporting,
                                        onPressed: _isExporting ? null : () => _sharePdf(data),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // 2. Vitals & Measurements Overview
                          Text(
                            'MEASUREMENT SUMMARY & RANGES',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.neutral500,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ...data.metricSummaries.map((m) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: AppCard(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            m.type.displayName,
                                            style: AppTypography.titleSmall.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            m.summaryText,
                                            style: AppTypography.bodySmall.copyWith(
                                              color: isDark ? AppColors.neutral300 : AppColors.neutral700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${m.readingCount} entries',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.neutral500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: AppSpacing.lg),

                          // 3. Medication Adherence
                          Text(
                            'MEDICATION ADHERENCE',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.neutral500,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (data.medications.isEmpty)
                            AppCard(
                              child: Text(
                                'No medications recorded in this timeframe.',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.neutral500),
                              ),
                            )
                          else
                            ...data.medications.map((med) {
                              final rate = med.stats.recordedAdherenceRate != null
                                  ? '${med.stats.recordedAdherenceRate!.toStringAsFixed(0)}%'
                                  : 'N/A';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: AppCard(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              med.name,
                                              style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              '${med.dosage} · ${med.frequency}',
                                              style: AppTypography.bodySmall.copyWith(color: AppColors.neutral500),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            rate,
                                            style: AppTypography.titleMedium.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.statusStable,
                                            ),
                                          ),
                                          Text(
                                            '${med.stats.takenCount} taken / ${med.stats.missedCount} missed',
                                            style: const TextStyle(fontSize: 10, color: AppColors.neutral500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          const SizedBox(height: AppSpacing.lg),

                          // 4. Logged Symptoms
                          Text(
                            'LOGGED SYMPTOMS',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.neutral500,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (data.symptoms.isEmpty)
                            AppCard(
                              child: Text(
                                'No symptoms reported during this period.',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.neutral500),
                              ),
                            )
                          else
                            ...data.symptoms.map((s) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: AppCard(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(s.name, style: AppTypography.bodyMedium),
                                      Text(
                                        '${s.occurrences}x (Last: ${dateFormat.format(s.mostRecentDate)})',
                                        style: AppTypography.bodySmall.copyWith(color: AppColors.neutral500),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          const SizedBox(height: AppSpacing.lg),

                          // 5. Notable Changes
                          if (data.notableChanges.isNotEmpty) ...[
                            Text(
                              'STATISTICAL OBSERVATIONS',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.neutral500,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ...data.notableChanges.map((change) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: AppCard(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.arrow_right, size: 20, color: AppColors.primary600),
                                      const SizedBox(width: AppSpacing.xs),
                                      Expanded(
                                        child: Text(change, style: AppTypography.bodySmall),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
