# TASK — urutan pengerjaan

> Dokumen ini menjawab **apa selanjutnya**. Kerjakan dari atas ke bawah.

**Aturan main:** jangan centang apa pun sebelum dilihat sendiri di HP.
Kode untuk semua tahap sudah ditulis lebih dulu dan belum pernah
dikompilasi, jadi tahap-tahap di bawah kini berfungsi sebagai **daftar
verifikasi**, bukan daftar tulis-kode.
Tahap 0 sampai 4 sudah membentuk aplikasi utuh yang layak dinilai. Kalau
waktu menipis, tahap 5 ke atas boleh dipangkas.

Setiap tahap selesai: push `dev`, merge ke `main`, perbarui Jira.

---

## Tahap 0 — Fondasi

- [ ] Pastikan `PUB_CACHE` dan `GRADLE_USER_HOME` menunjuk ke `E:\dev-cache`
- [ ] `flutter doctor` bersih untuk toolchain Android
- [ ] Cek lokasi Android SDK dan Flutter SDK di `flutter doctor -v`: keduanya
      tidak boleh di C: sebelum `flutter run` pertama
- [ ] Buat repo GitHub baru (private), catat namanya di `00-BACA-DULU.md`
- [ ] `git init -b main`, commit pertama berisi dokumen, push ke `main`,
      lalu buat branch `dev`
- [ ] `flutter create --project-name foodpilot --org com.arbelvalley --platforms android .`
- [ ] Jalankan aplikasi di HP fisik, lalu commit kode ke `dev`
- [ ] Pasang dependensi inti: `flutter_riverpod`, `go_router`, `lucide_icons_flutter`
- [ ] Tambahkan font Plus Jakarta Sans (berat 400 dan 600) ke `assets/fonts/` dan `pubspec.yaml`
- [ ] Buat `tokens.dart`, `app_colors.dart`, `app_theme.dart` sesuai pemetaan di `CONTEXT.md` bagian 7
- [ ] Aktifkan lint ketat di `analysis_options.yaml`
- [ ] Buat `format.dart` berisi `formatRupiah`
- [ ] Layar uji: kartu `surface`, judul `ink`, angka `success` tabular
- [ ] Verifikasi di HP, termasuk mode gelap
- [ ] Push `dev`, merge ke `main`, perbarui Jira

**Selesai jika:** layar uji tampil dengan font dan warna yang benar di
kedua mode.

---

## Tahap 1 — Rangka navigasi

- [ ] Router dengan `StatefulShellRoute.indexedStack` untuk 4 tab
- [ ] Tab bar pil melayang sesuai `CONTEXT.md` bagian 7
- [ ] Tombol tengah tinta yang membuka catat penjualan
- [ ] Modal catat penjualan naik dari bawah dengan header kustom
- [ ] Rute bersarang yang menutupi tab bar: `/menu/:id`, `/analisis/ai`, `/profil/biaya`, `/profil/pengaturan`
- [ ] Grup onboarding sebagai halaman kosong
- [ ] AppBar menyatu dengan latar, tanpa bayangan
- [ ] Verifikasi di HP: tab berpindah, modal bisa ditutup geser, tombol
      kembali berfungsi, layar level 2 menutupi tab bar, tab bar aman dari
      tombol navigasi HP, mode gelap

**Selesai jika:** semua layar bisa dicapai dan tidak ada rute buntu.

---

## Tahap 2 — Database dan domain

- [ ] Pasang `drift`, `sqlite3_flutter_libs`, `path_provider`, `build_runner`, `drift_dev`
- [ ] Tulis tabel drift sesuai `CONTEXT.md` bagian 3
- [ ] Jalankan `build_runner`, pastikan kode tergenerasi tanpa error
- [ ] Repository per entitas
- [ ] Fungsi domain: hpp, profit, breakeven, classify, weekly_pattern
- [ ] Unit test tiap fungsi domain, termasuk kasus tepi di bagian 4
- [ ] `flutter test` hijau

**Selesai jika:** semua rumus punya test dan semua test lulus.

---

## Tahap 3 — Menu, HPP, dan onboarding

- [ ] Daftar menu dengan badge margin berwarna
- [ ] Form tambah dan ubah menu
- [ ] Baris bahan yang bisa ditambah dan dihapus
- [ ] Ringkasan HPP berubah saat mengetik
- [ ] Validasi: nama wajib, harga di atas nol, minimal satu bahan
- [ ] Menonaktifkan menu tanpa menghapus data lama
- [ ] Kondisi kosong dengan satu tombol aksi
- [ ] Alur onboarding 3 langkah
- [ ] Arahkan ke onboarding kalau tabel `business` kosong
- [ ] Tombol lewati di tiap langkah

---

## Tahap 4 — Catat penjualan dan Beranda

Inti aplikasi. Ikuti `DESAIN-catat.md`.

