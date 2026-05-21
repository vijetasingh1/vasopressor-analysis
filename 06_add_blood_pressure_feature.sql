-- ============================================
-- Step 6: Add Blood Pressure Feature
-- ============================================

-- Definitions:
-- chartevents = table storing ICU vital signs
-- itemid = numeric ID representing a clinical variable
-- SBP = systolic blood pressure
-- avg_sbp = average systolic BP per ICU stay
-- stay_id = ICU stay identifier
-- label = 1 (vasopressor used), 0 (not used)

-- Goal:
-- Add systolic blood pressure as a key predictor feature

-- Clinical Insight:
-- Low BP is a major reason for vasopressor initiation

-- Method:
-- 1. Extract BP values from chartevents
-- 2. Filter using blood pressure itemids
-- 3. Compute average BP per ICU stay
-- 4. Join with dataset (cohort + labels + HR)

WITH cohort AS (
  SELECT
    subject_id,
    stay_id,
    hadm_id,
    intime,
    outtime
  FROM (
    SELECT
      subject_id,
      stay_id,
      hadm_id,
      intime,
      outtime,
      ROW_NUMBER() OVER (PARTITION BY subject_id ORDER BY intime) AS rn
    FROM `physionet-data.mimiciv_3_1_icu.icustays`
  )
  WHERE rn = 1
),

labels AS (
  SELECT
    ie.stay_id,
    MIN(ie.starttime) AS vasopressor_start_time
  FROM `physionet-data.mimiciv_3_1_icu.inputevents` AS ie
  JOIN `physionet-data.mimiciv_3_1_icu.d_items` AS di
    ON ie.itemid = di.itemid
  WHERE LOWER(di.label) LIKE '%norepinephrine%'
     OR LOWER(di.label) LIKE '%epinephrine%'
     OR LOWER(di.label) LIKE '%vasopressin%'
     OR LOWER(di.label) LIKE '%dopamine%'
  GROUP BY ie.stay_id
),

heart_rate AS (
  SELECT
    stay_id,
    AVG(valuenum) AS avg_hr
  FROM `physionet-data.mimiciv_3_1_icu.chartevents`
  WHERE itemid IN (220045, 211)
  AND valuenum IS NOT NULL
  GROUP BY stay_id
),

blood_pressure AS (
  SELECT
    stay_id,
    AVG(valuenum) AS avg_sbp
  FROM `physionet-data.mimiciv_3_1_icu.chartevents`
  WHERE itemid IN (
    220179,  -- Systolic BP (common ID)
    51       -- Systolic BP (older ID)
  )
  AND valuenum IS NOT NULL
  GROUP BY stay_id
)

SELECT
  c.subject_id,
  c.stay_id,
  c.hadm_id,
  c.intime,
  c.outtime,
  hr.avg_hr,
  bp.avg_sbp,
  CASE 
    WHEN l.vasopressor_start_time IS NOT NULL THEN 1
    ELSE 0
  END AS label
FROM cohort c
LEFT JOIN labels l
  ON c.stay_id = l.stay_id
LEFT JOIN heart_rate hr
  ON c.stay_id = hr.stay_id
LEFT JOIN blood_pressure bp
  ON c.stay_id = bp.stay_id;