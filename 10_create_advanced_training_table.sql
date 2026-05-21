-- ============================================
-- Step 10: Create advanced training table (Derived features + label)
-- Project: mimic-icu-project-496405
-- Dataset: mimic_ml
-- Output table: advanced_training_table
-- ============================================

-- Definitions:
-- cohort: first ICU stay per patient (subject_id)
-- label: 1 if any vasopressor started during ICU stay, else 0
-- vitals: first_day_vitalsign (min/max/mean vital signs) [2](https://onedrive.live.com/personal/5ad764691df1ff21/_layouts/15/doc.aspx?resid=9127864b-3f2b-453f-8ae6-35ba417b1a94&cid=5ad764691df1ff21)
-- labs: first_day_lab (min/max labs) [1](https://onedrive.live.com/personal/5ad764691df1ff21/_layouts/15/doc.aspx?resid=add68f46-ad57-4cfa-a71e-bf72772cc81f&cid=5ad764691df1ff21)
-- gcs: first_day_gcs (gcs_min + components) [3](https://onedrive.live.com/personal/5ad764691df1ff21/_layouts/15/doc.aspx?resid=a7269aaa-9662-4c38-963f-756f0c976acb&cid=5ad764691df1ff21)
-- uo: first_day_urine_output (urineoutput) [4](https://onedrive.live.com/personal/5ad764691df1ff21/_layouts/15/doc.aspx?resid=7bfc9d86-03d4-4369-93a3-2fc044022399&cid=5ad764691df1ff21)
-- ==========================================

CREATE OR REPLACE TABLE `mimic-icu-project-496405.mimic_ml.advanced_training_table` AS

WITH cohort AS (
  SELECT
    subject_id,
    stay_id,
    hadm_id
  FROM (
    SELECT *,
      ROW_NUMBER() OVER (PARTITION BY subject_id ORDER BY intime) AS rn
    FROM `physionet-data.mimiciv_3_1_icu.icustays`
  )
  WHERE rn = 1
),

labels AS (
  SELECT
    ie.stay_id,
    MIN(ie.starttime) AS vasopressor_start_time
  FROM `physionet-data.mimiciv_3_1_icu.inputevents` ie
  JOIN `physionet-data.mimiciv_3_1_icu.d_items` di
    ON ie.itemid = di.itemid
  GROUP BY ie.stay_id
)

SELECT
  c.subject_id,
  c.stay_id,

  vit.heart_rate_mean,
  vit.sbp_mean,
  vit.mbp_mean,
  vit.resp_rate_mean,
  vit.spo2_mean,

  lab.wbc_max,
  lab.platelets_min,
  lab.creatinine_max,
  lab.bun_max,

  gcs.gcs_min,
  uo.urineoutput,
  sofa.sofa,
  ch.charlson_comorbidity_index,

  CASE WHEN l.vasopressor_start_time IS NOT NULL THEN 1 ELSE 0 END AS label

FROM cohort c
LEFT JOIN labels l ON c.stay_id = l.stay_id
LEFT JOIN `physionet-data.mimiciv_3_1_derived.first_day_vitalsign` vit ON c.stay_id = vit.stay_id
LEFT JOIN `physionet-data.mimiciv_3_1_derived.first_day_lab` lab ON c.stay_id = lab.stay_id
LEFT JOIN `physionet-data.mimiciv_3_1_derived.first_day_gcs` gcs ON c.stay_id = gcs.stay_id
LEFT JOIN `physionet-data.mimiciv_3_1_derived.first_day_urine_output` uo ON c.stay_id = uo.stay_id
LEFT JOIN `physionet-data.mimiciv_3_1_derived.first_day_sofa` sofa ON c.stay_id = sofa.stay_id
LEFT JOIN `physionet-data.mimiciv_3_1_derived.charlson` ch ON c.hadm_id = ch.hadm_id

WHERE vit.heart_rate_mean IS NOT NULL;