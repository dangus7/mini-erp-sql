-- Revaluation scenario (Average cost compliance demo)
-- Goal: show that adjustments for already issued stock should go to variance, not change current unit cost.

CREATE TABLE revaluations (
  reval_id    INTEGER PRIMARY KEY,
  product_id  INTEGER NOT NULL,
  reval_date  DATE NOT NULL,
  delta_total NUMERIC(12,2) NOT NULL, -- total cost adjustment amount
  reason      TEXT,
  FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Example: retroactive cost correction for Chair purchases (+30 total)
INSERT INTO revaluations (reval_id, product_id, reval_date, delta_total, reason)
VALUES (1, 1, '2026-01-20', 30.00, 'Vendor price correction for past receipt');
