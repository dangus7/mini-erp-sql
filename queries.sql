-- Q1: Current on-hand quantity per product
SELECT p.sku, p.name, SUM(m.qty) AS on_hand_qty
FROM products p
JOIN stock_moves m ON m.product_id = p.product_id
GROUP BY p.sku, p.name
ORDER BY p.sku;

-- Q2: Total sales revenue per customer (from order lines)
SELECT c.name, ROUND(SUM(ol.qty * ol.unit_price), 2) AS revenue
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN order_lines ol ON ol.order_id = o.order_id
WHERE o.status IN ('confirmed','invoiced')
GROUP BY c.name
ORDER BY revenue DESC;

-- Q3: Open invoices + outstanding amount
SELECT i.invoice_id, c.name AS customer, i.invoice_date,
       ROUND(SUM(ol.qty * ol.unit_price),2) AS invoice_total,
       ROUND(COALESCE(SUM(p.amount),0),2) AS paid,
       ROUND(SUM(ol.qty * ol.unit_price) - COALESCE(SUM(p.amount),0),2) AS outstanding
FROM invoices i
JOIN orders o ON o.order_id = i.order_id
JOIN customers c ON c.customer_id = o.customer_id
JOIN order_lines ol ON ol.order_id = o.order_id
LEFT JOIN payments p ON p.invoice_id = i.invoice_id
WHERE i.status = 'open'
GROUP BY i.invoice_id, c.name, i.invoice_date
ORDER BY i.invoice_date;

-- Q4: Stock moves ledger for one product (Chair)
SELECT m.move_date, m.qty, m.unit_cost, m.ref
FROM stock_moves m
JOIN products p ON p.product_id = m.product_id
WHERE p.sku = 'SKU-CHAIR'
ORDER BY m.move_date, m.move_id;

-- Q5: Average unit cost of receipts per product (simple average of receipt costs)
SELECT p.sku, p.name,
       ROUND(AVG(m.unit_cost), 2) AS avg_receipt_cost
FROM products p
JOIN stock_moves m ON m.product_id = p.product_id
WHERE m.qty > 0
GROUP BY p.sku, p.name
ORDER BY p.sku;

-- Q6: Weighted average cost (WAC) of receipts per product
SELECT p.sku, p.name,
       ROUND(SUM(m.qty * m.unit_cost) / SUM(m.qty), 2) AS weighted_avg_cost
FROM products p
JOIN stock_moves m ON m.product_id = p.product_id
WHERE m.qty > 0
GROUP BY p.sku, p.name
ORDER BY p.sku;

-- Q7: "Inventory valuation" using weighted avg cost * current on-hand qty (approximation)
WITH onhand AS (
  SELECT product_id, SUM(qty) AS on_hand_qty
  FROM stock_moves
  GROUP BY product_id
),
wac AS (
  SELECT product_id, SUM(qty * unit_cost) / SUM(qty) AS weighted_avg_cost
  FROM stock_moves
  WHERE qty > 0
  GROUP BY product_id
)
SELECT p.sku, p.name,
       onhand.on_hand_qty,
       ROUND(wac.weighted_avg_cost, 2) AS weighted_avg_cost,
       ROUND(onhand.on_hand_qty * wac.weighted_avg_cost, 2) AS inventory_value
FROM products p
JOIN onhand ON onhand.product_id = p.product_id
JOIN wac ON wac.product_id = p.product_id
ORDER BY p.sku;

-- Q8: Compliance-friendly revaluation allocation:
-- Apply revaluation only to current on-hand qty; remainder goes to variance (COGS variance).
WITH onhand AS (
  SELECT product_id, SUM(qty) AS on_hand_qty
  FROM stock_moves
  GROUP BY product_id
),
receipt_cost AS (
  SELECT product_id,
         SUM(qty * unit_cost) AS total_receipt_cost,
         SUM(qty) AS total_receipt_qty
  FROM stock_moves
  WHERE qty > 0
  GROUP BY product_id
),
wac AS (
  SELECT r.product_id,
         (r.total_receipt_cost / r.total_receipt_qty) AS base_wac
  FROM receipt_cost r
),
issued AS (
  SELECT product_id, -SUM(qty) AS issued_qty
  FROM stock_moves
  WHERE qty < 0
  GROUP BY product_id
),
reval AS (
  SELECT product_id, SUM(delta_total) AS delta_total
  FROM revaluations
  GROUP BY product_id
)
SELECT p.sku, p.name,
       onhand.on_hand_qty,
       COALESCE(issued.issued_qty,0) AS issued_qty,
       ROUND(wac.base_wac, 2) AS base_wac,
       ROUND(COALESCE(reval.delta_total,0), 2) AS reval_total,
       -- Allocate proportionally to on-hand vs total receipts:
       ROUND(COALESCE(reval.delta_total,0) * (onhand.on_hand_qty * 1.0 / receipt_cost.total_receipt_qty), 2) AS reval_to_inventory,
       ROUND(COALESCE(reval.delta_total,0) - (COALESCE(reval.delta_total,0) * (onhand.on_hand_qty * 1.0 / receipt_cost.total_receipt_qty)), 2) AS variance_to_cogs,
       ROUND((wac.base_wac + (COALESCE(reval.delta_total,0) / receipt_cost.total_receipt_qty)), 4) AS naive_new_wac,
       ROUND(wac.base_wac + (COALESCE(reval.delta_total,0) * (onhand.on_hand_qty * 1.0 / receipt_cost.total_receipt_qty) / NULLIF(onhand.on_hand_qty,0)), 4) AS compliant_new_unit_cost
FROM products p
JOIN onhand ON onhand.product_id = p.product_id
JOIN receipt_cost ON receipt_cost.product_id = p.product_id
JOIN wac ON wac.product_id = p.product_id
LEFT JOIN issued ON issued.product_id = p.product_id
LEFT JOIN reval ON reval.product_id = p.product_id
WHERE p.sku = 'SKU-CHAIR';

-- Q9: Show the difference between "naive" (incorrect) and compliant approach
-- Naive: spread delta across all receipts -> changes unit cost for already issued items.
-- Compliant: only affects current inventory; rest variance.
SELECT 'Naive spreads to issued' AS approach,
       ROUND((SUM(m.qty*m.unit_cost) + r.delta_total)/SUM(m.qty), 4) AS unit_cost
FROM stock_moves m
JOIN revaluations r ON r.product_id = m.product_id
WHERE m.product_id = 1 AND m.qty > 0
UNION ALL
SELECT 'Compliant: inventory-only' AS approach,
       ROUND(
         (SUM(m.qty*m.unit_cost) + (r.delta_total * ( (SELECT SUM(qty) FROM stock_moves WHERE product_id=1) * 1.0 / SUM(m.qty) )))
         / (SELECT SUM(qty) FROM stock_moves WHERE product_id=1),
         4
       ) AS unit_cost
FROM stock_moves m
JOIN revaluations r ON r.product_id = m.product_id
WHERE m.product_id = 1 AND m.qty > 0;
