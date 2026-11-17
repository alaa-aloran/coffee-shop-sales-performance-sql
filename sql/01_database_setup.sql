-- =====================================================
-- Coffee Shop Sales & Operational Performance
-- Database: coffee_shop_performance
-- Purpose: Create the transaction-level POS table
-- =====================================================
CREATE TABLE transactions (
    outlet VARCHAR(20),
    date DATE,
    time TIME,
    net_sales NUMERIC(12, 3),
    tax NUMERIC(12, 3),
    total_amount NUMERIC(12, 3),
    receipt_number VARCHAR(50) PRIMARY KEY,
    items TEXT,
    total_item INTEGER,
    payment_method VARCHAR(50),
    use_loyalty_card INTEGER
);