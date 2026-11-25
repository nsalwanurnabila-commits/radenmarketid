-- RADENMARKET - SETUP DATABASE PROJECT SUPABASE BARU
-- Jalankan seluruh file ini di Supabase SQL Editor. Aman dijalankan ulang.
-- Hanya email pemilik yang ditentukan di bawah yang otomatis diberi akses admin.
-- Jangan pernah menaruh service_role/secret key di website.

-- 1. Tabel stok katalog
CREATE TABLE IF NOT EXISTS public.ff_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  category TEXT,
  price NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (price >= 0),
  status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available','sold')),
  image_url TEXT,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.ff_accounts ADD COLUMN IF NOT EXISTS category TEXT;
ALTER TABLE public.ff_accounts ADD COLUMN IF NOT EXISTS image_path TEXT;
ALTER TABLE public.ff_accounts ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON TABLE public.ff_accounts TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public.ff_accounts TO authenticated;
DROP POLICY IF EXISTS "Public can read stock" ON public.ff_accounts;
CREATE POLICY "Public can read stock" ON public.ff_accounts FOR SELECT TO anon, authenticated USING (true);

-- 2. Daftar admin dan pemeriksaan hak admin
CREATE TABLE IF NOT EXISTS public.admin_users (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE
);
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.admin_users FROM anon, authenticated;
CREATE OR REPLACE FUNCTION public.is_radenmarket_admin()
RETURNS BOOLEAN
LANGUAGE SQL STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = auth.uid());
$$;
REVOKE ALL ON FUNCTION public.is_radenmarket_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_radenmarket_admin() TO authenticated;
DROP POLICY IF EXISTS "Admin can insert stock" ON public.ff_accounts;
CREATE POLICY "Admin can insert stock" ON public.ff_accounts FOR INSERT TO authenticated WITH CHECK (public.is_radenmarket_admin());
DROP POLICY IF EXISTS "Admin can update stock" ON public.ff_accounts;
CREATE POLICY "Admin can update stock" ON public.ff_accounts FOR UPDATE TO authenticated USING (public.is_radenmarket_admin()) WITH CHECK (public.is_radenmarket_admin());
DROP POLICY IF EXISTS "Admin can delete stock" ON public.ff_accounts;
CREATE POLICY "Admin can delete stock" ON public.ff_accounts FOR DELETE TO authenticated USING (public.is_radenmarket_admin());

-- 3. Bukti transaksi
CREATE TABLE IF NOT EXISTS public.transaction_proofs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_name TEXT NOT NULL,
  price NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (price >= 0),
  transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
  note TEXT,
  image_url TEXT NOT NULL,
  image_path TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.transaction_proofs ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON TABLE public.transaction_proofs TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public.transaction_proofs TO authenticated;
DROP POLICY IF EXISTS "Public can view transaction proofs" ON public.transaction_proofs;
CREATE POLICY "Public can view transaction proofs" ON public.transaction_proofs FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "Admins can insert transaction proofs" ON public.transaction_proofs;
CREATE POLICY "Admins can insert transaction proofs" ON public.transaction_proofs FOR INSERT TO authenticated WITH CHECK (public.is_radenmarket_admin());
DROP POLICY IF EXISTS "Admins can update transaction proofs" ON public.transaction_proofs;
CREATE POLICY "Admins can update transaction proofs" ON public.transaction_proofs FOR UPDATE TO authenticated USING (public.is_radenmarket_admin()) WITH CHECK (public.is_radenmarket_admin());
DROP POLICY IF EXISTS "Admins can delete transaction proofs" ON public.transaction_proofs;
CREATE POLICY "Admins can delete transaction proofs" ON public.transaction_proofs FOR DELETE TO authenticated USING (public.is_radenmarket_admin());

