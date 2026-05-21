-- ============================================
-- Step 12: Train Boosted Tree (XGBoost) model in BigQuery ML
-- Model type: BOOSTED_TREE_CLASSIFIER (trained using XGBoost)
-- ============================================

CREATE OR REPLACE MODEL `mimic-icu-project-496405.mimic_ml.vasopressor_boosted_tree_v1`
OPTIONS(
  model_type = 'BOOSTED_TREE_CLASSIFIER',
  input_label_cols = ['label'],

  -- Starter hyperparameters (safe defaults)
  max_tree_depth = 6,
  learn_rate = 0.1,
  subsample = 0.8,
  colsample_bytree = 0.8,
  max_iterations = 50,

  -- Optional: compute approximate global feature contributions
  approx_global_feature_contrib = TRUE
) AS
SELECT
  *
FROM `mimic-icu-project-496405.mimic_ml.advanced_training_table`
WHERE label IS NOT NULL;

-- Evaluate model
SELECT *
FROM ML.EVALUATE(MODEL `mimic-icu-project-496405.mimic_ml.vasopressor_boosted_tree_v1`);
