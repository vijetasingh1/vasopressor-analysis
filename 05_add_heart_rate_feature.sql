-- ============================================
-- Step 5: Add Heart Rate Feature
-- ============================================

-- Definitions:
-- chartevents = table storing ICU vital signs (heart rate, BP, etc.)
-- itemid = numeric ID representing a clinical variable
-- heart rate itemids = IDs corresponding to heart rate measurements
-- stay_id = ICU stay identifier
-- avg_hr = average heart rate per ICU stay
-- label = 1 (vasopressor used), 0 (not used)

-- Goal:
-- Add heart rate as a predictor feature for each ICU stay

-- Method:
-- 1. Extract heart rate values from chartevents
-- 2. Filter using heart rate itemids
-- 3. Calculate average heart rate per stay
-- 4. Join with ML dataset (from Step 4)

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

features AS (
  SELECT
    stay_id,
    AVG(valuenum) AS avg_hr
  FROM `physionet-data.mimiciv_3_1_icu.chartevents`
  WHERE itemid IN (
    220045,  -- Heart Rate (common ID)
    211      -- Heart Rate (older ID)
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
  f.avg_hr,
  CASE 
    WHEN l.vasopressor_start_time IS NOT NULL THEN 1
    ELSE 0
  END AS label
FROM cohort c
LEFT JOIN labels l
  ON c.stay_id = l.stay_id
LEFT JOIN features f
  ON c.stay_id = f.stay_id;