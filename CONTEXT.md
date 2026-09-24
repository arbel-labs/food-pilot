# CONTEXT — arsitektur teknis

> Dokumen ini menjawab **bagaimana** aplikasi dibangun.

---

## 1. Stack

| Kebutuhan | Pilihan | Alasan |
|---|---|---|
| Framework | Flutter 3.47.5 | Diwajibkan dosen |
| Routing | `go_router` | Rute deklaratif, dukung shell route untuk tab |
| State | `flutter_riverpod` | Standar komunitas, mudah dites |
| Database | `drift` + `drift_flutter` | SQLite bertipe, query diperiksa saat kompilasi. SQLite dibundel lewat build hooks paket `sqlite3`, tanpa `sqlite3_flutter_libs` |
| Ikon | `lucide_icons_flutter` | Garis tipis, cocok dengan arah desain |
| Font | Plus Jakarta Sans, aset lokal | Tidak butuh internet, tidak berkedip |
| Backend | `supabase_flutter` | Auth dan edge function |
| Model AI | Gemini Flash via Supabase Edge Function | Free tier, kunci aman di server |
| Test | `flutter_test` | Bawaan Flutter |

**Catatan belajar:**
- Riverpod ditulis manual dulu, **tanpa** `riverpod_generator`. Lebih
  mudah dipahami, dan mengurangi satu lapis code generation.
- Drift butuh `build_runner` untuk menghasilkan kode. Itu satu-satunya
  code generation di project ini.
- Font sengaja **tidak** memakai paket `google_fonts`, karena paket itu
  mengunduh font saat runtime. Aplikasi ini offline-first.
- `go_router` dikunci di `^17.5.0`. Mulai versi 18, go_router memakai
  paket `material_ui`, sedangkan app ini memakai
  `package:flutter/material.dart` seperti template Flutter 3.47.5. Kalau
  dicampur, go_router tidak mengenali `MaterialApp` kita dan transisi
  halaman hilang. Jangan naikkan ke 18 sebelum seluruh import pindah ke
  `material_ui`.

**Versi yang dipakai** (ditulis di `pubspec.yaml`, semuanya diperiksa ke
kode sumber rilisnya, bukan dari ingatan):

| Paket | Versi | Catatan |
|---|---|---|
| `flutter_riverpod` | `^3.0.0` | `Notifier` dan `NotifierProvider`; `StateProvider` sudah pindah ke `legacy.dart` |
| `go_router` | `>=17.0.0 <18.0.0` | lihat catatan di atas |
| `drift` + `drift_flutter` | `^2.35.0`, `^0.3.1` | `driftDatabase(name:)` yang mengurus lokasi file |
| `supabase_flutter` | `^2.17.1` | `Supabase.initialize(url:, publishableKey:)`, bukan `anonKey` |
| `flutter_local_notifications` | `^22.3.1` | versi 21 bentrok dengan `pdf` lewat paket `xml`; API dan syarat Android 22 sama dengan 21 (`compileSdk 36`, desugaring 2.1.4). Versi 23 masih dev dan menuntut `compileSdk 37` |
| `pdf` + `printing` | `^3.13.1`, `^5.15.1` | laporan bulanan |
| `timezone` | `^0.11.0` | wajib untuk notifikasi terjadwal |

**Jangan upgrade Flutter di tengah semester.**

---

## 2. Prinsip arsitektur

**Offline-first.** Database lokal adalah sumber kebenaran. Tulis ke lokal
dulu, UI langsung berubah, sinkronisasi berjalan belakangan. Semua fitur
kecuali konsultan AI berfungsi tanpa internet.

**Perhitungan di lapisan domain.** Semua matematika bisnis ada di
`lib/domain/` sebagai fungsi Dart murni: tanpa Flutter, tanpa database,
tanpa efek samping. Mudah diuji, dan saat sidang tinggal tunjuk satu
folder ketika ditanya "rumusnya dari mana".

**AI tidak pernah menghitung.** Angka dihitung di domain, dikirim ke AI
sebagai ringkasan jadi. AI hanya menulis narasi dan rekomendasi.

