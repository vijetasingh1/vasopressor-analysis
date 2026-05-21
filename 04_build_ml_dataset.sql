-- ============================================
-- Step 4: Build Machine Learning Dataset
-- ============================================

-- Definitions:
-- cohort = first ICU stay per patient (from Step 2)
-- labels = vasopressor usage per ICU stay (from Step 3)
-- stay_id = ICU stay identifier (used to join tables)
-- label = binary outcome (1 = vasopressor used, 0 = no vasopressor)

-- Goal:
-- Combine cohort and vasopressor labels into ONE dataset
-- Each row = one patient ICU stay with outcome label

-- Method:
-- 1. Create cohort (first ICU stay)
-- 2. Create vasopressor labels
-- 3. LEFT JOIN cohort with labels
-- 4. Assign label:
--    - 1 if vasopressor exists
--    - 0 if not

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
)

SELECT
  c.subject_id,
  c.stay_id,
  c.hadm_id,
  c.intime,
  c.outtime,
  CASE 
    WHEN l.vasopressor_start_time IS NOT NULL THEN 1
    ELSE 0
  END AS label
FROM cohort c
LEFT JOIN labels l
ON c.stay_id = l.stay_id;
