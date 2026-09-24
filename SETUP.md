# SETUP — dari ZIP sampai jalan di HP

Urutkan dari atas. Tiap langkah punya cara memastikan berhasil.

---

## 0. Prasyarat

- Flutter **3.47.5** (`flutter --version`). Jangan di-upgrade.
- `PUB_CACHE` dan `GRADLE_USER_HOME` menunjuk ke `E:\dev-cache`.
- HP Android tersambung, USB debugging aktif (`flutter devices`).

---

## 1. Siapkan folder project

Project ini tinggal di folder baru `E:\FoodPilot`. Folder lama sisa
percobaan React Native tidak bentrok karena namanya beda, jadi tidak wajib
dihapus. Kalau mau menghapusnya untuk menghemat ruang, pastikan dulu repo
lamanya sudah ter-push beserta tag `rn-final`.

Ekstrak isi ZIP ini ke `E:\FoodPilot`, lalu:

```powershell
cd E:\FoodPilot
git init -b main
git add .
git commit -m "Fondasi FoodPilot: dokumen dan kode tahap 0-9"
git branch dev
git checkout dev
```

---

## 2. Buat folder Android

ZIP ini tidak membawa seluruh folder `android/`, hanya dua file yang sudah
diubah (`app/build.gradle.kts` dan `AndroidManifest.xml`). Sisanya dibuat
`flutter create` di laptop sendiri supaya cocok dengan Flutter yang
terpasang. **File yang sudah ada tidak akan ditimpa.**

```powershell
flutter create --project-name foodpilot --org com.arbelvalley --platforms android .
flutter pub get
```

**Berhasil kalau:** muncul folder `android/`, dan
`android/app/build.gradle.kts` masih berisi baris
`isCoreLibraryDesugaringEnabled = true`. Kalau baris itu hilang berarti
file tertimpa; salin ulang dari ZIP.

---

## 3. Generate kode drift

Drift menulis `database.g.dart` dari definisi tabel. Tanpa langkah ini,
`flutter analyze` akan penuh error "`_$AppDatabase` tidak dikenal".

```powershell
dart run build_runner build --delete-conflicting-outputs
```

**Berhasil kalau:** file `lib/data/database.g.dart` muncul dan analyzer
tidak lagi mengeluh soal `_$AppDatabase`.

Ulangi perintah ini setiap kali isi `lib/data/database.dart` diubah.

---

## 4. Ikon dan splash

```powershell
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

**Berhasil kalau:** muncul file di `android/app/src/main/res/mipmap-*` dan
ikon aplikasi berubah setelah dipasang ulang.

---

## 5. Jalankan

```powershell
flutter analyze
flutter test
flutter run --dart-define-from-file=env.json
```

`env.json` belum ada di awal, dan itu tidak apa-apa: tanpa file itu
aplikasi tetap jalan penuh secara offline, konsultan AI memakai mode demo,
dan menu cadangan menampilkan keterangan bahwa Supabase belum disiapkan.
Kalau mau jalan tanpa Supabase, cukup `flutter run`.

**Berhasil kalau:** onboarding muncul, menu pertama bisa disimpan, tombol
tengah membuka layar catat, dan angka di Beranda berubah setelah menyimpan.

---

## 6. Supabase (opsional, untuk AI dan cadangan)

1. Buat project baru di Supabase, catat **Project URL** dan
   **publishable key** (`sb_publishable_...`).
2. Salin `env.example.json` menjadi `env.json`, isi kedua nilai itu.
   `env.json` sudah masuk `.gitignore`, jadi tidak akan ter-commit.
3. Jalankan isi `supabase/migrations/20260922090000_backups.sql` di SQL
   Editor. Ini membuat tabel `backups` beserta aturan RLS-nya.
4. Deploy Edge Function dan simpan kunci Gemini:

```powershell
supabase login
supabase link --project-ref <ref-project>
supabase secrets set GEMINI_API_KEY=<kunci-gemini>
supabase functions deploy analyze --no-verify-jwt
```

**Berhasil kalau:** di Profil → Pengaturan, sakelar "Mode demo konsultan
AI" bisa dimatikan, lalu Analisis → Konsultan AI mengembalikan tiga
rekomendasi yang menyebut nama menu sungguhan.

Kunci Gemini **tidak pernah** masuk ke aplikasi. Aplikasi hanya memanggil
function `analyze`; function itu yang memegang kunci.

---

## 7. Build rilis

Untuk APK yang bisa dipasang sendiri tanpa kabel:

```powershell
flutter build apk --release --dart-define-from-file=env.json
```

Tanpa `android/key.properties`, build rilis memakai kunci debug. Itu cukup
untuk demo di kelas. Kalau mau kunci sendiri:

```powershell
keytool -genkey -v -keystore E:\kunci\foodpilot.jks -keyalg RSA -keysize 2048 -validity 10000 -alias foodpilot
```

Lalu buat `android/key.properties` (sudah di-gitignore):

```properties
storePassword=...
keyPassword=...
keyAlias=foodpilot
storeFile=E:\\kunci\\foodpilot.jks
```

---

## 8. Kalau macet

| Gejala | Penyebab biasanya |
|---|---|
| `_$AppDatabase` tidak dikenal | `build_runner` belum dijalankan (langkah 3) |
| Error `Bad state: Unable to resolve` saat build_runner | Tambahkan `--delete-conflicting-outputs` |
| Build Android gagal soal `desugar` | `android/app/build.gradle.kts` tertimpa `flutter create`, salin ulang dari ZIP |
| Notifikasi tidak muncul | Izin notifikasi ditolak; cek Pengaturan HP → Aplikasi → FoodPilot |
| Analisis AI selalu error | `GEMINI_API_KEY` belum diset, atau function belum di-deploy dengan `--no-verify-jwt` |
| Drive C: penuh lagi | Cek `flutter doctor -v`, pastikan SDK dan cache di E: |