**Snapshot harga di tiap transaksi.** `sale_items` menyimpan harga jual
dan modal saat transaksi terjadi. Kalau harga bahan naik bulan depan,
laporan bulan lalu tetap menampilkan angka bulan lalu.

---

## 3. Skema database

SQL di bawah adalah **acuan kolom dan tipe**. Implementasinya ditulis
sebagai kelas tabel drift di `lib/data/database.dart`.

```sql
CREATE TABLE business (
  id             TEXT PRIMARY KEY,
  name           TEXT NOT NULL,
  type           TEXT NOT NULL,        -- 'kuliner' | 'fashion' | 'jasa'
  open_time      TEXT,                 -- 'HH:MM'
  close_time     TEXT,
  operating_days INTEGER NOT NULL DEFAULT 30,
  created_at     INTEGER NOT NULL,
  updated_at     INTEGER NOT NULL
);

CREATE TABLE products (
  id          TEXT PRIMARY KEY,
  business_id TEXT NOT NULL REFERENCES business(id),
  name        TEXT NOT NULL,
  category    TEXT,
  sell_price  INTEGER NOT NULL,       -- rupiah
  is_active   INTEGER NOT NULL DEFAULT 1,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  created_at  INTEGER NOT NULL,
  updated_at  INTEGER NOT NULL
);

CREATE TABLE ingredients (
  id          TEXT PRIMARY KEY,
  product_id  TEXT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  qty         REAL NOT NULL,          -- jumlah bahan, boleh desimal
  unit        TEXT NOT NULL,          -- 'gram' | 'ml' | 'pcs' | 'sdm'
  unit_price  INTEGER NOT NULL,       -- rupiah per satuan
  created_at  INTEGER NOT NULL
);

CREATE TABLE sales (
  id          TEXT PRIMARY KEY,
  business_id TEXT NOT NULL REFERENCES business(id),
  sale_date   TEXT NOT NULL,          -- 'YYYY-MM-DD'
  note        TEXT,
  created_at  INTEGER NOT NULL,
  updated_at  INTEGER NOT NULL,
  UNIQUE (business_id, sale_date)
);

CREATE TABLE sale_items (
  id         TEXT PRIMARY KEY,
  sale_id    TEXT NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL REFERENCES products(id),
  qty        INTEGER NOT NULL,
  unit_price INTEGER NOT NULL,        -- snapshot harga jual
  unit_cost  INTEGER NOT NULL         -- snapshot HPP
);

CREATE TABLE operating_costs (
  id          TEXT PRIMARY KEY,
  business_id TEXT NOT NULL REFERENCES business(id),
  period      TEXT NOT NULL,          -- 'YYYY-MM'
  name        TEXT NOT NULL,
  amount      INTEGER NOT NULL,
  created_at  INTEGER NOT NULL,
  UNIQUE (business_id, period, name)
);

CREATE TABLE ai_analyses (
  id            TEXT PRIMARY KEY,
  business_id   TEXT NOT NULL REFERENCES business(id),
  period_start  TEXT NOT NULL,
  period_end    TEXT NOT NULL,
  input_summary TEXT NOT NULL,        -- JSON yang dikirim
  result        TEXT NOT NULL,        -- JSON hasil
  created_at    INTEGER NOT NULL
);
```

**Aturan tipe:**
- **Uang selalu `int` rupiah**, tidak pernah `double`. Floating point
  tidak akurat untuk uang, dan kesalahannya menumpuk di laporan bulanan.
- Timestamp sebagai `int` epoch milidetik.
- Tanggal transaksi sebagai teks `YYYY-MM-DD`, aman diurutkan dan bebas
  masalah zona waktu.
- ID sebagai UUID yang dibuat di perangkat, syarat offline-first.

---

## 4. Rumus domain

Kontrak yang tidak boleh diubah tanpa memperbarui test.

