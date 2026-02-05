INSERT INTO customers (customer_id, name) VALUES
(1,'Alice s.r.o.'),(2,'Bob a.s.');

INSERT INTO products (product_id, sku, name) VALUES
(1,'SKU-CHAIR','Chair'),
(2,'SKU-DESK','Desk');

-- Stock receipts (in) with costs + issues (out)
INSERT INTO stock_moves (move_id, product_id, move_date, qty, unit_cost, ref) VALUES
(1, 1, '2026-01-02',  10, 50.00, 'PO-001'),   -- +10 chairs @50
(2, 1, '2026-01-05',  -4, NULL,  'SO-001'),   -- -4 chairs
(3, 1, '2026-01-10',   6, 55.00, 'PO-002'),   -- +6 chairs @55
(4, 1, '2026-01-15',  -3, NULL,  'SO-002'),   -- -3 chairs

(5, 2, '2026-01-03',   5, 120.00,'PO-003'),   -- +5 desks @120
(6, 2, '2026-01-12',  -2, NULL,  'SO-003');   -- -2 desks

INSERT INTO orders (order_id, customer_id, order_date, status) VALUES
(1,1,'2026-01-05','confirmed'),
(2,1,'2026-01-15','confirmed'),
(3,2,'2026-01-12','confirmed');

INSERT INTO order_lines (order_line_id, order_id, product_id, qty, unit_price) VALUES
(1,1,1,4,90.00),
(2,2,1,3,95.00),
(3,3,2,2,180.00);

INSERT INTO invoices (invoice_id, order_id, invoice_date, status) VALUES
(1,1,'2026-01-06','paid'),
(2,2,'2026-01-16','open'),
(3,3,'2026-01-13','paid');

INSERT INTO payments (payment_id, invoice_id, pay_date, amount) VALUES
(1,1,'2026-01-07',360.00),
(2,3,'2026-01-14',360.00);
