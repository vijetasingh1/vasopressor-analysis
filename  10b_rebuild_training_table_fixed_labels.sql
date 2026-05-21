CREATE OR REPLACE TABLE `mimic-icu-project-496405.mimic_ml.advanced_training_table_v2` AS
WITH cohort AS (
  SELECT subject_id, stay_id, hadm_id
  FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY subject_id ORDER BY intime) AS rn
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
  WHERE LOWER(di.label) LIKE '%norepinephrine%'
     OR LOWER(di.label) LIKE '%epinephrine%'
     OR LOWER(di.label) LIKE '%vasopressin%'
     OR LOWER(di.label) LIKE '%dopamine%'
  GROUP BY ie.stay_id
)
SELECT
  c.subject_id,
  c.stay_id,

  -- Vitals (means) from first_day_vitalsign [1](https://oneuptime.com/blog/post/2026-02-17-how-to-build-a-classification-model-in-bigquery-ml-for-churn-prediction/view)
  vit.heart_rate_mean,
  vit.sbp_mean,
  vit.mbp_mean,
  vit.resp_rate_mean,
  vit.spo2_mean,

  -- Labs (subset) from first_day_lab [2](https://gist.github.com/alex-bezverkhniy/a48cbad3b1fd992ca474cefb76883741)
  lab.wbc_max,
  lab.platelets_min,
  lab.creatinine_max,
  lab.bun_max,
  lab.bilirubin_total_max,

  -- GCS from first_day_gcs [3](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-create-xgboost)
  gcs.gcs_min,

  -- Urine output from first_day_urine_output [4](https://dev.to/suzuki0430/bigquery-and-xgboost-integration-a-jupyter-notebook-tutorial-for-binary-classification-1ocb)
  uo.urineoutput,

  -- SOFA: keep non-cardiovascular parts to avoid leakage [1](https://oneuptime.com/blog/post/2026-02-17-how-to-build-a-classification-model-in-bigquery-ml-for-churn-prediction/view)
  sofa.respiration,
  sofa.coagulation,
  sofa.liver,
  sofa.cns,
  sofa.renal,

  -- Charlson comorbidity index [2](https://gist.github.com/alex-bezverkhniy/a48cbad3b1fd992ca474cefb76883741)
  ch.charlson_comorbidity_index,

  CASE WHEN l.vasopressor_start_time IS NOT NULL THEN 1 ELSE 0 END AS label
FROM cohort c
LEFT JOIN labels l ON c.stay_id = l.stay_id
LEFT JOIN `physionet-data.mimiciv_3_1_derived.first_day_vitalsign` vit ON c.stay_id = vit.stay_id
LEFT JOIN `physionet-data.mimiciv_3_1_derived.first_day_lab` lab ON c.stay_id = lab.stay_id
LEFT JOIN `physionet-data.mimiciv_3_1_derived.first_day_gcs` gcs ON c.stay_id = gcs.stay_id
LEFT JOIN `physionet-data.mimiciv_3_1_derived.first_day_urine_output` uo ON c.stay_id = uo.stay_id
LEFT JOIN `physionet-data.mimiciv_3_1_derived.first_day_sofa` sofa ON c.stay_id = sofa.stay_id
LEFT JOIN `physionet-data.mimiciv_3_1_derived.charlson` ch ON c.hadm_id = ch.hadm_id;