-- ============================================
-- Step 8: Train + Evaluate BigQuery ML Model
-- Project: mimic-icu-project-496405
-- Dataset: mimic_ml
-- Model: vasopressor_model
-- ============================================

-- Definitions:
-- cohort = first ICU stay per patient
-- labels = vasopressor start time per stay (positive cases)
-- avg_hr = average heart rate per stay (from chartevents)
-- avg_sbp = average systolic blood pressure per stay (from chartevents)
-- avg_lactate = average lactate per hospital admission (from labevents)
-- label = target variable (1 = vasopressor used, 0 = no vasopressor)

-- NOTE:
-- This creates the model inside YOUR project+dataset:
-- `mimic-icu-project-496405.mimic_ml.vasopressor_model`
-- Make sure dataset `mimic_ml` exists in location US.

CREATE OR REPLACE MODEL `mimic-icu-project-496405.mimic_ml.vasopressor_model`
OPTIONS(
  model_type = 'logistic_reg',
  input_label_cols = ['label']
) AS

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
  WHERE itemid IN (220045, 211)      -- Heart Rate itemids
    AND valuenum IS NOT NULL
  GROUP BY stay_id
),

blood_pressure AS (
  SELECT
    stay_id,
    AVG(valuenum) AS avg_sbp
  FROM `physionet-data.mimiciv_3_1_icu.chartevents`
  WHERE itemid IN (220179, 51)       -- Systolic BP itemids
    AND valuenum IS NOT NULL
  GROUP BY stay_id
),

lactate AS (
  SELECT
    hadm_id,
    AVG(valuenum) AS avg_lactate
  FROM `physionet-data.mimiciv_3_1_hosp.labevents`
  WHERE itemid = 50813               -- Lactate itemid
    AND valuenum IS NOT NULL
  GROUP BY hadm_id
)

SELECT
  -- Features
  hr.avg_hr,
  bp.avg_sbp,
  lct.avg_lactate,

  -- Label (target)
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
  ON c.hadm_id = lct.hadm_id

-- Keep only rows with complete features for first model
WHERE hr.avg_hr IS NOT NULL
  AND bp.avg_sbp IS NOT NULL
  AND lct.avg_lactate IS NOT NULL
;

-- ============================================
-- Evaluate the model
-- ============================================

SELECT *
FROM ML.EVALUATE(MODEL `mimic-icu-project-496405.mimic_ml.vasopressor_model`);