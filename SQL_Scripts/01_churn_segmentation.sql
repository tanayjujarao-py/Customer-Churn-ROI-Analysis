/* ================================================================================
STRATEGIC CHURN ANALYSIS & SEGMENTATION
Author: Tanay Ravindra Jujarao
Project: Customer Retention Optimization
Tooling: SQL (Data Transformation) & Tableau (Visualization)
================================================================================

Description: 
The following queries were developed to segment customer data by tenure, tier, 
and channel. This provides the granular evidence needed to drive the $853K 
annual savings initiative shown in the dashboard.
*/

-- -----------------------------------------------------------------------------
-- 1. SUBSCRIPTION TIER PERFORMANCE (The "Who")
-- Purpose: Identifies which product tiers are bleeding the most customers.
-- Insight: Calculates churn rate and the tier's total impact on the churn base.
-- -----------------------------------------------------------------------------

SELECT 
    subscription_tier,
    COUNT(*) as total_customers,
    SUM(CASE WHEN subscription_status = 'Churned' THEN 1 ELSE 0 END) as churned_customers,
    ROUND(100.0 * SUM(CASE WHEN subscription_status = 'Churned' THEN 1 ELSE 0 END) / COUNT(*), 1) as churn_rate,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM customers), 1) as pct_of_customer_base,
    ROUND(100.0 * SUM(CASE WHEN subscription_status = 'Churned' THEN 1 ELSE 0 END) / 
          (SELECT SUM(CASE WHEN subscription_status = 'Churned' THEN 1 ELSE 0 END) FROM customers), 1) as pct_of_total_churn
FROM customers
GROUP BY subscription_tier
ORDER BY churn_rate DESC;


-- -----------------------------------------------------------------------------
-- 2. TENURE RISK SEGMENTATION (The "When")
-- Purpose: Analyzes the 'Critical Window' of churn based on customer age.
-- Insight: Confirms if churn is concentrated in the 0-3 month onboarding phase.
-- -----------------------------------------------------------------------------

SELECT 
    CASE 
        WHEN customer_lifetime_months <= 3 THEN '0-3 months'
        WHEN customer_lifetime_months <= 6 THEN '4-6 months'
        WHEN customer_lifetime_months <= 12 THEN '7-12 months'
        ELSE '12+ months'
    END as tenure_group,
    COUNT(*) as total_customers,
    SUM(CASE WHEN subscription_status = 'Churned' THEN 1 ELSE 0 END) as churned_customers,
    ROUND(100.0 * SUM(CASE WHEN subscription_status = 'Churned' THEN 1 ELSE 0 END) / COUNT(*), 1) as churn_rate
FROM customers
GROUP BY 1 -- Grouping by the CASE statement above
ORDER BY churn_rate DESC;


-- -----------------------------------------------------------------------------
-- 3. ACQUISITION CHANNEL EFFICIENCY
-- Purpose: Evaluates churn rate against Average Acquisition Cost (CAC).
-- Insight: Determines which marketing channels bring in the "stickiest" customers.
-- -----------------------------------------------------------------------------

SELECT 
    acquisition_channel,
    COUNT(*) as total_customers,
    SUM(CASE WHEN subscription_status = 'Churned' THEN 1 ELSE 0 END) as churned_customers,
    ROUND(100.0 * SUM(CASE WHEN subscription_status = 'Churned' THEN 1 ELSE 0 END) / COUNT(*), 1) as churn_rate,
    ROUND(AVG(acquisition_cost), 2) as avg_acquisition_cost
FROM customers
GROUP BY acquisition_channel
ORDER BY churn_rate DESC;


-- -----------------------------------------------------------------------------
-- 4. BILLING CYCLE ANALYSIS
-- Purpose: Compares Monthly vs. Annual churn rates.
-- Insight: Validates if moving customers to annual plans reduces churn risk.
-- -----------------------------------------------------------------------------

SELECT 
    billing_cycle,
    COUNT(*) as total_customers,
    SUM(CASE WHEN subscription_status = 'Churned' THEN 1 ELSE 0 END) as churned_customers,
    ROUND(100.0 * SUM(CASE WHEN subscription_status = 'Churned' THEN 1 ELSE 0 END) / COUNT(*), 1) as churn_rate
FROM customers
GROUP BY billing_cycle
ORDER BY churn_rate DESC;


-- -----------------------------------------------------------------------------
-- 5. "GOLDEN COHORT" IDENTIFICATION
-- Purpose: Isolate the most loyal customer segments (established for 12+ months).
-- Insight: Identifies the specific attributes of the top 5 most stable segments.
-- -----------------------------------------------------------------------------

SELECT 
    subscription_tier,
    billing_cycle,
    acquisition_channel,
    COUNT(*) as customers,
    SUM(CASE WHEN subscription_status = 'Churned' THEN 1 ELSE 0 END) as churned,
    ROUND(100.0 * SUM(CASE WHEN subscription_status = 'Churned' THEN 1 ELSE 0 END) / COUNT(*), 1) as churn_rate
FROM customers
WHERE customer_lifetime_months >= 12  -- Focused only on established customers
GROUP BY subscription_tier, billing_cycle, acquisition_channel
HAVING COUNT(*) >= 20  -- Ensuring statistical significance
ORDER BY churn_rate ASC
LIMIT 5;