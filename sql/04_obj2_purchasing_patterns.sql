-- == == == == == == == == == == == == == == == == == == == == == == == == == =
-- PROJECT: Coffee Shop Sales & Operational Performance
-- OBJECTIVE 2: Understand Purchasing Patterns
-- Goal: Analyze transaction activity by time, payment method, and loyalty-card usage.
-- == == == == == == == == == == == == == == == == == == == == == == == == == =
-- QUERY 2.1: Peak Transaction Hours
-- Business Question 3:
-- During which hours do outlets experience the highest
-- paid transaction activity?
-- == == == == == == == == == == == == == == == == == == == == == == == == == =
SELECT outlet,
    EXTRACT(
        HOUR
        FROM time
    )::INTEGER AS transaction_hour,
    COUNT(*) AS paid_transactions,
    ROUND(SUM(net_sales), 2) AS total_net_sales
FROM transactions
WHERE net_sales > 0 -- Only positive-sales transactions count as paid purchases.
GROUP BY outlet,
    EXTRACT(
        HOUR
        FROM time
    )
ORDER BY outlet,
    paid_transactions DESC;
/*
 FINDING:
 - Evening hours (5 PM–10 PM) showed the highest purchasing activity
 across all three outlets.
 - SHOP001 and SHOP003 peaked at 8 PM, recording 1,840 and
 1,306 paid transactions, respectively.
 - SHOP002 peaked at 10 PM, with 778 paid transactions.
 - These patterns suggest that evening staffing and service capacity
 deserve particular attention, although staffing and service data
 are needed before making specific operational recommendations.
 */
-- == == == == == == == == == == == == == == == == == == == == == == == == == =
-- QUERY 2.2A: Average Daily Performance by Day of Week
-- Business Question 4A:
-- Which days of the week have the highest average daily paid transactions and net sales at each outlet?
-- == == == == == == == == == == == == == == == == == == == == == == == == == =
WITH daily_performance AS (
    SELECT outlet,
        date,
        EXTRACT(
            ISODOW
            FROM date
        )::INTEGER AS day_number,
        -- Ensures weekdays are ordered Monday (1) to Sunday (7).
        TRIM(TO_CHAR(date, 'Day')) AS day_name,
        COUNT(*) FILTER (
            WHERE net_sales > 0
        ) AS paid_transactions,
        SUM(net_sales) AS net_sales
    FROM transactions
    GROUP BY outlet,
        date
)
SELECT outlet,
    day_name,
    ROUND(AVG(paid_transactions), 1) AS avg_daily_paid_transactions,
    ROUND(AVG(net_sales), 2) AS avg_daily_net_sales
FROM daily_performance
GROUP BY outlet,
    day_number,
    day_name
ORDER BY outlet,
    day_number;
-- == == == == == == == == == == == == == == == == == == == == == == == == == =
-- QUERY 2.2B: Consistency of Purchasing Activity Across Weekdays
-- Business Question 4B:
-- How much do average daily paid transactions differ between the busiest and quietest weekdays at each outlet?
-- == == == == == == == == == == == == == == == == == == == == == == == == == =
WITH daily_performance AS (
    SELECT outlet,
        date,
        EXTRACT(
            ISODOW
            FROM date
        )::INTEGER AS day_number,
        COUNT(*) FILTER (
            WHERE net_sales > 0
        ) AS paid_transactions
    FROM transactions
    GROUP BY outlet,
        date
),
weekday_averages AS (
    SELECT outlet,
        day_number,
        AVG(paid_transactions) AS avg_daily_paid_transactions
    FROM daily_performance
    GROUP BY outlet,
        day_number
)
SELECT outlet,
    ROUND(AVG(avg_daily_paid_transactions), 1) AS avg_across_weekdays,
    ROUND(MIN(avg_daily_paid_transactions), 1) AS lowest_weekday_avg,
    ROUND(MAX(avg_daily_paid_transactions), 1) AS highest_weekday_avg,
    ROUND(
        MAX(avg_daily_paid_transactions) - MIN(avg_daily_paid_transactions),
        1
    ) AS weekday_range,
    ROUND(
        100.0 * (
            MAX(avg_daily_paid_transactions) - MIN(avg_daily_paid_transactions)
        ) / NULLIF(AVG(avg_daily_paid_transactions), 0),
        2
    ) AS weekday_range_pct
