-- ============================================
-- Step 7: Add Lactate Feature
-- ============================================

-- Definitions:
-- labevents = table storing lab test results
-- itemid = numeric ID representing a lab test
-- lactate = blood lactate level (marker of shock)
-- hadm_id = hospital admission ID (labs are linked to admission)
-- avg_lactate = average lactate per admission
-- label = 1 (vasopressor used), 0 (not used)

-- Goal:
-- Add lactate as a key lab feature for predicting vasopressor need

-- Clinical Insight:
-- High lactate strongly indicates shock and poor tissue perfusion

-- Method:
-- 1. Extract lactate values from labevents
-- 2. Filter using lactate itemids
-- 3. Compute average lactate per admission
-- 4. Join with ICU stays using hadm_id

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
  WHERE itemid IN (220179, 51)
  AND valuenum IS NOT NULL
  GROUP BY stay_id
),

lactate AS (
  SELECT
    hadm_id,
    AVG(valuenum) AS avg_lactate
  FROM `physionet-data.mimiciv_3_1_hosp.labevents`
  WHERE itemid = 50813   -- Lactate itemid
  AND valuenum IS NOT NULL
  GROUP BY hadm_id
)

SELECT
  c.subject_id,
  c.stay_id,
  c.hadm_id,
  c.intime,
  c.outtime,
  hr.avg_hr,
  bp.avg_sbp,
  lct.avg_lactate,
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
  ON c.stay_id = bp.stay_id
LEFT JOIN lactate lct
  ON c.hadm_id = lct.hadm_id;