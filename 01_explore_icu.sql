-- ============================================
-- Step 1: Data Exploration (ICU Stays Table)
-- ============================================

-- Definitions:
-- ICU = Intensive Care Unit (critical care setting)
-- subject_id = Unique patient identifier
-- hadm_id = Hospital admission ID
-- stay_id = ICU stay ID (each ICU episode)
-- intime = Time patient entered ICU
-- outtime = Time patient left ICU

-- Table:
-- icustays = Core ICU table that tracks ICU admissions and discharges

-- Goal:
-- Explore the structure and contents of the ICU stays table
-- Understand what data is available before building cohort and features

-- Method:
-- Select a small sample of rows to inspect columns and values

SELECT
  subject_id,
  stay_id,
  hadm_id,
  intime,
  outtime
FROM `physionet-data.mimiciv_3_1_icu.icustays`
LIMIT 100;