FROM weekday_averages
GROUP BY outlet
ORDER BY outlet;
/*
 COMBINED FINDING — QUERIES 2.2A & 2.2B:
 
 - Average daily paid transactions were relatively consistent
 across weekdays within each outlet.
 - SHOP001 showed the smallest weekday variation (3.3%),
 followed by SHOP002 (7.3%) and SHOP003 (9.4%).
 - Although the busiest days differed by outlet, the relatively
 small variations suggest no strong weekday-specific
 purchasing patterns.
 - Management may benefit more from maintaining consistent
 daily operational coverage and focusing on peak hours
 rather than making major weekday-specific adjustments.
 */
-- == == == == == == == == == == == == == == == == == == == == == == == == == =
-- QUERY 2.3: Payment Method Patterns
-- Business Question 5:
-- How do paid transaction volumes and average paid transaction values differ by payment method across the three outlets?
-- == == == == == == == == == == == == == == == == == == == == == == == == == =
SELECT outlet,
    payment_method,
    COUNT(*) AS paid_transactions,
    ROUND(SUM(net_sales), 2) AS total_net_sales,
    ROUND(AVG(net_sales), 2) AS avg_paid_transaction_value
FROM transactions
WHERE net_sales > 0
GROUP BY outlet,
    payment_method
ORDER BY outlet,
    paid_transactions DESC;
/*
 FINDING:
 - BCA dominated paid transactions across all outlets (82.2%),
 followed by Cash (17.6%) and GoFood (0.2%).
 - Average paid transaction values were very similar between
 BCA and Cash, indicating limited spending differences.
 - GoFood transaction volumes were too small to draw
 reliable conclusions about average spending patterns.
 - Maintaining reliable support for BCA is operationally important,
 given its dominant share of recorded paid transactions.
 
 Note: 
 BCA refers to Bank Central Asia, an Indonesian bank.
 The dataset does not distinguish between specific BCA
 payment channels (e.g., debit cards, QRIS, or transfers).
 */
-- == == == == == == == == == == == == == == == == == == == == == == == == == =
-- QUERY 2.4: Non-Paid Loyalty Transaction Patterns
-- Business Question 6:
-- How frequently do non-paid loyalty transactions occur across the three outlets?
-- == == == == == == == == == == == == == == == == == == == == == == == == == =
SELECT outlet,
    COUNT(*) AS total_transactions,
    -- In this dataset, zero-sales transactions are all loyalty-related.
    COUNT(*) FILTER (
        WHERE net_sales = 0
    ) AS non_paid_loyalty_transactions,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE net_sales = 0
        ) / COUNT(*),
        2
    ) AS loyalty_transaction_pct
FROM transactions
GROUP BY outlet
ORDER BY loyalty_transaction_pct DESC;
/*
 FINDING:
 - SHOP001 recorded the highest number of non-paid loyalty
 transactions (765), but the lowest relative share (2.91%).
 - SHOP002 had the highest loyalty transaction share (3.75%),
 followed by SHOP003 (3.35%) and SHOP001 (2.91%).
 - These differences may warrant further investigation into
 loyalty-program activity across outlets.
 - SHOP002's higher share does not necessarily indicate more
 loyal customers, as customer identifiers are unavailable
 and reward redemptions cannot be confirmed.
 */
-- == == == == == == == == == == == == == == == == == == == == == == == == == =
-- FINAL SUMMARY
-- == == == == == == == == == == == == == == == == == == == == == == == == == =
/*
 OBJECTIVE 2: FINAL SUMMARY
 
 - Evening hours (5 PM–10 PM) showed the highest purchasing
 activity across all outlets, suggesting that staffing
 and service capacity should be reviewed during these periods.
 
 - Average daily paid transactions were relatively consistent
 across weekdays, with modest variations of 3.3%–9.4%
 within outlets. Hourly demand patterns may therefore be
 more relevant for operational planning than weekday differences.
 
 - BCA dominated paid transactions (82.2%), while Cash accounted
 for 17.6%. Average paid transaction values were similar
 between these payment methods, highlighting the importance
 of maintaining reliable BCA payment services.
 
 - SHOP002 recorded the highest share of non-paid loyalty
 transactions (3.75%), despite SHOP001 having the highest
 absolute count (765). These transactions may reflect
 loyalty-program activity, but do not establish customer
 retention or confirmed reward redemptions.
 
 - Overall, the findings suggest prioritizing evening service
 capacity, maintaining reliable payment operations, and
 reviewing loyalty-program activity across outlets.
 Specific operational changes require additional data.
 */