/* ================================================================================
BEHAVIORAL CHURN DRIVERS & SUPPORT ANALYSIS
Author: Tanay Ravindra Jujarao
Project: Customer Retention Optimization
Tooling: SQL (Behavioral Analysis) & Tableau (Visualization)
================================================================================

Description: 
These queries isolate the "Why" behind the churn crisis. They examine support 
interaction quality, feature engagement, and initial activation speed to 
provide actionable evidence for the proposed $270K retention initiative.
*/

-- -----------------------------------------------------------------------------
-- 1. SUPPORT TICKET VOLUME IMPACT
-- Purpose: Analyzes how the number of support requests correlates with churn.
-- Insight: Validates the "Support Death Spiral" where 6+ tickets indicate
-- a nearly 100% churn probability.
-- -----------------------------------------------------------------------------

SELECT 
    CASE 
        WHEN customer_support_tickets = 0 THEN '0 tickets'
        WHEN customer_support_tickets BETWEEN 1 AND 2 THEN '1-2 tickets'
        WHEN customer_support_tickets BETWEEN 3 AND 5 THEN '3-5 tickets'
        ELSE '6+ tickets'
    END as support_ticket_range,
    COUNT(*) as total_customers,
    SUM(CASE WHEN subscription_status = 'Churned' THEN 1 ELSE 0 END) as churned_customers,
    ROUND(100.0 * SUM(CASE WHEN subscription_status = 'Churned' THEN 1 ELSE 0 END) / COUNT(*), 1) as churn_rate
FROM customers
GROUP BY 1
ORDER BY churn_rate ASC;


-- -----------------------------------------------------------------------------
-- 2. RESOLUTION SPEED VS. RETENTION
-- Purpose: Uses a CTE to calculate average resolution time per customer.
-- Insight: Proves that "Slow Resolution (48hr+)" is a primary churn driver.
-- -----------------------------------------------------------------------------

WITH customer_support_metrics AS (
    SELECT 
        s.customer_id,
        AVG(s.resolution_time_hours) as avg_resolution_time,
        COUNT(*) as ticket_count
    FROM support_interactions s
    WHERE s.ticket_status = 'Resolved'
    GROUP BY s.customer_id
)
SELECT 
    CASE 
        WHEN sm.avg_resolution_time < 24 THEN 'Fast resolution (<24hr)'
        WHEN sm.avg_resolution_time < 48 THEN 'Medium resolution (24-48hr)'
        ELSE 'Slow resolution (48hr+)'
    END as resolution_speed,
    COUNT(*) as total_customers,
    SUM(CASE WHEN c.subscription_status = 'Churned' THEN 1 ELSE 0 END) as churned_customers,
    ROUND(100.0 * SUM(CASE WHEN c.subscription_status = 'Churned' THEN 1 ELSE 0 END) / COUNT(*), 1) as churn_rate,
    ROUND(AVG(sm.avg_resolution_time), 1) as avg_hours_to_resolve
FROM customer_support_metrics sm
JOIN customers c ON sm.customer_id = c.customer_id
GROUP BY 1
ORDER BY churn_rate ASC;


-- -----------------------------------------------------------------------------
-- 3. PRODUCT FEATURE USAGE & ENGAGEMENT
-- Purpose: Segments customers by their feature usage score.
-- Insight: Low usage (<40) often precedes churn, signaling a lack of perceived value.
-- -----------------------------------------------------------------------------

SELECT 
    CASE 
        WHEN feature_usage_score >= 70 THEN 'High usage (70+)'
        WHEN feature_usage_score >= 40 THEN 'Medium usage (40-69)'
        WHEN feature_usage_score IS NOT NULL THEN 'Low usage (<40)'
        ELSE 'No data'
    END as usage_level,
    COUNT(*) as total_customers,
    SUM(CASE WHEN subscription_status = 'Churned' THEN 1 ELSE 0 END) as churned_customers,
    ROUND(100.0 * SUM(CASE WHEN subscription_status = 'Churned' THEN 1 ELSE 0 END) / COUNT(*), 1) as churn_rate,
    ROUND(AVG(feature_usage_score), 1) as avg_usage_score
