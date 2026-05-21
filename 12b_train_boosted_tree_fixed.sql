CREATE OR REPLACE MODEL `mimic-icu-project-496405.mimic_ml.vasopressor_boosted_tree_v2`
OPTIONS(
  model_type = 'BOOSTED_TREE_CLASSIFIER',
  input_label_cols = ['label'],
  max_iterations = 50,
  max_tree_depth = 6,
  learn_rate = 0.1,
  subsample = 0.8,
  colsample_bytree = 0.8
) AS
SELECT *
FROM `mimic-icu-project-496405.mimic_ml.advanced_training_table_v2`;

SELECT *
FROM ML.EVALUATE(MODEL `mimic-icu-project-496405.mimic_ml.vasopressor_boosted_tree_v2`);