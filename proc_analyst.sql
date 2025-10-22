-- PREVIEW DATA --
SELECT * 
FROM `procurement-analyst.procurement.proc_dummy`
LIMIT 5;

-- ==========================
-- 🧹 DATA CLEANING
-- ==========================

-- 1. Check total rows and NULL values --
SELECT 
  COUNT(*) AS total_rows,
  COUNTIF(procurement_id_number IS NULL OR TRIM(procurement_id_number) = '') AS null_or_empty_count
FROM `procurement-analyst.procurement.proc_dummy`;

-- Check which rows have NULL id_number --
SELECT *
FROM `procurement-analyst.procurement.proc_dummy`
WHERE procurement_id_number IS NULL 
   OR TRIM(procurement_id_number) = '';

-- 2. Remove rows with NULL procurement_id_number --
CREATE OR REPLACE TABLE `procurement-analyst.procurement.proc_dummy_clean` AS
SELECT *
FROM `procurement-analyst.procurement.proc_dummy`
WHERE procurement_id_number IS NOT NULL
  AND TRIM(procurement_id_number) != '';

-- Recheck after cleaning --
SELECT 
  COUNT(*) AS total_rows,
  COUNTIF(procurement_id_number IS NULL OR TRIM(procurement_id_number) = '') AS null_or_empty_count
FROM `procurement-analyst.procurement.proc_dummy_clean`;

-- 3. Check for duplicate procurement IDs --
SELECT 
  procurement_id_number,
  COUNT(*) AS duplicates
FROM `procurement-analyst.procurement.proc_dummy_clean`
GROUP BY procurement_id_number
HAVING COUNT(*) > 1
ORDER BY duplicates DESC;

-- ==========================
-- 🔄 DATA TRANSFORMATION
-- ==========================

-- 1. Convert string dates to DATE format --
CREATE OR REPLACE TABLE `procurement-analyst.procurement.proc_dummy_clean` AS
SELECT
  *,
  SAFE.PARSE_DATE('%d/%m/%Y', form_date) AS form_date,
  SAFE.PARSE_DATE('%d/%m/%Y', actual_spmp_wo_date) AS actual_spmp_wo_date
FROM `procurement-analyst.procurement.proc_dummy_clean`;

-- 2. Clean numeric columns (remove text/characters) --
CREATE OR REPLACE TABLE `procurement-analyst.procurement.proc_dummy_clean` AS
SELECT
  *,
  SAFE_CAST(
    REPLACE(
      REGEXP_REPLACE(order_value, r'[^0-9,\.]', ''),
      ',', '.') AS FLOAT64
  ) AS order_value,
  SAFE_CAST(
    REPLACE(
      REGEXP_REPLACE(final_procurement_value, r'[^0-9,\.]', ''), 
      ',', '.') AS FLOAT64
  ) AS final_procurement_value
FROM `procurement-analyst.procurement.proc_dummy_clean`;

-- 3. Fill NULL values & calculate efficiency --
CREATE OR REPLACE TABLE `procurement-analyst.procurement.proc_dummy_clean` AS
SELECT
    *,
    CASE
        WHEN order_value IS NULL AND final_procurement_value IS NOT NULL THEN final_procurement_value
        ELSE order_value
    END AS order_value_filled,
    CASE
        WHEN final_procurement_value IS NULL AND order_value IS NOT NULL THEN order_value
        ELSE final_procurement_value
    END AS final_value_filled,
    CASE
        WHEN order_value IS NULL OR final_procurement_value IS NULL THEN 0
        ELSE order_value - final_procurement_value
    END AS efficiency2
FROM `procurement-analyst.procurement.proc_dummy_clean`;

SELECT procurement_id_number,order_value,final_procurement_value,order_value_filled,final_value_filled,efficiency2
FROM `procurement-analyst.procurement.proc_dummy_clean` 
ORDER BY efficiency ASC;

-- ==========================
-- ⏱ SLA CALCULATION
-- ==========================