FROM customers
GROUP BY 1
ORDER BY churn_rate ASC;


-- -----------------------------------------------------------------------------
-- 4. EMAIL ENGAGEMENT SCORE ANALYSIS
-- Purpose: Evaluates marketing communication effectiveness.
-- Insight: Medium to high engagement scores correlate with lower churn rates.
-- -----------------------------------------------------------------------------

SELECT 
    CASE 
        WHEN email_engagement_score >= 60 THEN 'High engagement (60+)'
        WHEN email_engagement_score >= 30 THEN 'Medium engagement (30-59)'
        ELSE 'Low engagement (<30)'
    END as engagement_level,
    COUNT(*) as total_customers,
    SUM(CASE WHEN subscription_status = 'Churned' THEN 1 ELSE 0 END) as churned_customers,
    ROUND(100.0 * SUM(CASE WHEN subscription_status = 'Churned' THEN 1 ELSE 0 END) / COUNT(*), 1) as churn_rate,
    ROUND(AVG(email_engagement_score), 1) as avg_engagement_score
FROM customers
GROUP BY 1
ORDER BY churn_rate ASC;


-- -----------------------------------------------------------------------------
-- 5. NET PROMOTER SCORE (NPS) CATEGORIZATION
-- Purpose: Links customer sentiment (NPS) directly to churn outcomes.
-- Insight: "Detractors (0-6)" are the highest churn risk segment.
-- -----------------------------------------------------------------------------

SELECT 
    CASE 
        WHEN nps_score >= 9 THEN 'Promoters (9-10)'
        WHEN nps_score >= 7 THEN 'Passives (7-8)'
        WHEN nps_score IS NOT NULL THEN 'Detractors (0-6)'
        ELSE 'No NPS data'
    END as nps_category,
    COUNT(*) as total_customers,
    SUM(CASE WHEN subscription_status = 'Churned' THEN 1 ELSE 0 END) as churned_customers,
    ROUND(100.0 * SUM(CASE WHEN subscription_status = 'Churned' THEN 1 ELSE 0 END) / COUNT(*), 1) as churn_rate,
    ROUND(AVG(nps_score), 1) as avg_nps_score
FROM customers
GROUP BY 1
ORDER BY churn_rate ASC;


-- -----------------------------------------------------------------------------
-- 6. ORDER FREQUENCY & ACTIVATION SPEED
-- Purpose: Measures the impact of "Time to First Order" on long-term retention.
-- Insight: Confirms that customers who never order or delay activation
-- contribute significantly to the 38.4% churn rate.
-- -----------------------------------------------------------------------------

SELECT 
    CASE 
        WHEN last_order_date IS NULL THEN 'Never ordered'
        WHEN DATEDIFF(last_order_date, signup_date) <= 14 THEN 'Ordered within 14 days'
        WHEN DATEDIFF(last_order_date, signup_date) <= 30 THEN 'Ordered within 30 days'
        ELSE 'Ordered after 30+ days'
    END as time_to_first_order,
    COUNT(*) as total_customers,
    SUM(CASE WHEN subscription_status = 'Churned' THEN 1 ELSE 0 END) as churned_customers,
    ROUND(100.0 * SUM(CASE WHEN subscription_status = 'Churned' THEN 1 ELSE 0 END) / COUNT(*), 1) as churn_rate
FROM customers
GROUP BY 1
ORDER BY churn_rate DESC;


-- -----------------------------------------------------------------------------
-- 7. CHURN REASON HIERARCHY
-- Purpose: Summarizes qualitative churn reasons for executive review.
-- Insight: Directly informs the "Why" section of the Portfolio Dashboard.
-- -----------------------------------------------------------------------------

SELECT 
    churn_reason,
    COUNT(*) as churned_customers,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM customers WHERE churn_reason IS NOT NULL), 1) as pct_of_churned
FROM customers
WHERE churn_reason IS NOT NULL
GROUP BY churn_reason
ORDER BY churned_customers DESC;