-- Customers
CREATE TABLE customers (
  customer_id INTEGER PRIMARY KEY,
  name        TEXT NOT NULL
);

-- Products
CREATE TABLE products (
  product_id  INTEGER PRIMARY KEY,
  sku         TEXT NOT NULL UNIQUE,
  name        TEXT NOT NULL
);

-- Inventory movements (goods in/out)
-- qty > 0 = receipt (in), qty < 0 = issue (out)
CREATE TABLE stock_moves (
  move_id     INTEGER PRIMARY KEY,
  product_id  INTEGER NOT NULL,
  move_date   DATE NOT NULL,
  qty         INTEGER NOT NULL,
  unit_cost   NUMERIC(12,2),      -- only for receipts; NULL for issues
  ref         TEXT,
  FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Sales orders
CREATE TABLE orders (
  order_id    INTEGER PRIMARY KEY,
  customer_id INTEGER NOT NULL,
  order_date  DATE NOT NULL,
  status      TEXT NOT NULL CHECK (status IN ('draft','confirmed','invoiced','cancelled')),
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_lines (
  order_line_id INTEGER PRIMARY KEY,
  order_id      INTEGER NOT NULL,
  product_id    INTEGER NOT NULL,
  qty           INTEGER NOT NULL,
  unit_price    NUMERIC(12,2) NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders(order_id),
  FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Invoices and payments
CREATE TABLE invoices (
  invoice_id   INTEGER PRIMARY KEY,
  order_id     INTEGER NOT NULL,
  invoice_date DATE NOT NULL,
  status       TEXT NOT NULL CHECK (status IN ('open','paid','cancelled')),
  FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE payments (
  payment_id   INTEGER PRIMARY KEY,
  invoice_id   INTEGER NOT NULL,
  pay_date     DATE NOT NULL,
  amount       NUMERIC(12,2) NOT NULL,
  FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id)
);