```
hpp(product)            = Σ (ingredient.qty × ingredient.unit_price)
margin(product)         = (sell_price − hpp) / sell_price
profitPerUnit(product)  = sell_price − hpp

grossProfit(item)       = (unit_price − unit_cost) × qty
dailyRevenue(sale)      = Σ (unit_price × qty)
dailyGrossProfit(sale)  = Σ grossProfit(item)

dailyFixedCost          = Σ operating_costs.amount / operating_days
dailyNetProfit(sale)    = dailyGrossProfit(sale) − dailyFixedCost

avgProfitPerUnit        = Σ grossProfit / Σ qty
breakEvenUnits          = ceil(dailyFixedCost / avgProfitPerUnit)

contribution(product)   = Σ grossProfit(product) / Σ grossProfit(semua)
```

**Kasus tepi yang wajib ditangani:**
- `avgProfitPerUnit` nol (belum ada penjualan) atau negatif (semua menu
  rugi): `breakEvenUnits` tidak boleh menghasilkan tak hingga atau angka
  negatif. Kembalikan status yang jelas agar UI bisa menjelaskannya.
- `sell_price` nol: `margin` tidak boleh membagi dengan nol.
- Biaya operasional belum diisi: laba bersih ditandai sebagai estimasi.

**Klasifikasi menu**, dievaluasi berurutan:
1. `margin < 0` → menguras tanpa hasil
2. `contribution ≥ rata-rata kontribusi` → penyumbang laba utama
3. `qty ≥ median qty` dan `margin < rata-rata margin` → laku tapi tipis
4. selain itu → menguras tanpa hasil

Kurang dari 7 hari data → status data belum cukup.

---

## 5. Struktur folder

```
lib/
├── main.dart                    # database, Supabase opsional, pengingat, lisensi font
├── app/
│   ├── router.dart
│   ├── shell.dart               # tab bar + tombol catat di atas isi tab
│   └── theme/
│       ├── tokens.dart          # nilai mentah: warna, spasi, radius, ukuran
│       ├── app_colors.dart      # ThemeExtension warna semantik
│       └── app_theme.dart       # ThemeData terang & gelap
├── core/
│   ├── config.dart              # baca dart-define
│   ├── ids.dart                 # newId(), nowMillis()
│   └── setting_keys.dart        # kunci tabel app_settings
├── domain/                      # Dart murni, dilarang import flutter
│   ├── models.dart
│   ├── hpp.dart
│   ├── profit.dart
│   ├── breakeven.dart
│   ├── classify.dart
│   ├── weekly_pattern.dart
│   ├── monthly_report.dart
│   ├── ai_summary.dart          # angka yang dikirim ke AI
│   └── ai_result.dart           # penjaga bentuk balasan AI
├── data/
│   ├── database.dart            # tabel drift
│   ├── providers.dart           # semua provider Riverpod lapisan data
│   ├── seed.dart                # data contoh 30 hari
│   └── repositories/            # business, menu, sales, cost, analysis, settings, backup
├── features/
│   ├── beranda/
│   ├── menu/                    # daftar, form, caption promo
│   ├── catat/                   # controller draf + modal catat
│   ├── analisis/                # kelompok menu, pola mingguan, simulasi, konsultan AI
│   ├── profil/                  # usaha, biaya, laporan PDF, akun, pengaturan
│   └── onboarding/
└── shared/
    ├── widgets/                 # pill_tab_bar, action_pill, stat_tile, section_card, dll
    ├── dates.dart               # today(), dateKey(), periodKey()
    └── format.dart              # formatRupiah, formatTanggal, parseRupiah
test/
├── domain/                      # hpp, profit, breakeven, classify, weekly_pattern, ai_result
├── shared/
└── widget_test.dart             # database memori
android/
├── app/build.gradle.kts         # desugaring, multiDex, kunci rilis
└── app/src/main/AndroidManifest.xml
assets/
├── fonts/
└── icon/
supabase/
├── functions/analyze/           # edge function, tetap TypeScript
└── migrations/                  # tabel backups + RLS
```

**Aturan:**
- `lib/domain/` tidak boleh mengimpor `package:flutter`.
- Widget tidak memanggil database langsung. Selalu lewat repository dan
  provider Riverpod.
