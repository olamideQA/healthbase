# HealthBase — Clinical Review Register & Medical Safety Policy

**Document ID:** HBASE-CLIN-REG-2026-V1  
**Classification:** Medical Device Boundary & Clinical Algorithm Audit  
**Status:** Complete / Ready for Pre-Deployment Clinical Review  
**Audited Against:** HealthBase Build Playbook Loop 14 (Safety & Clinical Boundaries)

---

## 1. Executive Medical-Safety Statement

HealthBase is designed and architected as a **personal health-monitoring and record-keeping tool**. 
It is **NOT an FDA-cleared diagnostic device, emergency telemedicine system, or software as a medical device (SaMD) diagnostic engine**.

### Core Clinical Tenets
1. **Zero Diagnostic Claims:** The application NEVER claims to diagnose, cure, mitigate, treat, or prevent any illness, cardiac arrhythmia, or metabolic disorder.
2. **Authoritative Evidence Citations:** All categories, statistical indicators, and baseline comparisons cite recognized public health guidelines (AHA/ACC, ADA, WHO, CDC, NICE). No arbitrary or "AI-hallucinated" thresholds exist in the codebase.
3. **No False Reassurance:** When values fall within reference ranges, the system uses objective terminology (e.g., *"Within standard guideline target"*) rather than unqualified reassurance (e.g., *"You are 100% healthy"* or *"No need to see a doctor"*).
4. **No Unnecessary Alarm:** Boundary deviations are labeled factually with guideline source names and calm guidance.
5. **Urgent Care Prioritization:** For acute red-flag symptoms or vital signs in the crisis spectrum, self-monitoring is immediately deprioritized in favor of direct emergency care routing (911, 112, 999, 000).

---

## 2. Clinical Thresholds Master Register

Every clinical rule and cutoff in HealthBase is isolated in `lib/core/safety/clinical_thresholds.dart` and reviewed below.

