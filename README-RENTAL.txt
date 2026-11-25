FITUR RENTAL AKUN RADENMARKET
============================

Perubahan:
- Pintasan HOT di halaman utama diarahkan ke katalog Rental Akun.
- Katalog rental memakai tema navy/ungu RadenMarket dan responsif untuk HP.
- Admin dapat menambah, mengedit, dan menghapus akun rental.
- Admin dapat mengubah nama game, nama akun, foto, spesifikasi, status, serta harga durasi 1, 3, 6, 12, dan 24 jam.
- Tombol Rental Sekarang membuka WhatsApp CS dengan detail akun dan daftar harga.
- Fitur lama pada paket sumber tetap disertakan.

LANGKAH WAJIB:
1. Buka Supabase project yang sudah dipakai website ini.
2. SQL Editor > New query, jalankan SELURUH isi setup_database.sql terbaru dari ZIP ini. SQL rental ada di bagian paling bawah. Aman dijalankan ulang.
3. Deploy isi folder ZIP ke Netlify (index.html harus di root folder deploy).
4. Login Admin. Panel Kelola Katalog Rental akan muncul.
5. Tambahkan akun rental percobaan dan cek katalog publik.

CATATAN:
- Harga dan durasi rental bisa diatur per akun. Nilai harga kosong dianggap Rp0 dan tidak ditampilkan sebagai paket harga.
- Pesanan rental pada versi ini diarahkan ke WhatsApp untuk konfirmasi manual; belum ada pembayaran otomatis, timer sewa, atau penguncian akun otomatis.
- Jangan membagikan password admin atau Supabase secret/service_role key.