- [ ] Grid kartu menu dua kolom
- [ ] Tap menambah porsi, badge naik dengan animasi
- [ ] Tombol kurang, tidak bisa di bawah nol
- [ ] Bar total menempel di bawah
- [ ] Simpan dengan snapshot harga
- [ ] Catat ulang tanggal yang sama menimpa, bukan menduplikasi
- [ ] Beranda: laba bersih, progress balik modal, menu terlaris
- [ ] Layar biaya operasional dan salin dari bulan lalu
- [ ] Uji: 5 menu dalam 8 tap atau kurang

> Sampai titik ini aplikasi sudah layak dinilai.

---

## Tahap 5 — Analisis

- [ ] Tiga kelompok menu berwarna
- [ ] Rincian rumus tiap item
- [ ] Grafik pola mingguan
- [ ] Kalimat kesimpulan otomatis
- [ ] Kondisi data belum cukup
- [ ] Semua perhitungan lokal

---

## Tahap 6 — Konsultan AI

- [ ] Supabase Edge Function `analyze`
- [ ] Kunci Gemini di environment function
- [ ] Payload ringkasan dari domain
- [ ] Parsing JSON defensif
- [ ] Tiga kartu rekomendasi
- [ ] Skeleton saat menunggu
- [ ] Timeout, pesan error, tombol coba lagi
- [ ] Simpan ke riwayat
- [ ] Mode demo

---

## Tahap 7 — Fitur tambahan

- [ ] Simulasi geser
- [ ] Notifikasi pengingat
- [ ] Login dan sinkronisasi
- [ ] Export PDF
- [ ] Caption promo

---

## Tahap 8 — Pemolesan

- [ ] Kondisi kosong di setiap layar
- [ ] Umpan balik di setiap aksi
- [ ] Transisi halus
- [ ] Mode gelap di semua layar
- [ ] Uji di HP spesifikasi rendah
- [ ] Data contoh 30 hari
- [ ] Toggle data contoh di onboarding

---

## Tahap 9 — Rilis dan presentasi

- [ ] Ikon aplikasi dan splash screen
- [ ] Keystore dan APK rilis bertanda tangan
- [ ] Uji pasang di HP yang belum pernah memasangnya
- [ ] Naskah demo 8 menit
- [ ] Siapkan jawaban: angka dari mana, kenapa Flutter, tanpa internet
      bagaimana, kalau AI salah bagaimana
- [ ] Video cadangan

---

## Catatan berjalan

```
2026-09-15/16 — Project dimulai dengan React Native, Tahap 0 dan 1
selesai. Diarsipkan di repo lama, tag rn-final.

Pindah ke Flutter karena dosen mewajibkannya. Semua keputusan produk,
skema database, rumus, dan arah desain dipertahankan. Yang ditulis
ulang hanya kode.

Pelajaran dari fase React Native:
- Pemeriksaan statis bersih tidak menjamin aplikasi jalan. Verifikasi
  di HP adalah satu-satunya bukti.
- Drive C: sempat penuh total akibat cache. Semua cache dipindah ke E:.

2026-09-22 — Mulai ulang di repo git baru yang bersih, terpisah dari
repo React Native. Sistem desain direvisi setelah meninjau referensi
DocSpot (CONTEXT.md bagian 7): tab aktif berlabel, kotak statistik, pil
aksi di layar level 2, token primary berganti nama menjadi accent, serta
pemetaan ColorScheme dan TextTheme.

Hari yang sama — Kode Tahap 0 dan 1 ditulis sekaligus atas permintaan,
tanpa bisa dijalankan di lingkungan Claude. Butir TASK tetap kosong
sampai terbukti di HP. go_router dikunci di 17.x karena versi 18 memakai
paket material_ui (lihat CONTEXT.md bagian 1).

2026-09-23 — Kode Tahap 2 sampai 9 ditulis sekaligus atas permintaan:
database drift, repository, domain, seluruh layar, Edge Function, PDF,
pengingat, cadangan, ikon, dan test. Semuanya masih belum dikompilasi.
Tanda tangan API tiap paket diperiksa langsung ke kode sumber rilisnya,
bukan dari ingatan, karena banyak yang berubah di versi terbaru:
- flutter_local_notifications dikunci 21.x. Versi 23 masih dev dan minta
  compileSdk 37, sementara Flutter 3.47.5 memakai 36.
- supabase_flutter 2.17.1 memakai publishableKey, bukan anonKey.
- DropdownButtonFormField memakai initialValue, value sudah deprecated.
- ThemeData menerima InputDecorationThemeData dan DialogThemeData.
Butir TASK sengaja tetap kosong: belum ada yang terbukti.

Hari yang sama — Nama brand diganti dari Warungku menjadi FoodPilot,
sebelum kode pernah dijalankan. Ikut berubah: nama paket Dart
(foodpilot), applicationId (com.arbelvalley.foodpilot), label aplikasi,
nama file database, folder project (E:\FoodPilot), dan ikon. Karena
belum ada instalasi di HP, tidak ada data yang perlu dimigrasi.
```