- Satu fitur, satu folder di `features/`.

---

## 6. Integrasi AI

```
Aplikasi → ringkasan angka dari domain
  → POST ke Supabase Edge Function /analyze
    → Edge Function menambah kunci API, memanggil Gemini
      → JSON skema tetap
        → Aplikasi merender 3 kartu, menyimpan ke ai_analyses
```

**Kunci API tidak pernah masuk ke aplikasi.** APK bisa dibongkar.

**Skema balikan:**
```json
{
  "headline": "maks 80 karakter",
  "recommendations": [
    {
      "problem": "maks 120 karakter",
      "action": "maks 200 karakter, konkret",
      "impact": "maks 100 karakter",
      "priority": "tinggi | sedang | rendah"
    }
  ]
}
```

Tepat tiga rekomendasi. Parsing defensif dengan try-catch. Timeout 15
detik lalu tombol coba lagi. Hasil selalu disimpan lokal. Sediakan mode
demo yang memakai respons tersimpan.

**Aturan prompt:** model dilarang menghitung, dilarang menyebut angka yang
tidak ada di payload, bahasa sehari-hari, setiap tindakan harus bisa
dikerjakan minggu ini.

---

## 7. Sistem desain

> Direvisi 22 Sep 2026 setelah meninjau referensi DocSpot: tab aktif
> berlabel, kotak statistik, pil aksi di layar level 2, token `primary`
> berganti nama menjadi `accent`, serta pemetaan ke `ColorScheme` dan
> `TextTheme`.

### Arah

Simpel, tapi tidak terlihat murah. Keindahan datang dari tipografi, ruang
kosong, dan menahan diri memakai warna, bukan dari dekorasi.

- **Angka adalah subjek utama layar.** Besar, rapat, tabular. Tiap layar
  punya satu angka atau satu aksi yang dominan.
- **Aksi berwarna tinta**, bukan berwarna-warni. Hijau, amber, dan merah
  disimpan khusus untuk makna finansial, sehingga tiap kali warna muncul,
  artinya langsung terbaca.
- **Netral hangat ke arah kertas**, bukan abu-abu dingin. Aplikasi ini
  menggantikan buku catatan warung.
- **Satu bidang tinta di bagian bawah layar.** Di layar tab itu tombol
  catat, di layar level 2 itu pil aksi, di modal catat itu tombol Simpan.
  Tidak pernah dua sekaligus.

### Referensi

Referensi visual: DocSpot (`referensi/docspot.png`), konsep aplikasi
kesehatan untuk iOS. Yang diambil adalah bahasa kartunya, bukan isi atau
kepadatannya.

| Diambil | Dipakai di |
|---|---|
| Aksi utama berupa pil tinta pekat | Pil aksi di layar level 2 |
| Kartu putih radius besar di atas latar terang | Semua kartu (`surface` di atas `background`) |
| Kotak statistik: satu angka, satu label | Detail menu: modal per porsi, laba per porsi, margin |
| Tab aktif berupa kapsul berlabel | Tab bar |

| Tidak diambil | Alasan |
|---|---|
| Hijau-teal dan kuning sebagai hiasan | Hijau berarti untung, amber berarti laku tapi tipis |
| Gradien | Keindahan dari tipografi dan ruang, bukan dekorasi |
| Ikon berwarna atau 3D | Ikon selalu garis Lucide satu warna |
| Search bar dan grid kategori | Menambah elemen di jalur utama, dicoret di `DESAIN-catat.md` |
| Tab bar berwarna tinta | Bersaing dengan tombol catat |
| Latar abu-abu dingin | Arah kita netral hangat |
| Banyak blok berbobot setara | Beranda didominasi satu angka: laba bersih hari ini |

### Warna

