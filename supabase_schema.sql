-- ==============================================================================
-- Schema Supabase untuk WatchYourMoney (Table 'transactions' & RLS Security)
-- Jalankan script SQL ini di Supabase Dashboard -> SQL Editor -> New query -> RUN
-- ==============================================================================

-- 1. Buat tabel 'transactions' jika belum ada
CREATE TABLE IF NOT EXISTS public.transactions (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    amount NUMERIC NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
    category_id TEXT DEFAULT 'uncategorized',
    note TEXT DEFAULT '',
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT now(),
    payment_method TEXT DEFAULT 'cash' CHECK (payment_method IN ('cash', 'card')),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Aktifkan Row Level Security (RLS) agar data aman per user
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- 3. Kebijakan akses (User hanya dapat melihat, menambah, mengubah, dan menghapus data miliknya)
DROP POLICY IF EXISTS "Users can view their own transactions" ON public.transactions;
CREATE POLICY "Users can view their own transactions" 
ON public.transactions FOR SELECT 
TO authenticated 
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own transactions" ON public.transactions;
CREATE POLICY "Users can insert their own transactions" 
ON public.transactions FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own transactions" ON public.transactions;
CREATE POLICY "Users can update their own transactions" 
ON public.transactions FOR UPDATE 
TO authenticated 
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own transactions" ON public.transactions;
CREATE POLICY "Users can delete their own transactions" 
ON public.transactions FOR DELETE 
TO authenticated 
USING (auth.uid() = user_id);

-- 4. Index untuk performa query cepat berdasarkan user_id dan tanggal
CREATE INDEX IF NOT EXISTS idx_transactions_user_date 
ON public.transactions (user_id, transaction_date DESC);
