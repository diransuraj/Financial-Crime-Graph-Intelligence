-- ============================================================
-- AML TRANSACTION MONITORING SYSTEM: CORE QUERIES
-- ============================================================
-- Author: [Your Name]
-- Dataset: Paysim
-- Purpose: Detection queries for money mule patterns, structuring,
--          and risk scoring
-- ============================================================

-- ============================================================
-- 1. SMART RULE: 3-Signal Money Mule Detection
-- ============================================================
-- Detects the classic money mule pattern:
--   - Account wipe (sender drained to zero)
--   - Fresh recipient (recipient had zero balance)
--   - Balance mismatch (immediate onward movement/layering)
--   - Amount > calibrated threshold

SELECT
    COUNT(*) AS total_alerts,
    SUM(isfraud) AS true_fraud_caught,
    SUM(CASE WHEN isfraud = 0 THEN 1 ELSE 0 END) AS false_positives,
    ROUND(100.0 * SUM(CASE WHEN isfraud = 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS false_positive_rate_pct,
    ROUND(100.0 * SUM(isfraud) / COUNT(*), 2) AS precision_pct
FROM transactions
WHERE type IN ('CASH_OUT', 'TRANSFER')
  AND amount > 400000                           -- Calibrated threshold
  AND newbalanceorig = 0                        -- Signal 1: Account wiped
  AND (oldbalancedest + amount) <> newbalancedest -- Signal 2: Balance mismatch
  AND oldbalancedest = 0;                       -- Signal 3: Fresh destination


-- ============================================================
-- 2. AMOUNT RISK ANALYSIS: U-Shaped Fraud Curve
-- ============================================================
-- Demonstrates the non-linear relationship between amount and fraud
-- Fraud rate is highest at both extremes (<$5K and >$1M)

SELECT 
    CASE 
        WHEN amount < 5000 THEN '<5K'
        WHEN amount < 10000 THEN '5K-10K'
        WHEN amount < 25000 THEN '10K-25K'
        WHEN amount < 50000 THEN '25K-50K'
        WHEN amount < 75000 THEN '50K-75K'
        WHEN amount < 100000 THEN '75K-100K'
        WHEN amount < 250000 THEN '100K-250K'
        WHEN amount < 500000 THEN '250K-500K'
        WHEN amount < 1000000 THEN '500K-1M'
        ELSE '>1M'
    END AS amount_bracket,
    COUNT(*) AS total_transactions,
    SUM(isfraud) AS fraud_cases,
    ROUND(100.0 * SUM(isfraud) / COUNT(*), 2) AS fraud_rate_pct
FROM transactions
WHERE type IN ('CASH_OUT', 'TRANSFER')
GROUP BY amount_bracket
ORDER BY MIN(amount);


-- ============================================================
-- 3. SIGNAL ANALYSIS: Individual Risk Indicators
-- ============================================================
-- Calculates fraud rate for each signal in isolation

-- 3a. Transaction Type Risk
SELECT 
    type,
    COUNT(*) AS total_transactions,
    SUM(isfraud) AS fraud_cases,
    ROUND(100.0 * SUM(isfraud) / COUNT(*), 2) AS fraud_rate_pct
FROM transactions
WHERE type IN ('CASH_OUT', 'TRANSFER')
GROUP BY type
ORDER BY fraud_rate_pct DESC;

-- 3b. Balance Wipe Risk
SELECT 
    CASE WHEN newbalanceorig = 0 THEN 'Wiped' ELSE 'Balance Remaining' END AS wipe_status,
    COUNT(*) AS total_transactions,
    SUM(isfraud) AS fraud_cases,
    ROUND(100.0 * SUM(isfraud) / COUNT(*), 2) AS fraud_rate_pct
FROM transactions
WHERE type IN ('CASH_OUT', 'TRANSFER')
GROUP BY wipe_status;

-- 3c. Balance Mismatch Risk (Layering Indicator)
SELECT 
    CASE 
        WHEN (oldbalancedest + amount) <> newbalancedest THEN 'Mismatch' 
        ELSE 'Matches' 
    END AS balance_check,
    COUNT(*) AS total_transactions,
    SUM(isfraud) AS fraud_cases,
    ROUND(100.0 * SUM(isfraud) / COUNT(*), 2) AS fraud_rate_pct
FROM transactions
WHERE type IN ('CASH_OUT', 'TRANSFER')
GROUP BY balance_check;

-- 3d. Fresh Recipient Risk (Strongest Signal)
SELECT 
    CASE WHEN oldbalancedest = 0 THEN 'Fresh' ELSE 'Has Balance' END AS recipient_status,
    COUNT(*) AS total_transactions,
    SUM(isfraud) AS fraud_cases,
    ROUND(100.0 * SUM(isfraud) / COUNT(*), 2) AS fraud_rate_pct
FROM transactions
WHERE type IN ('CASH_OUT', 'TRANSFER')
GROUP BY recipient_status;


-- ============================================================
-- 4. THRESHOLD OPTIMIZATION: Finding the Best Amount Cutoff
-- ============================================================
-- Tests multiple amount thresholds to find optimal balance
-- between precision and operational volume

WITH test_thresholds AS (
    SELECT 200000 AS threshold UNION ALL
    SELECT 250000 UNION ALL
    SELECT 300000 UNION ALL
    SELECT 350000 UNION ALL
    SELECT 400000 UNION ALL
    SELECT 500000
)
SELECT 
    t.threshold,
    COUNT(*) AS alerts,
    SUM(tr.isfraud) AS fraud_caught,
    ROUND(100.0 * SUM(tr.isfraud) / COUNT(*), 2) AS precision_pct
FROM test_thresholds t
CROSS JOIN transactions tr
WHERE tr.type IN ('CASH_OUT', 'TRANSFER')
  AND tr.amount > t.threshold
  AND tr.newbalanceorig = 0
  AND (tr.oldbalancedest + tr.amount) <> tr.newbalancedest
  AND tr.oldbalancedest = 0
GROUP BY t.threshold
ORDER BY t.threshold;


-- ============================================================
-- 5. VELOCITY ANALYSIS: Transaction Frequency Patterns
-- ============================================================
-- Identifies accounts with unusual transaction velocity
-- (High frequency or monetary volume in short windows)

WITH account_velocity AS (
    SELECT 
        nameorig,
        COUNT(*) AS transaction_count,
        SUM(amount) AS total_amount,
        COUNT(DISTINCT namedest) AS unique_recipients,
        MAX(step) - MIN(step) AS time_window
    FROM transactions
    WHERE type IN ('CASH_OUT', 'TRANSFER')
    GROUP BY nameorig
    HAVING COUNT(*) >= 3
)
SELECT 
    nameorig,
    transaction_count,
    ROUND(total_amount, 2) AS total_amount,
    unique_recipients,
    time_window,
    ROUND(total_amount / NULLIF(time_window, 0), 2) AS amount_per_step,
    CASE 
        WHEN transaction_count >= 5 THEN 'High Frequency'
        WHEN total_amount >= 500000 THEN 'High Monetary'
        ELSE 'Moderate'
    END AS velocity_risk
FROM account_velocity
ORDER BY total_amount DESC
LIMIT 20;


-- ============================================================
-- 6. FEATURE ENGINEERING: For Random Forest Model
-- ============================================================
-- Creates all 18 features used in the ML model

SELECT
    -- Target
    isfraud,
    
    -- Core signals (binary)
    CASE WHEN newbalanceorig = 0 THEN 1 ELSE 0 END AS balance_wipe,
    CASE WHEN oldbalancedest = 0 THEN 1 ELSE 0 END AS recipient_fresh,
    CASE WHEN (oldbalancedest + amount) <> newbalancedest THEN 1 ELSE 0 END AS balance_mismatch,
    
    -- Transaction type
    CASE WHEN type = 'TRANSFER' THEN 1 ELSE 0 END AS is_transfer,
    CASE WHEN type = 'CASH_OUT' THEN 1 ELSE 0 END AS is_cashout,
    
    -- Amount features (non-linear)
    amount,
    LOG(amount + 1) AS log_amount,
    
    -- Amount buckets (captures U-shaped risk)
    CASE 
        WHEN amount >= 1000000 THEN 'ultra_large'
        WHEN amount >= 500000 THEN 'very_large'
        WHEN amount >= 250000 THEN 'large'
        WHEN amount >= 100000 THEN 'medium_large'
        WHEN amount >= 25000 THEN 'medium'
        WHEN amount >= 5000 THEN 'small'
        ELSE 'very_small'
    END AS amount_bucket,
    
    -- Interaction features (combinatorial patterns)
    CASE WHEN newbalanceorig = 0 AND type = 'TRANSFER' THEN 1 ELSE 0 END AS wipe_and_transfer,
    CASE WHEN newbalanceorig = 0 AND oldbalancedest = 0 THEN 1 ELSE 0 END AS wipe_and_fresh_recipient,
    CASE WHEN newbalanceorig = 0 AND (oldbalancedest + amount) <> newbalancedest THEN 1 ELSE 0 END AS wipe_and_mismatch,
    CASE WHEN type = 'TRANSFER' AND oldbalancedest = 0 THEN 1 ELSE 0 END AS transfer_to_fresh,
    CASE WHEN amount >= 500000 AND oldbalancedest = 0 THEN 1 ELSE 0 END AS large_to_fresh
    
FROM transactions
WHERE type IN ('CASH_OUT', 'TRANSFER')
LIMIT 10000;


-- ============================================================
-- 7. COMPOSITE RISK SCORING (SQL Implementation)
-- ============================================================
-- Calculates final risk score using the composite formula:
-- Final Score = (Smart Rule Binary × 50 × 0.30) + (RF Score × 0.70)
-- Note: RF Score would come from model prediction in production

WITH risk_components AS (
    SELECT
        -- Smart Rule components
        CASE WHEN newbalanceorig = 0 THEN 30 ELSE 0 END AS wipe_points,
        CASE WHEN type = 'TRANSFER' THEN 25 WHEN type = 'CASH_OUT' THEN 10 ELSE 0 END AS type_points,
        CASE WHEN (oldbalancedest + amount) <> newbalancedest THEN 20 ELSE 0 END AS mismatch_points,
        
        -- Smart Rule binary flag (all conditions)
        CASE 
            WHEN type IN ('CASH_OUT', 'TRANSFER')
             AND amount > 400000
             AND newbalanceorig = 0
             AND (oldbalancedest + amount) <> newbalancedest
             AND oldbalancedest = 0
            THEN 1 ELSE 0 
        END AS smart_rule_triggered,
        
        -- RF probability placeholder (would come from model)
        0.98 AS rf_probability  -- Example value; real value from ML model
        
    FROM transactions
    WHERE type IN ('CASH_OUT', 'TRANSFER')
)
SELECT 
    smart_rule_triggered,
    rf_probability,
    -- Smart Rule Score: 50 when triggered
    smart_rule_triggered * 50 AS smart_rule_score,
    -- RF Score: 0-100
    rf_probability * 100 AS rf_score,
    -- Composite score (30% Smart Rule, 70% RF)
    (smart_rule_triggered * 50 * 0.30) + (rf_probability * 100 * 0.70) AS composite_score,
    -- Risk tier
    CASE 
        WHEN (smart_rule_triggered * 50 * 0.30) + (rf_probability * 100 * 0.70) >= 75 THEN 'CRITICAL'
        WHEN (smart_rule_triggered * 50 * 0.30) + (rf_probability * 100 * 0.70) >= 50 THEN 'MEDIUM'
        WHEN (smart_rule_triggered * 50 * 0.30) + (rf_probability * 100 * 0.70) >= 30 THEN 'LOW'
        ELSE 'NEGLIGIBLE'
    END AS risk_tier
FROM risk_components
WHERE smart_rule_triggered = 1 OR rf_probability > 0.7
ORDER BY composite_score DESC
LIMIT 100;


-- ============================================================
-- 8. OPERATIONAL METRICS: Alert Volume Projection
-- ============================================================
-- Calculates daily alert volume for capacity planning

SELECT 
    'Smart Rule' AS detection_method,
    COUNT(*) AS annual_alerts,
    ROUND(COUNT(*) / 365.0, 0) AS daily_alerts
FROM transactions
WHERE type IN ('CASH_OUT', 'TRANSFER')
  AND amount > 400000
  AND newbalanceorig = 0
  AND (oldbalancedest + amount) <> newbalancedest
  AND oldbalancedest = 0

UNION ALL

SELECT 
    'Random Forest (Projected)' AS detection_method,
    10662 AS annual_alerts,  -- From model projection
    29 AS daily_alerts;       -- 10662 / 365


-- ============================================================
-- 9. FRAUD BREAKDOWN BY TRANSACTION TYPE
-- ============================================================
SELECT 
    type,
    COUNT(*) AS fraud_cases,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM transactions WHERE isfraud = 1 AND type IN ('CASH_OUT', 'TRANSFER')), 2) AS pct_of_total_fraud
FROM transactions
WHERE isfraud = 1
  AND type IN ('CASH_OUT', 'TRANSFER')
GROUP BY type
ORDER BY fraud_cases DESC;