| Token | Terang | Gelap | Dipakai untuk |
|---|---|---|---|
| `ink` | `#1C1A17` | `#F5F1EA` | Aksi utama, tombol, navigasi aktif |
| `onInk` | `#FAF8F5` | `#191714` | Teks/ikon di atas `ink` |
| `background` | `#FAF8F5` | `#191714` | Latar layar dan sheet |
| `surface` | `#FFFFFF` | `#23201C` | Kartu, tab bar |
| `border` | `#E8E3DC` | `#37322C` | Garis pemisah, latar kapsul tab aktif |
| `text` | `#1C1A17` | `#F5F1EA` | Teks utama |
| `textMuted` | `#6B655C` | `#A39C92` | Teks pendukung, ikon tab tidak aktif |
| `success` | `#157F48` | `#2FA968` | Untung, penyumbang laba utama |
| `warning` | `#C2740A` | `#E0952C` | Laku tapi tipis |
| `danger` | `#C0392F` | `#E0645A` | Rugi, menguras tanpa hasil, pesan error |
| `accent` | `#3A48A8` | `#6C78D8` | Tautan teks saja |

Warna status punya pasangan `onSuccess`, `onWarning`, `onDanger` untuk
teks di atasnya. Amber selalu memakai teks gelap di kedua mode. Warna lain
memakai teks terang di mode terang dan teks gelap di mode gelap.

**Aturan pakai:**
- `success` dan `warning` hanya untuk makna finansial. Konfirmasi seperti
  "Tersimpan" tetap netral, tidak hijau.
- `danger` juga dipakai untuk pesan error (validasi, gagal jaringan),
  karena maknanya sejalan: ada yang salah.
- `accent` (dulu bernama `primary`) tidak pernah untuk tombol, bidang
  besar, atau hiasan.
- Tidak ada gradien.

**Implementasi:** warna semantik dibuat sebagai `ThemeExtension<AppColors>`
dengan instance terang dan gelap. Widget mengambilnya lewat
`Theme.of(context).extension<AppColors>()!`. Tidak boleh ada `Color(0x...)`
literal di widget.

Widget bawaan Material membaca `ColorScheme`, jadi `ColorScheme` dibuat
manual dari token, **bukan** `ColorScheme.fromSeed`, supaya tidak ada
warna turunan yang tidak kita pilih.

| Peran `ColorScheme` | Token | Dipakai widget bawaan untuk |
|---|---|---|
| `primary` / `onPrimary` | `ink` / `onInk` | Tombol terisi, fokus input, switch, slider, progress |
| `secondary` / `onSecondary` | `ink` / `onInk` | Wajib diisi; disamakan agar tidak ada warna liar |
| `secondaryContainer` / `onSecondaryContainer` | `border` / `text` | Trek slider dan progress, segmen terpilih |
| `surface` / `onSurface` | `surface` / `text` | Kartu, dialog, teks umum |
| `surfaceContainerHighest` | `border` | Trek switch mati, trek slider dan progress gaya lama |
| `onSurfaceVariant` | `textMuted` | Hint input, subjudul ListTile |
| `outline` | `textMuted` | Garis input, jempol switch mati |
| `outlineVariant` | `border` | Divider |
| `error` / `onError` | `danger` / `onDanger` | Pesan dan garis error input |
| `inverseSurface` / `onInverseSurface` | `ink` / `onInk` | SnackBar |
| `surfaceTint` | transparan | Mencegah lapisan tint M3 saat permukaan terangkat |

`scaffoldBackgroundColor`, latar AppBar, dan latar bottom sheet diisi
`background`. `accent`, `success`, dan `warning` tidak dipetakan ke
`ColorScheme`; ketiganya hanya diambil lewat `AppColors`.

Mode gelap mengikuti sistem: `themeMode: ThemeMode.system`.

### Tipografi

Font: **Plus Jakarta Sans**, dimuat dari `assets/fonts/`. Berat yang
dipakai hanya 400 dan 600, jadi cukup dua file font.

| Gaya | Ukuran | Berat | Catatan |
|---|---|---|---|
| Angka besar | 46 | 600 | letter-spacing −1.6, tabular |
| Judul | 24 | 600 | |
| Subjudul | 18 | 600 | juga angka di kotak statistik |
| Isi | 16 | 400 | |
| Tombol | 16 | 600 | |
| Keterangan | 14 | 400 | |
| Label kecil | 12 | 400 | warna `textMuted` |
| Label tab | 12 | 600 | warna `ink` |