-- 4.1 Working Days SLA (excluding weekends & holidays)
CREATE OR REPLACE TABLE `procurement-analyst.procurement.proc_dummy_clean` AS
WITH holidays AS (
  SELECT DATE '2021-01-01' AS holiday UNION ALL
  SELECT DATE '2021-02-12' UNION ALL
  SELECT DATE '2021-03-11' UNION ALL
  SELECT DATE '2021-03-14' UNION ALL
  SELECT DATE '2021-04-02' UNION ALL
  SELECT DATE '2021-05-01' UNION ALL
  SELECT DATE '2021-05-13' UNION ALL
  SELECT DATE '2021-05-14' UNION ALL
  SELECT DATE '2021-05-26' UNION ALL
  SELECT DATE '2021-06-01' UNION ALL
  SELECT DATE '2021-07-20' UNION ALL
  SELECT DATE '2021-08-10' UNION ALL
  SELECT DATE '2021-08-17' UNION ALL
  SELECT DATE '2021-10-19' UNION ALL
  SELECT DATE '2021-12-24' UNION ALL
  SELECT DATE '2021-12-25' UNION ALL
  SELECT DATE '2021-12-27' UNION ALL
  SELECT DATE '2022-01-01' UNION ALL
  SELECT DATE '2022-02-01' UNION ALL
  SELECT DATE '2022-02-28' UNION ALL
  SELECT DATE '2022-03-03' UNION ALL
  SELECT DATE '2022-04-15' UNION ALL
  SELECT DATE '2022-04-29' UNION ALL
  SELECT DATE '2022-05-01' UNION ALL
  SELECT DATE '2022-05-02' UNION ALL
  SELECT DATE '2022-05-03' UNION ALL
  SELECT DATE '2022-05-04' UNION ALL
  SELECT DATE '2022-05-05' UNION ALL
  SELECT DATE '2022-05-06' UNION ALL
  SELECT DATE '2022-05-16' UNION ALL
  SELECT DATE '2022-05-26' UNION ALL
  SELECT DATE '2022-06-01' UNION ALL
  SELECT DATE '2022-07-09' UNION ALL
  SELECT DATE '2022-07-30' UNION ALL
  SELECT DATE '2022-08-17' UNION ALL
  SELECT DATE '2022-10-08' UNION ALL
  SELECT DATE '2022-12-25'
),
data_sla AS (
  SELECT *
  FROM `procurement-analyst.procurement.proc_dummy_clean`
  WHERE form_date IS NOT NULL
    AND actual_spmp_wo_date IS NOT NULL
    AND actual_spmp_wo_date > form_date
)
SELECT 
  *,
  ARRAY_LENGTH(
    ARRAY(
      SELECT dt
      FROM UNNEST(GENERATE_DATE_ARRAY(form_date, actual_spmp_wo_date)) AS dt
      WHERE EXTRACT(DAYOFWEEK FROM dt) NOT IN (1,7)
        AND dt NOT IN (SELECT holiday FROM holidays)
    )
  ) - IFNULL(SAFE_CAST(waiting_time_workdays AS INT64), 0) AS sla_working_days
FROM data_sla;

-- Preview SLA results
SELECT procurement_id_number,form_date,actual_spmp_wo_date,sla_working_days
FROM `procurement-analyst.procurement.proc_dummy_clean` LIMIT 10;

-- 4.2 SLA Standard by Procurement Method
CREATE OR REPLACE TABLE `procurement-analyst.procurement.proc_dummy_clean` AS
SELECT 
  *,
  CASE 
    WHEN procurement_method = "Penunjukan Langsung" THEN 10
    WHEN procurement_method = "Work Order" THEN 3
    WHEN procurement_method = "Pemilihan Langsung" THEN 15
    WHEN procurement_method = "PADI UMKM" THEN 10
    ELSE 0
  END AS sla_standard
FROM `procurement-analyst.procurement.proc_dummy_clean`;

-- Preview SLA results
SELECT procurement_id_number,procurement_method,form_date,actual_spmp_wo_date,sla_working_days, sla_standard
FROM `procurement-analyst.procurement.proc_dummy_clean` LIMIT 10;

-- 4.3 SLA Percentage
CREATE OR REPLACE TABLE `procurement-analyst.procurement.proc_dummy_clean` AS
SELECT
  *,
  CASE 
    WHEN SAFE_CAST(sla_working_days AS FLOAT64) > 0 THEN 
      ROUND((sla_standard / SAFE_CAST(sla_working_days AS FLOAT64)) * 100, 2)
    ELSE NULL
  END AS sla_percentage
FROM `procurement-analyst.procurement.proc_dummy_clean`;

-- Preview SLA results
SELECT procurement_id_number,procurement_pic,procurement_method,form_date,actual_spmp_wo_date,sla_working_days, sla_standard,sla_percentage
FROM `procurement-analyst.procurement.proc_dummy_clean` LIMIT 10;

-- 4.4 SLA Flagging
CREATE OR REPLACE TABLE `procurement-analyst.procurement.proc_dummy_clean` AS
SELECT
  *,
  CASE
    WHEN sla_percentage >= 100 THEN 'Achieved'
    WHEN sla_percentage < 100 THEN 'Not Achieved'
    ELSE NULL
  END AS sla_flagging
FROM `procurement-analyst.procurement.proc_dummy_clean`;

-- Preview SLA results
SELECT procurement_id_number,procurement_pic, procurement_method,form_date, actual_spmp_wo_date, sla_working_days, sla_standard, sla_percentage, sla_flagging
FROM `procurement-analyst.procurement.proc_dummy_clean`
LIMIT 10;

