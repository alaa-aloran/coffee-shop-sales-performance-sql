-- =====================================================
-- Coffee Shop Sales & Operational Performance
-- Database: coffee_shop_performance
-- PURPOSE: Profile transaction data completeness
-- =====================================================
-- CHECK 1: Transaction Record Validation
-- Purpose:
-- Verify the total number of imported records, receipt uniqueness, and missing receipt numbers.
-- =====================================================
SELECT COUNT(*) AS total_records,
    COUNT(DISTINCT receipt_number) AS unique_receipts,
    COUNT(*) - COUNT(receipt_number) AS missing_receipts
FROM transactions;
/*
 FINDING:
 - Successfully imported 53,820 transactions.
 - All receipt numbers are unique and non-null.
 - Imported record count matches the source file.
 */
-- == == == == == == == == == == == == == == == == == == == == == == == == == == =
-- CHECK 2: Missing Values
-- Purpose:
-- Identify missing values in key transaction fields.
-- == == == == == == == == == == == == == == == == == == == == == == == == == == =
SELECT COUNT(*) FILTER (
        WHERE outlet IS NULL
            OR TRIM(outlet) = ''
    ) AS missing_outlet,
    COUNT(*) FILTER (
        WHERE date IS NULL
    ) AS missing_date,
    COUNT(*) FILTER (
        WHERE time IS NULL
    ) AS missing_time,
    COUNT(*) FILTER (
        WHERE net_sales IS NULL
    ) AS missing_net_sales,
    COUNT(*) FILTER (
        WHERE tax IS NULL
    ) AS missing_tax,
    COUNT(*) FILTER (
        WHERE total_amount IS NULL
    ) AS missing_total_amount,
    COUNT(*) FILTER (
        WHERE items IS NULL
            OR TRIM(items) = ''
    ) AS missing_items,
    COUNT(*) FILTER (
        WHERE total_item IS NULL
    ) AS missing_total_item,
    COUNT(*) FILTER (
        WHERE payment_method IS NULL
            OR TRIM(payment_method) = ''
    ) AS missing_payment_method,
    COUNT(*) FILTER (
        WHERE use_loyalty_card IS NULL
    ) AS missing_loyalty_card
FROM transactions;
/*
 FINDING:
 - No missing values were found in any of the 10 fields checked.
 - All 53,820 transactions have complete data in these fields.
 */
-- == == == == == == == == == == == == == == == == == == == == == == == == == == =
-- CHECK 3: Sales and Quantity Validation
-- Purpose:
-- Identify zero or negative sales amounts and item quantities that may affect business performance analysis.
-- == == == == == == == == == == == == == == == == == == == == == == == == == == =
SELECT MIN(net_sales) AS min_net_sales,
    MAX(net_sales) AS max_net_sales,
    COUNT(*) FILTER (
        WHERE net_sales <= 0
    ) AS non_positive_net_sales,
    COUNT(*) FILTER (
        WHERE total_amount <= 0
    ) AS non_positive_total_amount,
    COUNT(*) FILTER (
        WHERE total_item <= 0
    ) AS non_positive_items
FROM transactions;
/*
 FINDING:
 - 1,733 transactions (3.2%) have non-positive net sales.
 - All transactions have positive item quantities.
 - Zero-sales transactions require further investigation
 before deciding whether to exclude them from analysis.
 */
-- == == == == == == == == == == == == == == == == == == == == == == == == == == =
-- CHECK 4: Zero-Sales Transactions
-- Purpose:
-- Inspect transactions with zero net sales to understand their monetary values and purchased items.
-- == == == == == == == == == == == == == == == == == == == == == == == == == == =
SELECT outlet,
    date,
    receipt_number,
    net_sales,
    tax,
    total_amount,
    total_item,
    items,
    payment_method,
    use_loyalty_card
FROM transactions
WHERE net_sales = 0
ORDER BY date,
    receipt_number
LIMIT 20;
/*
 FINDING:
 - The 20 reviewed zero-sales transactions have zero tax
 and total amounts, despite recording one purchased item.
 - All 20 transactions used a loyalty card and were
 recorded with Cash as the payment method.
 - These may represent loyalty rewards or complimentary
 items, but further validation is required.
 */
-- == == == == == == == == == == == == == == == == == == == == == == == == == == =
-- CHECK 5: Zero-Sales Transactions and Loyalty Cards
-- Purpose:
-- Determine whether zero-sales transactions are associated with loyalty-card usage.
-- == == == == == == == == == == == == == == == == == == == == == == == == == == =
SELECT use_loyalty_card,
    COUNT(*) AS transaction_count,
    COUNT(*) FILTER (
        WHERE net_sales = 0
    ) AS zero_sales_transactions,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE net_sales = 0
        ) / COUNT(*),
        2
    ) AS zero_sales_pct
FROM transactions
GROUP BY use_loyalty_card
ORDER BY use_loyalty_card;
/*
 FINDING:
 - All 1,733 loyalty-card transactions recorded zero sales.
 - All 52,087 non-loyalty transactions recorded positive sales.
 - This suggests possible loyalty reward redemptions,
 although the dataset does not confirm their purpose.
 */
-- == == == == == == == == == == == == == == == == == == == == == == == == == =
-- CHECK 6: Transaction Period and Outlet Coverage
-- Purpose:
-- Verify the date range and number of outlets represented in the dataset.
-- == == == == == == == == == == == == == == == == == == == == == == == == == =
SELECT MIN(date) AS first_transaction_date,
    MAX(date) AS last_transaction_date,
    COUNT(DISTINCT outlet) AS total_outlets,
    COUNT(DISTINCT date) AS active_transaction_days
FROM transactions;
/*
 FINDING:
 - Transactions cover January 2 to September 30, 2025.
 - The dataset includes 3 outlets and 272 days with recorded activity.
 */
-- == == == == == == == == == == == == == == == == == == == == == == == == == =
-- CHECK 7: Outlet Date Coverage
-- Purpose:
-- Verify the transaction period and activity coverage for each outlet.
-- == == == == == == == == == == == == == == == == == == == == == == == == == =
SELECT outlet,
    MIN(date) AS first_transaction_date,
    MAX(date) AS last_transaction_date,
    COUNT(DISTINCT date) AS active_days,
    COUNT(*) AS total_transactions
FROM transactions
GROUP BY outlet
ORDER BY outlet;
/*
 FINDING:
 - All three outlets recorded transactions on the same 272 days.
 - SHOP001 had the highest transaction volume (26,250),
 followed by SHOP003 (16,753) and SHOP002 (10,817).
 - Outlet activity coverage is consistent across the period.
 */