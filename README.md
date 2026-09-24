# FoodPilot

Aplikasi Android untuk mencatat penjualan harian UMKM dan melihat menu mana
yang benar-benar menguntungkan. Project akhir mata kuliah Pemrograman Mobile
(CIE 511), dibangun dengan Flutter 3.47.5.

Semua perhitungan berjalan di HP dan tetap berfungsi tanpa internet. AI
hanya dipakai untuk menarasikan angka yang sudah dihitung aplikasi.

Mulai dari [`00-BACA-DULU.md`](00-BACA-DULU.md) untuk konteks, atau langsung
ke [`SETUP.md`](SETUP.md) untuk menjalankan.

## Menjalankan singkat

```powershell
flutter create --project-name foodpilot --org com.arbelvalley --platforms android .
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

Langkah lengkap, termasuk Supabase dan build rilis, ada di `SETUP.md`.

## Dokumen

| File | Isi |
|---|---|
| `00-BACA-DULU.md` | Konteks project dan cara kerja |
| `PRD.md` | Kenapa produk ini ada, fitur, lingkupnya |
| `CONTEXT.md` | Arsitektur, skema database, rumus, sistem desain |
| `TASK.md` | Daftar verifikasi per tahap |
| `DESAIN-catat.md` | Rancangan layar catat penjualan |
| `SETUP.md` | Dari ZIP sampai jalan di HP |

Font Plus Jakarta Sans berlisensi SIL Open Font License 1.1
(`assets/fonts/OFL.txt`).