| Metric | Category / Stage | Numerical Boundary | Guideline Authority & Citation | Clinical Rationale & Triage Action |
| :--- | :--- | :--- | :--- | :--- |
| **Blood Pressure** | Normal | Systolic < 120 mmHg **and** Diastolic < 80 mmHg | AHA/ACC (2017) High Blood Pressure Guidelines | Optimal cardiovascular baseline. Standard logging without alert. |
| **Blood Pressure** | Elevated | Systolic 120–129 mmHg **and** Diastolic < 80 mmHg | AHA/ACC (2017) Section 3.2 | Lifestyle awareness; not classified as hypertension. |
| **Blood Pressure** | Stage 1 Range | Systolic 130–139 mmHg **or** Diastolic 80–89 mmHg | AHA/ACC (2017) Section 3.2 | Informational awareness. User advised to discuss frequency with physician. |
| **Blood Pressure** | Stage 2 Range | Systolic ≥ 140 mmHg **or** Diastolic ≥ 90 mmHg | AHA/ACC (2017) Section 3.2 | Prompts recommendation to schedule routine clinical evaluation. |
| **Blood Pressure** | **Hypertensive Crisis** | **Systolic > 180 mmHg or Diastolic > 120 mmHg** | **AHA/ACC (2017) Section 11.2** | **Critical Urgent Alert.** Triggers immediate emergency prompt if symptoms present. |
| **Blood Pressure** | Hypotension | Systolic < 90 mmHg **or** Diastolic < 60 mmHg | AHA Clinical Criteria | Prompts postural precautions (sit/lie down) and physician review if symptomatic. |
| **Heart Rate** | Normal Adult Resting | 60 – 100 BPM | CDC / AHA Adult Vitals Guidelines | Physiological resting norm for non-athletic adults. |
| **Heart Rate** | Bradycardia | < 60 BPM | CDC Vitals Reference | Statistical note. Common in endurance athletes; consult if fatigued/faint. |
| **Heart Rate** | **Severe Bradycardia** | **< 40 BPM** | **AHA Emergency Cardiovascular Care** | **Critical Urgent Alert.** Risk of hemodynamic instability. Prompt medical review. |
| **Heart Rate** | Tachycardia | > 100 BPM | CDC Vitals Reference | Suggests review of caffeine, stress, fever, or doctor consultation if persistent. |
| **Heart Rate** | **Severe Tachycardia** | **> 140 BPM (resting)** | **AHA Arrhythmia Guidelines** | **Critical Urgent Alert.** Prompts prompt medical evaluation. |
| **Blood Glucose** | Fasting Normal | 3.9 – 5.5 mmol/L (70 – 99 mg/dL) | ADA Standards of Care (2024) Chap 2 | Standard fasting reference level. |
| **Blood Glucose** | Impaired / Post-meal | 5.6 – 6.9 mmol/L (100 – 125 mg/dL) | ADA Standards of Care (2024) | Expected post-meal; notes impaired fasting if fasting. |
| **Blood Glucose** | Diabetes Range | ≥ 7.0 mmol/L (126 mg/dL) fasting | ADA Standards of Care (2024) | Recommends clinician consultation for diagnostic testing (A1c/OGTT). |
| **Blood Glucose** | Level 1 Hypoglycemia | < 3.9 mmol/L (70 mg/dL) | ADA Standards of Care (2024) Chap 6 | Prompts immediate carbohydrate intake (Rule of 15). |
| **Blood Glucose** | **Level 2 Hypoglycemia** | **< 3.0 mmol/L (54 mg/dL)** | **ADA Standards of Care (2024) Chap 6** | **Critical Urgent Alert.** Neuroglycopenic risk. Emergency action if confused. |
| **Blood Glucose** | **Severe Hyperglycemia**| **> 16.7 mmol/L (300 mg/dL)** | **ADA Standards of Care (2024)** | **Critical Urgent Alert.** Diabetic ketoacidosis (DKA) / HHS risk. Urgent care. |
| **Temperature** | Normal | 36.1 – 37.2 °C (97.0 – 99.0 °F) | CDC / NICE Guidelines | Standard homeostatic body temperature. |
| **Temperature** | Low-grade | 37.3 – 37.9 °C (99.1 – 100.2 °F) | CDC Guidelines | Mild elevation. Hydration advised. |
| **Temperature** | Fever (Pyrexia) | ≥ 38.0 °C (100.4 °F) | CDC Guidelines | Advises rest, fluids, and clinical review if fever persists > 3 days. |
| **Temperature** | **High Fever** | **≥ 39.5 °C (103.1 °F)** | **NICE Fever Assessment Guidelines** | **Critical Urgent Alert.** Prompt clinical assessment. |
| **Temperature** | **Hypothermia** | **< 35.0 °C (95.0 °F)** | **CDC Hypothermia Criteria** | **Critical Urgent Alert.** Re-warming and immediate clinical review. |
| **SpO2 (Pulse Ox)**| Normal | ≥ 95% | WHO Pulse Oximetry Manual (2020) | Standard arterial oxygen saturation. |
| **SpO2 (Pulse Ox)**| Borderline Low | 90% – 94% | WHO Clinical Management | Indicates potential mild hypoxemia. |
| **SpO2 (Pulse Ox)**| **Critical Hypoxia** | **< 90%** | **WHO Clinical Management** | **Critical Urgent Alert.** Urgent medical oxygenation / emergency evaluation. |

---

## 3. Physical Plausibility Guards (Typo & Sensor Corruption Rejection)

Physical plausibility bounds strictly reject corrupt or impossible entries before saving to local Drift SQLite or synchronizing to Supabase:
- **Systolic / Diastolic Relationship:** Must satisfy `systolic > diastolic`. Inverted entries (e.g., 80/120) are blocked.
- **Heart Rate:** `25.0 ≤ BPM ≤ 250.0`.
- **Systolic Pressure:** `40.0 ≤ mmHg ≤ 300.0`.
- **Diastolic Pressure:** `30.0 ≤ mmHg ≤ 200.0`.
- **Core Temperature:** `30.0 ≤ °C ≤ 45.0` (86.0 °F – 113.0 °F).
- **Body Weight:** `1.0 ≤ kg ≤ 400.0` (2.2 lbs – 881.8 lbs).
- **Blood Glucose:** `0.5 ≤ mmol/L ≤ 45.0` (9.0 mg/dL – 810.0 mg/dL).

