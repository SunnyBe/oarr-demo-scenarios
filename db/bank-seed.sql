INSERT INTO accounts (holder, account_num, type, balance) VALUES
  ('Marcus Blackwell', 'CHK-00192', 'checking',    12430.18),
  ('Marcus Blackwell', 'INV-00193', 'investment',  94875.00),
  ('Priya Nair',       'CHK-00287', 'checking',     8290.45),
  ('Priya Nair',       'SAV-00288', 'savings',     47250.00),
  ('Firm Operations',  'OPS-00401', 'operating',  231800.00),
  ('Firm Operations',  'RSV-00402', 'reserve',    850000.00);

INSERT INTO transactions (account_id, type, amount, description, occurred_at) VALUES
  (1, 'debit',   2400.00, 'Rent payment',                    NOW() - INTERVAL '25 days'),
  (1, 'credit',  6800.00, 'Payroll deposit',                 NOW() - INTERVAL '18 days'),
  (1, 'debit',    312.45, 'Utility bills',                   NOW() - INTERVAL '10 days'),
  (2, 'credit',  5200.00, 'Dividend reinvestment',           NOW() - INTERVAL '22 days'),
  (2, 'debit',   1875.00, 'Management fee Q4',               NOW() - INTERVAL '7 days'),
  (3, 'debit',   1950.00, 'Mortgage payment',                NOW() - INTERVAL '20 days'),
  (3, 'credit',  4600.00, 'Payroll deposit',                 NOW() - INTERVAL '18 days'),
  (4, 'credit',  5000.00, 'Annual savings contribution',     NOW() - INTERVAL '35 days'),
  (5, 'debit',  48000.00, 'Vendor payment - Q4 services',    NOW() - INTERVAL '14 days'),
  (5, 'credit',125000.00, 'Client retainer - Q1',            NOW() - INTERVAL '5 days');