-- ==========================
-- 📊 DATA ANALYSIS
-- ==========================

-- 1. Most Frequent Procurement Type
SELECT 
  procurement_method,
  COUNT(DISTINCT procurement_id_number) AS total_procurements
FROM `procurement-analyst.procurement.proc_dummy_clean`
GROUP BY procurement_method
ORDER BY total_procurements DESC;

-- 2. Monthly and Yearly Procurement Volume
SELECT
  EXTRACT(YEAR FROM form_date) AS year,
  EXTRACT(MONTH FROM form_date) AS month,
  COUNT(DISTINCT procurement_id_number) AS total_procurements
FROM `procurement-analyst.procurement.proc_dummy_clean`
GROUP BY year, month
ORDER BY year, month;

-- 3. Procurement Efficiency Classification
WITH efficiency_summary AS (
  SELECT
    CASE
      WHEN efficiency2 > 0 THEN 'Efficient'
      WHEN efficiency2 < 0 THEN 'Over Budget'
      ELSE 'Same (No Difference)'
    END AS efficiency_status,
    COUNT(*) AS total_projects,
    SUM(ABS(efficiency2)) AS total_difference
  FROM `procurement-analyst.procurement.proc_dummy_clean`
  WHERE order_value IS NOT NULL
    AND final_procurement_value IS NOT NULL
  GROUP BY efficiency_status
)

SELECT
  efficiency_status,
  total_projects,
  ROUND(total_projects * 100.0 / SUM(total_projects) OVER(), 2) AS percentage_of_projects,
  total_difference
FROM efficiency_summary
ORDER BY percentage_of_projects DESC;

-- 4. Average SLA Performance by Procurement Method
SELECT
  procurement_method,
  ROUND(AVG(sla_percentage), 2) AS avg_sla_percentage,
  COUNT(*) AS total_projects,
  SUM(CASE WHEN sla_flagging = 'Achieved' THEN 1 ELSE 0 END) AS achieved_count,
  SUM(CASE WHEN sla_flagging = 'Not Achieved' THEN 1 ELSE 0 END) AS not_achieved_count
FROM `procurement-analyst.procurement.proc_dummy_clean`
GROUP BY procurement_method
ORDER BY avg_sla_percentage DESC;

-- 5. Top 10 PICs with the Best SLA Performance
SELECT
  procurement_pic,
  ROUND(AVG(sla_percentage), 2) AS avg_sla_percentage,
  COUNT(*) AS total_procurements,
  SUM(CASE WHEN sla_flagging = 'Achieved' THEN 1 ELSE 0 END) AS achieved_count
FROM `procurement-analyst.procurement.proc_dummy_clean`
GROUP BY procurement_pic
HAVING COUNT(*) > 3  -- filter minimal 3 projects
ORDER BY avg_sla_percentage DESC
LIMIT 10;

-- 6. Top Efficient PICs Based on Total Efficiency
SELECT
  procurement_pic AS PIC_Name,
  COUNT(DISTINCT procurement_id_number) AS Total_Procurement,
  SUM(efficiency2) AS Total_Savings,
  AVG(efficiency2) AS Avg_Savings_Per_Procurement,
  SAFE_DIVIDE(SUM(efficiency2), SUM(order_value_filled)) * 100 AS Efficiency_Percentage
FROM
  `procurement-analyst.procurement.proc_dummy_clean`
WHERE
  efficiency2 > 0 -- hanya yang efisien (hemat)
GROUP BY
  PIC_Name
ORDER BY
  Total_Savings DESC;

-- 7. SLA Summary
SELECT
  COUNT(DISTINCT procurement_id_number) AS total_procurement,
  ROUND(AVG(sla_percentage), 2) AS avg_sla_percentage,
  SUM(CASE WHEN sla_flagging = 'Achieved' THEN 1 ELSE 0 END) AS total_achieved_sla,
  SUM(CASE WHEN sla_flagging = 'Not Achieved' THEN 1 ELSE 0 END) AS total_not_achieved_sla,
  ROUND(
    SAFE_DIVIDE(
      SUM(CASE WHEN sla_flagging = 'Achieved' THEN 1 ELSE 0 END),
      COUNT(DISTINCT procurement_id_number)
    ) * 100, 
    2
  ) AS sla_achievement_rate
FROM `procurement-analyst.procurement.proc_dummy_clean`;

-- 8. Overall Efficiency Summary
SELECT
  COUNT(procurement_id_number) AS total_procurement,
  ROUND(
    SAFE_DIVIDE(SUM(efficiency2), SUM(order_value_filled)) * 100,
    2
  ) AS overall_efficiency_percentage,
  ROUND(SUM(efficiency2), 2) AS total_cost_saving
FROM `procurement-analyst.procurement.proc_dummy_clean`;