-- 4. Storage foto bukti transaksi
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('transaction-proofs', 'transaction-proofs', true, 8388608, ARRAY['image/jpeg','image/png','image/webp'])
ON CONFLICT (id) DO UPDATE SET public = EXCLUDED.public, file_size_limit = EXCLUDED.file_size_limit, allowed_mime_types = EXCLUDED.allowed_mime_types;
DROP POLICY IF EXISTS "Public can view transaction proof images" ON storage.objects;
CREATE POLICY "Public can view transaction proof images" ON storage.objects FOR SELECT TO anon, authenticated USING (bucket_id = 'transaction-proofs');
DROP POLICY IF EXISTS "Admins can upload transaction proof images" ON storage.objects;
CREATE POLICY "Admins can upload transaction proof images" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'transaction-proofs' AND public.is_radenmarket_admin());
DROP POLICY IF EXISTS "Admins can update transaction proof images" ON storage.objects;
CREATE POLICY "Admins can update transaction proof images" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'transaction-proofs' AND public.is_radenmarket_admin()) WITH CHECK (bucket_id = 'transaction-proofs' AND public.is_radenmarket_admin());
DROP POLICY IF EXISTS "Admins can delete transaction proof images" ON storage.objects;
CREATE POLICY "Admins can delete transaction proof images" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'transaction-proofs' AND public.is_radenmarket_admin());

-- 5. Daftarkan akun pemilik yang mungkin sudah ada di Auth Users.
INSERT INTO public.admin_users (user_id)
SELECT id FROM auth.users WHERE lower(email) = 'mahdialdama@gmail.com'
ON CONFLICT (user_id) DO NOTHING;

