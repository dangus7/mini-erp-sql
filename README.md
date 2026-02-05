# Mini ERP (SQL) – Inventory + Invoicing + Average Cost

Small portfolio project demonstrating ERP-style data modeling and SQL queries:
- inventory movements (receipts/issues)
- orders + invoices + payments
- reporting queries (revenue, outstanding invoices, valuation)
- average/weighted average cost examples

## Files
- schema.sql – tables
- seed.sql – sample data
- queries.sql – reporting queries (ERP/BI style)

## Why this project
Focus on practical ERP problems: totals, outstanding balances, inventory valuation and cost logic.

## Average cost revaluation (compliance demo)

Demonstrates an inventory revaluation (+30) under Average costing.
A naive approach spreads the adjustment across all historical receipts (unit cost = 52.875),
incorrectly affecting already issued quantities.
The compliant approach allocates the adjustment only to on-hand inventory
(unit cost = 54.3333) and books the remainder as variance (COGS),
preventing retroactive cost changes.
