-- ============================================
-- Step 9: Discover available derived feature tables & columns
-- Dataset: physionet-data.mimiciv_3_1_derived
-- ============================================

-- Goal:
-- 1) List all tables in the derived dataset
-- 2) Inspect columns for the most useful “first day” feature tables

-- Why:
-- The MIMIC concept/derived tables include standard feature sets such as:
-- first_day_vitalsign, first_day_lab, first_day_urine_output, first_day_gcs, first_day_sofa, etc.
-- (These are described in the MIMIC concepts repository.) [1](https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iv/concepts/README.md)

-- ------------------------------------------------------------
-- 9.1 List tables in the derived dataset
-- ------------------------------------------------------------
SELECT
  table_name
FROM `physionet-data.mimiciv_3_1_derived.INFORMATION_SCHEMA.TABLES`
ORDER BY table_name;

-- ------------------------------------------------------------
-- 9.2 Inspect columns for key derived tables (run each block)
-- ------------------------------------------------------------

-- first day vitals (commonly includes BP/HR/RR/Temp/SpO2 etc.) [1](https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iv/concepts/README.md)[3](https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iv/concepts/measurement/vitalsign.sql)
SELECT
  column_name, data_type
FROM `physionet-data.mimiciv_3_1_derived.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'first_day_vitalsign'
ORDER BY ordinal_position;

-- first day labs (commonly includes lactate + other labs) [1](https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iv/concepts/README.md)
SELECT
  column_name, data_type
FROM `physionet-data.mimiciv_3_1_derived.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'first_day_lab'
ORDER BY ordinal_position;

-- urine output (first day) [1](https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iv/concepts/README.md)
SELECT
  column_name, data_type
FROM `physionet-data.mimiciv_3_1_derived.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'first_day_urine_output'
ORDER BY ordinal_position;

-- GCS (first day) [1](https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iv/concepts/README.md)
SELECT
  column_name, data_type
FROM `physionet-data.mimiciv_3_1_derived.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'first_day_gcs'
ORDER BY ordinal_position;

-- SOFA (first day) - severity score [1](https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iv/concepts/README.md)
SELECT
  column_name, data_type
FROM `physionet-data.mimiciv_3_1_derived.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'first_day_sofa'
ORDER BY ordinal_position;

-- Charlson comorbidity index (if present) [1](https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iv/concepts/README.md)
SELECT
  column_name, data_type
FROM `physionet-data.mimiciv_3_1_derived.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'charlson'
ORDER BY ordinal_position;
