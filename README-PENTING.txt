RADENMARKET - KONEKSI SUPABASE BARU
===================================

Perubahan pada paket ini:
- index.html kini memakai URL project Supabase baru: zohhcndgfuvcugikqgwf.
- Publishable key memakai key baru yang diberikan pemilik.
- Form tambah/edit stok kini mendukung pilih foto langsung dari galeri HP; foto diunggah ke Supabase Storage bucket transaction-proofs pada folder stock-images.
- Foto stok lama otomatis dibersihkan dari Storage saat diganti atau stok dihapus.
- Tampilan, katalog, alur WhatsApp, jasa bantuan pemulihan WhatsApp, dan halaman bukti transaksi tetap dipertahankan.
- setup_database.sql menyiapkan tabel stok, admin, bukti transaksi, kebijakan RLS, dan bucket foto bukti dalam satu kali proses.

PENTING: Database Supabase baru masih kosong. Data stok dan bukti transaksi dari project lama tidak otomatis ikut pindah. Jika tidak ada ekspor/backup project lama, data lama perlu dimasukkan kembali.

LANGKAH WAJIB SEBELUM DEPLOY
----------------------------
1. Buka project Supabase yang dipakai website ini.
2. Buka Supabase > SQL Editor > New query. Tempel seluruh isi setup_database.sql lalu tekan Run (termasuk penambahan kolom image_path). SQL ini menyiapkan tabel dan memberi hak admin hanya kepada email pemilik mahdialdama@gmail.com, termasuk bila akun tersebut sudah ada.
3. Deploy ulang isi folder hasil ekstrak ZIP ini ke Netlify.
4. Buka situs > menu Admin. Masukkan email mahdialdama@gmail.com dan password minimal 8 karakter, lalu tekan Buat Akun Admin. Jika konfirmasi email aktif, buka email dan konfirmasi dahulu sebelum login.
5. Buka Authentication > URL Configuration:
   - Site URL: isi URL utama Netlify milikmu, misalnya https://NAMA-SITUS.netlify.app
   - Redirect URLs: tambahkan https://NAMA-SITUS.netlify.app/**
   Ganti contoh tersebut dengan domain Netlify yang benar-benar kamu pakai. Jika memakai custom domain, tambahkan juga domain itu.
6. Pastikan Site URL dan Redirect URLs memakai domain Netlify yang benar.
7. Pastikan index.html berada langsung di root folder deploy.
8. Login menggunakan email pemilik dan password yang baru dibuat.
9. Uji tambah stok percobaan, edit, hapus, lalu uji upload satu foto bukti transaksi. Hapus stok percobaan setelah tes.

CATATAN LOGIN & LUPA PASSWORD
-----------------------------
- Login admin memakai akun yang dibuat melalui tombol Buat Akun Admin. Pendaftaran dibatasi ke email pemilik yang tertulis di SQL dan juga divalidasi di database.
- Lupa password mengirim tautan ke email user admin. Pastikan SMTP/email Supabase aktif dan URL Netlify sudah dimasukkan ke Redirect URLs.
- Jika email reset tidak masuk, periksa Spam dan pengaturan email Auth di Supabase. Pengiriman email default Supabase dapat memiliki batasan.

KEAMANAN
--------
- Publishable key di index.html memang boleh digunakan pada browser. Jangan pernah menaruh Secret key atau service_role key di website.
- Jangan bagikan password admin, OTP, atau secret key.
- Pemulihan akun WhatsApp tidak dijamin; gunakan proses banding/pemulihan resmi dan jangan meminta OTP/PIN/password pelanggan.
- Foto bukti transaksi di bucket publik dapat dilihat pengunjung. Samarkan data pribadi sebelum mengunggah.


FITUR TAMBAHAN RADENMARKET (PESANAN, FAVORIT, PENGUMUMAN, CS)
--------------------------------------------------------------
1. Setelah deploy ZIP versi baru, buka Supabase > SQL Editor.
2. Jalankan seluruh isi setup_database.sql lagi. File ini aman dijalankan ulang dan sekarang juga membuat tabel customer_orders serta announcements dan fungsi RPC untuk membuat/melacak pesanan.
3. Fitur Lacak Pesanan baru aktif setelah SQL berhasil dijalankan. Pelanggan membuat pesanan dari tombol Detail dengan mengisi nama dan nomor WhatsApp. Kode pesanan akan ditampilkan; simpan kode dan nomor WhatsApp untuk melacak.
4. Admin masuk ke dashboard untuk mengubah status pesanan: Menunggu konfirmasi, Diproses, Selesai, atau Dibatalkan. Pesanan tidak menandakan pembayaran sudah diterima.
5. Favorit disimpan lokal pada browser/perangkat pelanggan, bukan tersinkron antar perangkat.
6. Pengumuman dibuat, diedit, dan dihapus melalui dashboard admin. Hanya pengumuman aktif yang terlihat publik.
7. Floating CS menggunakan nomor WhatsApp khusus 6285199274698.
8. Jangan menghapus tabel atau bucket lama. Jangan menaruh service_role/secret key di index.html.


FITUR PELACAKAN JASA UNBAN WHATSAPP
- Formulir Unban meminta nama pembeli dan nomor WhatsApp yang terblokir.
- Saat formulir dikirim, permintaan disimpan ke Supabase dan kode UNB dibuat otomatis.
- Pelanggan melacak dengan kode Unban, nama pembeli, dan nomor WhatsApp yang sama.
- Admin dapat mengubah status di dashboard > Kelola Permintaan Unban:
  Menunggu konfirmasi, Sedang diproses, Sudah terpulihkan, Tidak berhasil dipulihkan.
- Jalankan seluruh setup_database.sql terbaru di Supabase sebelum deploy website.