-- 6. Otomatis beri akses admin hanya kepada email pemilik saat akun dibuat.
CREATE OR REPLACE FUNCTION public.assign_radenmarket_owner_admin()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF lower(coalesce(NEW.email, '')) = 'mahdialdama@gmail.com' THEN
    INSERT INTO public.admin_users (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.assign_radenmarket_owner_admin() FROM PUBLIC, anon, authenticated;
DROP TRIGGER IF EXISTS on_auth_user_created_radenmarket_admin ON auth.users;
CREATE TRIGGER on_auth_user_created_radenmarket_admin
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.assign_radenmarket_owner_admin();

-- 7. Pesanan pelanggan (kode unik dan status yang dikelola admin)
CREATE TABLE IF NOT EXISTS public.customer_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_code TEXT NOT NULL UNIQUE,
  product_id UUID,
  product_name TEXT NOT NULL,
  order_type TEXT NOT NULL CHECK (order_type IN ('BELI','NEGO','CICIL')),
  price NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (price >= 0),
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','processing','completed','cancelled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.customer_orders ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.customer_orders FROM anon, authenticated;
GRANT SELECT, UPDATE ON TABLE public.customer_orders TO authenticated;
DROP POLICY IF EXISTS "Admins can view customer orders" ON public.customer_orders;
CREATE POLICY "Admins can view customer orders" ON public.customer_orders FOR SELECT TO authenticated USING (public.is_radenmarket_admin());
DROP POLICY IF EXISTS "Admins can update customer orders" ON public.customer_orders;
CREATE POLICY "Admins can update customer orders" ON public.customer_orders FOR UPDATE TO authenticated USING (public.is_radenmarket_admin()) WITH CHECK (public.is_radenmarket_admin());

-- Pelanggan membuat pesanan melalui RPC; tabel tidak bisa diinsert langsung dari browser.
CREATE OR REPLACE FUNCTION public.radenmarket_create_order(
  p_product_id UUID,
  p_order_type TEXT,
  p_customer_name TEXT,
  p_customer_phone TEXT
) RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE v_product public.ff_accounts%ROWTYPE; v_code TEXT;
BEGIN
  IF p_order_type NOT IN ('BELI','NEGO','CICIL') THEN RAISE EXCEPTION 'Jenis pesanan tidak valid.'; END IF;
  IF length(trim(coalesce(p_customer_name,''))) < 2 OR length(trim(p_customer_name)) > 80 THEN RAISE EXCEPTION 'Nama pemesan tidak valid.'; END IF;
  IF length(regexp_replace(coalesce(p_customer_phone,''),'[^0-9]','','g')) NOT BETWEEN 9 AND 15 THEN RAISE EXCEPTION 'Nomor WhatsApp tidak valid.'; END IF;
  SELECT * INTO v_product FROM public.ff_accounts WHERE id=p_product_id AND status='available';
  IF NOT FOUND THEN RAISE EXCEPTION 'Akun tidak tersedia atau sudah terjual.'; END IF;
  v_code := 'RM' || to_char(now(),'YYMMDD') || upper(substr(md5(random()::text || clock_timestamp()::text),1,8));
  INSERT INTO public.customer_orders(order_code,product_id,product_name,order_type,price,customer_name,customer_phone)
  VALUES(v_code,v_product.id,v_product.name,p_order_type,v_product.price,trim(p_customer_name),CASE WHEN regexp_replace(p_customer_phone,'[^0-9]','','g') LIKE '0%' THEN '62' || substr(regexp_replace(p_customer_phone,'[^0-9]','','g'),2) ELSE regexp_replace(p_customer_phone,'[^0-9]','','g') END);
  RETURN v_code;
END;
$$;
REVOKE ALL ON FUNCTION public.radenmarket_create_order(UUID,TEXT,TEXT,TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.radenmarket_create_order(UUID,TEXT,TEXT,TEXT) TO anon, authenticated;

-- Pelacakan hanya mengembalikan data pesanan jika kode dan nomor WhatsApp cocok.
DROP FUNCTION IF EXISTS public.radenmarket_lookup_order(TEXT,TEXT);
CREATE FUNCTION public.radenmarket_lookup_order(p_order_code TEXT,p_customer_name TEXT)
RETURNS TABLE(order_code TEXT,product_name TEXT,order_type TEXT,price NUMERIC,status TEXT,created_at TIMESTAMPTZ)
LANGUAGE SQL STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT o.order_code,o.product_name,o.order_type,o.price,o.status,o.created_at
  FROM public.customer_orders o
  WHERE upper(o.order_code)=upper(trim(p_order_code))
    AND lower(trim(o.customer_name))=lower(trim(p_customer_name))
  LIMIT 1;
$$;
REVOKE ALL ON FUNCTION public.radenmarket_lookup_order(TEXT,TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.radenmarket_lookup_order(TEXT,TEXT) TO anon, authenticated;

-- 8. Pengumuman yang bisa dikelola admin dan dibaca publik saat aktif.
CREATE TABLE IF NOT EXISTS public.announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL CHECK (length(title) BETWEEN 1 AND 90),
  body TEXT NOT NULL CHECK (length(body) BETWEEN 1 AND 500),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON TABLE public.announcements TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public.announcements TO authenticated;
DROP POLICY IF EXISTS "Public can read active announcements" ON public.announcements;
CREATE POLICY "Public can read active announcements" ON public.announcements FOR SELECT TO anon, authenticated USING (is_active=true OR public.is_radenmarket_admin());
DROP POLICY IF EXISTS "Admins can insert announcements" ON public.announcements;
CREATE POLICY "Admins can insert announcements" ON public.announcements FOR INSERT TO authenticated WITH CHECK (public.is_radenmarket_admin());
DROP POLICY IF EXISTS "Admins can update announcements" ON public.announcements;
CREATE POLICY "Admins can update announcements" ON public.announcements FOR UPDATE TO authenticated USING (public.is_radenmarket_admin()) WITH CHECK (public.is_radenmarket_admin());
DROP POLICY IF EXISTS "Admins can delete announcements" ON public.announcements;
CREATE POLICY "Admins can delete announcements" ON public.announcements FOR DELETE TO authenticated USING (public.is_radenmarket_admin());


-- 9. Permintaan jasa Unban WhatsApp dan pelacakan status
CREATE TABLE IF NOT EXISTS public.unban_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  unban_code TEXT NOT NULL UNIQUE,
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,
  blocked_date DATE NOT NULL,
  unban_type TEXT NOT NULL CHECK (unban_type IN ('Permanen','Tinjau')),
  price NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (price >= 0),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','processing','restored','failed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.unban_requests ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.unban_requests FROM anon, authenticated;
GRANT SELECT, UPDATE ON TABLE public.unban_requests TO authenticated;
DROP POLICY IF EXISTS "Admins can view unban requests" ON public.unban_requests;
CREATE POLICY "Admins can view unban requests" ON public.unban_requests
  FOR SELECT TO authenticated USING (public.is_radenmarket_admin());
DROP POLICY IF EXISTS "Admins can update unban requests" ON public.unban_requests;
CREATE POLICY "Admins can update unban requests" ON public.unban_requests
  FOR UPDATE TO authenticated USING (public.is_radenmarket_admin())
  WITH CHECK (public.is_radenmarket_admin());

CREATE OR REPLACE FUNCTION public.radenmarket_create_unban_request(
  p_customer_name TEXT,
  p_customer_phone TEXT,
  p_blocked_date DATE,
  p_unban_type TEXT
) RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE v_code TEXT; v_price NUMERIC(14,2);
BEGIN
  IF length(trim(coalesce(p_customer_name,''))) < 2 OR length(trim(p_customer_name)) > 80
    THEN RAISE EXCEPTION 'Nama pembeli tidak valid.'; END IF;
  IF length(regexp_replace(coalesce(p_customer_phone,''),'[^0-9]','','g')) NOT BETWEEN 9 AND 15
    THEN RAISE EXCEPTION 'Nomor WhatsApp tidak valid.'; END IF;
  IF p_unban_type NOT IN ('Permanen','Tinjau') THEN RAISE EXCEPTION 'Jenis layanan tidak valid.'; END IF;
  IF p_blocked_date IS NULL OR p_blocked_date > CURRENT_DATE THEN RAISE EXCEPTION 'Tanggal kejadian tidak valid.'; END IF;
  v_price := CASE WHEN p_unban_type='Permanen' THEN 100000 ELSE 50000 END;
  v_code := 'UNB' || to_char(now(),'YYMMDD') || upper(substr(md5(random()::text || clock_timestamp()::text),1,8));
  INSERT INTO public.unban_requests(unban_code,customer_name,customer_phone,blocked_date,unban_type,price)
  VALUES(v_code,trim(p_customer_name),CASE WHEN regexp_replace(p_customer_phone,'[^0-9]','','g') LIKE '0%'
    THEN '62'||substr(regexp_replace(p_customer_phone,'[^0-9]','','g'),2)
    ELSE regexp_replace(p_customer_phone,'[^0-9]','','g') END,p_blocked_date,p_unban_type,v_price);
  RETURN v_code;
END;
$$;
REVOKE ALL ON FUNCTION public.radenmarket_create_unban_request(TEXT,TEXT,DATE,TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.radenmarket_create_unban_request(TEXT,TEXT,DATE,TEXT) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.radenmarket_lookup_unban(p_unban_code TEXT,p_customer_name TEXT,p_customer_phone TEXT)
RETURNS TABLE(unban_code TEXT,customer_name TEXT,unban_type TEXT,price NUMERIC,status TEXT,blocked_date DATE,created_at TIMESTAMPTZ)
LANGUAGE SQL STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT u.unban_code,u.customer_name,u.unban_type,u.price,u.status,u.blocked_date,u.created_at
  FROM public.unban_requests u
  WHERE upper(u.unban_code)=upper(trim(p_unban_code))
    AND lower(trim(u.customer_name))=lower(trim(p_customer_name))
    AND regexp_replace(u.customer_phone,'[^0-9]','','g')=regexp_replace(p_customer_phone,'[^0-9]','','g')
  LIMIT 1;
$$;
REVOKE ALL ON FUNCTION public.radenmarket_lookup_unban(TEXT,TEXT,TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.radenmarket_lookup_unban(TEXT,TEXT,TEXT) TO anon, authenticated;


-- 15. Katalog rental akun game RadenMarket
CREATE TABLE IF NOT EXISTS public.rental_accounts (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 game_name TEXT NOT NULL,
 account_name TEXT NOT NULL,
 specs TEXT,
 prices JSONB NOT NULL DEFAULT '{"1":0,"3":0,"6":0,"12":0,"24":0}'::jsonb,
 status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available','unavailable')),
 image_url TEXT,
 image_path TEXT,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.rental_accounts ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON public.rental_accounts TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.rental_accounts TO authenticated;
DROP POLICY IF EXISTS "Public can read rental accounts" ON public.rental_accounts;
CREATE POLICY "Public can read rental accounts" ON public.rental_accounts FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "Admins manage rental accounts" ON public.rental_accounts;
CREATE POLICY "Admins manage rental accounts" ON public.rental_accounts FOR ALL TO authenticated USING (public.is_radenmarket_admin()) WITH CHECK (public.is_radenmarket_admin());
