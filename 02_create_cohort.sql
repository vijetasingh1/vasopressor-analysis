-- ============================================
-- Step 2: Cohort Creation (First ICU Stay)
-- ============================================

-- Definitions:
-- ICU = Intensive Care Unit
-- subject_id = Unique patient identifier
-- hadm_id = Hospital admission ID
-- stay_id = ICU stay ID (each ICU episode)
-- intime = Time patient entered ICU
-- outtime = Time patient left ICU
-- rn = Row number assigned per patient (used to select first stay)

-- Goal:
-- Select ONE ICU stay per patient (the first ICU stay)
-- This defines the base population (cohort) for the ML model

-- Method:
-- 1. Partition by patient (subject_id)
-- 2. Order ICU stays by admission time (intime)
-- 3. Assign row numbers (rn)
-- 4. Select the first stay (rn = 1)

WITH ranked_stays AS (
  SELECT
    subject_id,
    stay_id,
    hadm_id,
    intime,
    outtime,
    ROW_NUMBER() OVER (PARTITION BY subject_id ORDER BY intime) AS rn
  FROM `physionet-data.mimiciv_3_1_icu.icustays`
)

SELECT
  subject_id,
  stay_id,
  hadm_id,
  intime,
  outtime
FROM ranked_stays
WHERE rn = 1;