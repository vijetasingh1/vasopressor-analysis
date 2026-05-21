-- ============================================
-- Step 3: Vasopressor Label Creation
-- ============================================

-- Definitions:
-- IE = inputevents (medication administration table)
-- DI = d_items (dictionary table for itemid → drug name/label)
-- stay_id = ICU stay identifier
-- itemid = numeric ID for medication
-- label = human-readable drug name

-- Goal:
-- Identify ICU stays where vasopressors were administered

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
GROUP BY ie.stay_id;
