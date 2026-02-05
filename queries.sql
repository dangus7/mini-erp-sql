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