---

## 4. Red-Flag Symptoms & Emergency Routing Protocol

The following red-flag symptoms are defined in `EmergencyProtocols.redFlagSymptoms` (`lib/core/safety/emergency_protocols.dart`):
1. **Chest discomfort, tightness, or pressure**
2. **Severe or sudden shortness of breath**
3. **Sudden numbness or facial/limb weakness**
4. **Difficulty speaking or slurred speech**
5. **Sudden thunderclap severe headache**
6. **Loss of consciousness or acute syncope**
7. **Coughing up blood (hemoptysis)**
8. **Sudden loss of vision or diplopia**

### Clinical Behavior
- When any red-flag symptom is selected during the Daily Check:
  1. The app renders a persistent high-contrast **Urgent Medical Advisory Banner**.
  2. The app surfaces a direct **Emergency Directory** modal offering one-tap calling to local regional dispatch centers (`911` for US/CA, `999` for UK, `112` for EU/Universal, `000` for Australia).
  3. The app explicitly instructs: *"Do NOT delay emergency medical attention to record data in this application."*

---

## 5. Camera Pulse (PPG) Clinical Safety Controls

Implemented in Loop 13 and re-audited under Loop 14:
1. **Mandatory Non-Diagnostic Disclaimer:** Displayed before, during, and after any pulse estimate.
2. **Dual-Method Discrepancy Gate:** If Time-Domain Inter-Beat Interval (IBI) and Frequency-Domain Autocorrelation Spectral Peak diverge by more than **6 BPM**, no number is displayed; the reading is rejected.
3. **Signal Quality Gate:** Quality score must exceed **0.60** (60%). Flatline, high noise, or insufficient finger contact results in rejection.
4. **Zero Frame Storage Rule:** Video frames are analyzed solely in memory as raw RGB arithmetic means and immediately garbage-collected; zero images or video files are written to disk.
5. **Provenance Tagging:** All camera pulse measurements saved to the database are permanently tagged with `source: camera` and `provenance: estimated`.

---

## 6. Terminology Audit: Removed vs. Approved Copy

| Screen / Component | Deprecated / Prohibited Phrasing | Approved Clinical-Grade Phrasing |
| :--- | :--- | :--- |
| **Onboarding** | "HealthBase diagnoses your health." | "HealthBase is a personal health-monitoring and record-keeping tool." |
| **Personal Baseline** | "Your normal clinical baseline." | "Your personal range reflects your own historical measurements over time. It is a statistical baseline and does not represent a clinical diagnosis." |
| **What Changed?** | "Your blood pressure is abnormal." | "Notable difference: Blood pressure is higher than your recent baseline. Consult your physician if persistent." |
| **Daily Check** | "You have no health issues." | "No symptoms selected today." |
| **Add Measurement** | Silent save of 200/130 mmHg. | Immediate live Urgent Care Alert Banner + confirmation modal advising emergency services. |
| **Trends & Charts** | "Projected recovery timeline." | "Trend lines illustrate statistical progression across your personal logged entries." |
| **Reports (PDF)** | "Medical Diagnostic Summary." | "Personal Health Report: Compiled from self-recorded measurements to assist in discussions with your physician." |

---

## 7. Pre-Production Clinical Board Sign-Off Checklist

Before releasing HealthBase to app stores or production patient cohorts:
- [x] All thresholds verified against AHA/ACC, ADA, WHO, CDC, and NICE published literature.
- [x] Plausibility guards active on all measurement entry forms.
- [x] Emergency red-flag symptoms equipped with direct regional emergency calling assistance.
- [x] Camera Pulse dual-method agreement and quality rejection gates verified with automated tests.
- [x] Zero frame retention rule confirmed in memory lifecycle.
- [x] All screens display non-diagnostic clinical disclaimers.
- [ ] Final institutional review by Medical Director / Clinical Safety Officer.
