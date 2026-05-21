CREATE OR REPLACE MODEL `mimic-icu-project-496405.mimic_ml.vasopressor_model_v3`
OPTIONS(
  model_type = 'logistic_reg',
  input_label_cols = ['label']
) AS

SELECT *
FROM `mimic-icu-project-496405.mimic_ml.advanced_training_table`;

-- Evaluate
SELECT *
FROM ML.EVALUATE(MODEL `mimic-icu-project-496405.mimic_ml.vasopressor_model_v3`);


---- Add Auto Class Weights(replaced/added to the above sql query to improve handling of class imbalance) ----
CREATE OR REPLACE MODEL `mimic-icu-project-496405.mimic_ml.vasopressor_model_v4`
OPTIONS(
  model_type = 'logistic_reg',
  input_label_cols = ['label'],
  auto_class_weights = TRUE
) AS
SELECT *
FROM `mimic-icu-project-496405.mimic_ml.advanced_training_table`;

-- Evaluate
SELECT *
FROM ML.EVALUATE(MODEL `mimic-icu-project-496405.mimic_ml.vasopressor_model_v4`);

