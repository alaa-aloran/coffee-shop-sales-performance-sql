-- == == == == == == == == == == == == == == == == == == == == == == == == == =
-- PROJECT: Coffee Shop Sales & Operational Performance
-- OBJECTIVE 1: Evaluate Outlet Sales Performance
-- Goal: Assess differences in revenue, transaction activity, and sales trends across the three outlets.
-- == == == == == == == == == == == == == == == == == == == == == == == == == =
-- QUERY 1.1: Outlet Performance Comparison
-- Business Question 1:
-- How do outlets compare in net sales, transaction volume, and average paid transaction value?
-- == == == == == == == == == == == == == == == == == == == == == == == == == =
SELECT outlet,
    ROUND(SUM(net_sales), 2) AS total_net_sales,
    COUNT(*) AS total_transactions,
    -- Only positive-sales transactions count as paid purchases.
    COUNT(*) FILTER (
        WHERE net_sales > 0
    ) AS paid_transactions,
    -- All loyalty-card transactions have zero net sales in this dataset.
    COUNT(*) FILTER (
        WHERE net_sales = 0
    ) AS non_paid_loyalty_transactions,
    -- Exclude zero-value transactions from average paid spending.
    ROUND(
        AVG(net_sales) FILTER (
            WHERE net_sales > 0
        ),
        2
    ) AS avg_paid_transaction_value
FROM transactions
GROUP BY outlet
ORDER BY total_net_sales DESC;
/*
 FINDING Q1:
 - SHOP001 generated the highest net sales (IDR 580.28M)
 and paid transactions (25,485).
 - Average paid transaction values were similar across
 outlets, ranging from IDR 22,642.72 to 22,785.65.
 - Differences in revenue were primarily associated with
 transaction volume rather than average spending.
 
 Note: IDR = Indonesian Rupiah (Indonesia's official currency).
 */
-- == == == == == == == == == == == == == == == == == == == == == == == == == =
-- QUERY 1.2: Monthly Sales Trends
-- Business Question 2:
-- How did monthly net sales and paid transaction activity
-- change across the three outlets?
-- == == == == == == == == == == == == == == == == == == == == == == == == == =
WITH monthly_performance AS (
    SELECT outlet,
        DATE_TRUNC('month', date)::DATE AS sales_month,
        -- rounds date down to the beginning of a specified period.
        ROUND(SUM(net_sales), 2) AS net_sales,
        COUNT(*) FILTER (
            WHERE net_sales > 0
        ) AS paid_transactions
    FROM transactions
    GROUP BY outlet,
        DATE_TRUNC('month', date)
)
SELECT outlet,
    sales_month,
    net_sales,
    paid_transactions,
    ROUND(
        100.0 * (
            net_sales - LAG(net_sales) OVER (
                PARTITION BY outlet
                ORDER BY sales_month
            )
        ) / NULLIF(
            LAG(net_sales) OVER (
                PARTITION BY outlet
                ORDER BY sales_month
            ),
            0
        ),
        2
    ) AS monthly_sales_change_pct
FROM monthly_performance
ORDER BY outlet,
    sales_month;
/*
 FINDING Q2:
 - SHOP001 consistently led monthly sales, peaking at IDR 78.09M in June.
 - SHOP002 peaked in July (IDR 38.60M), followed by
 a 39.22% decline in August.
 - SHOP003 experienced a 61.01% sales decline in April,
 followed by a 94.36% recovery in May.
 - Monthly sales patterns varied across outlets, with
 notable fluctuations in SHOP002 and SHOP003.
 */
-- == == == == == == == == == == == == == == == == == == == == == == == == == =
-- FINAL SUMMARY
-- == == == == == == == == == == == == == == == == == == == == == == == == == =
/*
 OBJECTIVE 1: FINAL SUMMARY
 
 - SHOP001 led overall sales (IDR 580.28M) and recorded
 the highest transaction volume throughout the period.
 
 - Average paid transaction values were nearly identical
 across outlets (approximately IDR 22.6K–22.8K),
 indicating that revenue differences were primarily
 driven by transaction volume rather than spending.
 
 - SHOP002 experienced its largest monthly sales decline
 in August (-39.22%), while SHOP003 recorded its
 largest decline in April (-61.01%).
 
 - Overall, transaction volume was the main differentiator
 in outlet sales performance, while monthly fluctuations
 warrant further operational investigation.
 */