**Semua angka wajib memakai `FontFeature.tabularFigures()`.** Tanpa itu
digit punya lebar berbeda, dan total yang berubah tiap tap akan terlihat
bergoyang.

`TextTheme` bawaan dipetakan ke gaya di atas: `headlineSmall` ← Judul,
`titleLarge` ← Subjudul, `bodyLarge` ← Isi, `labelLarge` ← Tombol,
`bodyMedium` ← Keterangan, `bodySmall` ← Label kecil. Dengan begitu judul
AppBar, teks input, dan tombol bawaan otomatis memakai gaya kita.

### Bentuk dan ruang

```
Spasi       4, 8, 12, 16, 22, 24, 32, 48
Radius      kartu 20, sheet 26, tombol dan pil penuh
Sentuhan    minimal 44 × 44
```

### Komponen

**Kotak statistik.** Kartu `surface` radius 20, padding 12, berisi satu
angka (gaya Subjudul, tabular) dan satu label (gaya Label kecil) di
bawahnya. Maksimal tiga per baris dengan jarak 8. Kalau angka tidak muat,
angkanya mengecil, tidak dipotong. Warna angka `text`; warna status hanya
kalau bermakna finansial, misalnya margin negatif memakai `danger`.

**Pil aksi.** Aksi utama di layar level 2. Pil penuh warna `ink`, tinggi
56, menempati posisi tab bar: inset 22 dari kiri, kanan, dan bawah plus
safe area. Teks gaya Tombol warna `onInk`. Satu layar, satu pil aksi.

### Navigasi

- **Tab bar pil melayang:** inset 22 dari kiri, kanan, dan bawah plus safe
  area. Bentuk stadium, latar `surface`, border tipis.
- **Tab aktif:** kapsul berlatar `border` berisi ikon dan label, keduanya
  `ink`. **Tab tidak aktif:** ikon saja, `textMuted`, tanpa latar.
  Perubahan lebar kapsul dianimasikan singkat, sekitar 200 ms. Label:
  Beranda, Menu, Analisis, Profil.
- **Tombol tengah:** lingkaran 46 warna `ink`, mengambang **di atas** pil
  dengan jarak, tidak menempel.
- **Layar level 2** (`/menu/:id`, `/analisis/ai`, `/profil/biaya`,
  `/profil/pengaturan`) tampil menutupi tab bar, dan aksi utamanya (kalau
  ada) memakai pil aksi. Di go_router, rute ini memakai navigator root
  lewat `parentNavigatorKey`.
- **AppBar:** latar sama dengan `background`, tanpa bayangan, tanpa garis
  pemisah, tidak berubah warna saat konten di-scroll.
- **Modal catat penjualan:** naik dari bawah, sudut atas membulat 26, latar
  sheet `background` supaya kartu menu terlihat terangkat, latar belakang
  meredup, header kustom dengan ikon X di kiri.

### Format

- Rupiah selalu lewat `formatRupiah()`: `Rp 15.000`
- Ringkasan besar disingkat: `Rp 1,2 jt`
- Tanggal bahasa Indonesia: `Rabu, 16 Sep`

---

## 8. Konvensi kode

- File `snake_case.dart`, kelas `PascalCase`, variabel `camelCase`
- Identifier bahasa Inggris, teks untuk pengguna bahasa Indonesia
- UI memakai bahasa awam: "modal per porsi", "balik modal"
- Lint dari `flutter_lints` plus mode ketat di `analysis_options.yaml`
- Setiap fungsi domain wajib punya unit test
- Pesan commit: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`

---

## 9. Lingkungan

- Windows, PowerShell, Flutter 3.47.5
- Cache di E:: `PUB_CACHE` = `E:\dev-cache\pub`, `GRADLE_USER_HOME` =
  `E:\Android\.gradle`. **Tidak ada yang boleh ditulis ke C:.**
- `env.json` masuk `.gitignore`. Kunci Gemini hanya di environment Edge
  Function.
