-- Supabase Migration: Add balance tracking columns to transactions table
-- Run this in Supabase SQL Editor when ready to enable remote balance tracking
--
-- This migration adds balance_before and balance_after columns to track
-- wallet balance before and after each transaction, matching the local Hive storage.

-- 1. Add the new columns (nullable for backward compatibility with existing rows)
ALTER TABLE public.transactions
ADD COLUMN IF NOT EXISTS balance_before NUMERIC(18, 2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS balance_after NUMERIC(18, 2) DEFAULT 0.0;

-- 2. Add comments for documentation
COMMENT ON COLUMN public.transactions.balance_before IS 'Wallet balance before this transaction (for the payment method)';
COMMENT ON COLUMN public.transactions.balance_after IS 'Wallet balance after this transaction (for the payment method)';

-- 3. Create an index for faster balance queries (optional but recommended)
CREATE INDEX IF NOT EXISTS idx_transactions_balance
ON public.transactions (user_id, payment_method, transaction_date DESC);

-- 4. Backfill existing transactions with calculated balances (optional)
-- This calculates balances for existing transactions based on chronological order per user/payment_method
-- Run this if you want historical balance data populated
/*
WITH ordered_tx AS (
  SELECT
    id,
    user_id,
    payment_method,
    type,
    amount,
    transaction_date,
    LAG(
      CASE
        WHEN type = 'income' THEN amount
        ELSE -amount
      END
    ) OVER (PARTITION BY user_id, payment_method ORDER BY transaction_date ASC) as prev_change,
    SUM(
      CASE
        WHEN type = 'income' THEN amount
        ELSE -amount
      END
    ) OVER (PARTITION BY user_id, payment_method ORDER BY transaction_date ASC
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as running_balance
  FROM public.transactions
  WHERE user_id IS NOT NULL
)
UPDATE public.transactions t
SET
  balance_before = o.running_balance -
    CASE WHEN o.type = 'income' THEN o.amount ELSE -o.amount END,
  balance_after = o.running_balance
FROM ordered_tx o
WHERE t.id = o.id;
*/

-- 5. After migration is verified, update Dart code:
-- In transaction_model.dart, uncomment the balance fields in toSupabaseJson():
--   'balance_before': balanceBefore,
--   'balance_after': balanceAfter,
--
-- Or simply replace toSupabaseJson() with toJson() in supabase_transaction_repository.dart

-- VERIFICATION QUERIES:
-- Check columns exist:
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_name = 'transactions' AND column_name IN ('balance_before', 'balance_after');

-- Test insert with balance fields:
-- INSERT INTO public.transactions (id, user_id, amount, type, category_id, note, transaction_date, payment_method, balance_before, balance_after)
-- VALUES (gen_random_uuid(), auth.uid(), 100000, 'expense', 'food', 'Test', now(), 'cash', 500000, 400000);