# PRD — FoodPilot

> Dokumen ini menjawab **kenapa** produk ini ada dan **apa** yang harus dibuat.
> Keputusan teknis ada di `CONTEXT.md`, urutan kerja di `TASK.md`.

---

## 1. Ringkasan

Aplikasi mobile pencatatan dan analisis keuangan sederhana untuk pelaku
UMKM, dengan lapisan konsultan AI di atasnya. Pengguna mencatat penjualan
harian dalam hitungan detik, aplikasi menghitung menu mana yang benar-benar
menguntungkan, lalu AI memberi tiga rekomendasi konkret dari angka itu.

Project akhir mata kuliah Pemrograman Mobile, dibangun dengan Flutter.

---

## 2. Masalah

Mayoritas pelaku UMKM tidak bisa menjawab pertanyaan paling dasar tentang
usahanya sendiri: menu mana yang paling menguntungkan. Bukan karena tidak
peduli, tapi karena tidak ada datanya.

1. Tidak ada pencatatan. Uang usaha dan pribadi bercampur di satu laci.
2. HPP tidak pernah dihitung. Harga jual ditentukan dari harga tetangga.
3. Aplikasi kasir yang ada terlalu berat untuk pemilik warung yang sambil
   memasak.

**Insight utama:** masalahnya bukan kurangnya kecerdasan analisis, tapi
kurangnya data mentah. Prioritas nomor satu adalah membuat input semudah
mungkin, bukan membuat analisis secanggih mungkin.

---

## 3. Persona

**Bu Sri, 42 tahun, pemilik warung makan.** Buka 10 jam sehari, hampir
semuanya dikerjakan sendiri. HP Android kelas menengah bawah, kuota
terbatas. Pernah mencoba aplikasi kasir, berhenti karena ribet. Tidak
paham istilah akuntansi.

Kuliner adalah persona utama, tapi aplikasi mendukung tiga jenis usaha:
kuliner, fashion, dan jasa.

**Implikasi desain:**
- Input bisa diselesaikan satu tangan sambil berdiri
- Bahasa sehari-hari: "modal per porsi", bukan "HPP"
- Berfungsi penuh tanpa internet
- Tidak ada layar yang butuh membaca panduan dulu

---

## 4. Tujuan dan kriteria nilai

| Kriteria dosen | Cara memenuhinya |
|---|---|
| UI/UX | Sistem desain konsisten, satu aksi utama per layar |
| Kenyamanan pengguna | Alur harian selesai dalam 3 tap |
| Alur tidak berbelit | Kedalaman navigasi maksimal 2 level |
| Tidak loading lama | Offline-first, perhitungan lokal, AI opsional |

---

## 5. Lingkup

**Masuk:** pencatatan menu dan HPP otomatis, penjualan harian, biaya
operasional, laba bersih dan titik impas, klasifikasi menu, pola mingguan,
rekomendasi AI, riwayat analisis.

**Tidak masuk** (tulis di batasan masalah laporan):
- Prediksi tren pasar jangka panjang, tidak bisa dipertanggungjawabkan
- Manajemen stok real-time
- Multi-cabang, multi-pengguna, peran kasir
- Integrasi ojek online dan pembayaran
- Rekomendasi lokasi usaha

---

## 6. Fitur

### Wajib (Must)

**F-01 Onboarding** — tiga langkah: sambutan, data usaha, menu pertama.
Bisa dilewati. Biaya operasional tidak ditanya di sini, ditawarkan lewat
banner setelah tiga hari data.

**F-02 Menu dan HPP** — tambah, ubah, nonaktifkan menu. Tiap menu punya
daftar bahan. HPP, margin, dan laba per porsi muncul langsung saat
mengetik, tanpa tombol hitung. Menu bermargin negatif ditandai merah.

**F-03 Catat penjualan** — fitur paling kritis. Grid kartu menu, tap untuk
menambah porsi, total berjalan di bawah, satu tombol simpan. Target di
bawah 10 detik. Detail di `DESAIN-catat.md`.

**F-04 Biaya operasional** — diisi sekali sebulan, bisa disalin dari bulan
lalu. Dibagi ke biaya harian berdasarkan hari operasional.

**F-05 Beranda** — satu layar tanpa scroll: laba bersih hari ini sebagai
angka utama, progress menuju balik modal, tiga menu terlaris.

**F-06 Analisis menu** — tiga kelompok berbahasa awam: penyumbang laba
utama (hijau), laku tapi tipis (amber), menguras tanpa hasil (merah).
Setiap item bisa dibuka untuk melihat rumusnya. Butuh minimal 7 hari data.

**F-07 Pola mingguan** — grafik batang 7 hari dan satu kalimat kesimpulan
otomatis dari aturan sederhana, bukan AI.

**F-08 Konsultan AI** — kirim ringkasan angka, terima tiga rekomendasi
berformat tetap (masalah, tindakan, dampak), tampil sebagai kartu, bukan
gelembung chat. Kunci API tidak pernah di dalam aplikasi.

**F-09 Riwayat analisis** — tersimpan lokal, dibuka ulang tanpa internet.

### Sebaiknya ada (Should)

**F-10 Simulasi geser** — slider harga dan biaya, angka laba berubah
seketika. Paling berkesan saat demo karena nol loading.

**F-11 Pengingat harian** — notifikasi lokal tiap sore.

**F-14 Login dan sinkronisasi** — cadangan data, aplikasi tetap jalan
penuh tanpa login.

### Bisa ada (Could)

**F-12 Export PDF** — laporan bulanan, berguna untuk pengajuan pinjaman.

**F-13 Caption promo** — AI membuat caption untuk menu unggulan.

---

## 7. Data contoh

Sediakan pilihan "Isi dengan data contoh" di onboarding yang mengisi 30
hari data warung fiktif. Dashboard kosong membuat demo terlihat hambar.
**Wajib ada sebelum hari demo.**

---

## 8. Metrik

| Metrik | Target |
|---|---|
| Onboarding sampai menu pertama tersimpan | < 3 menit |
| Mencatat penjualan satu hari | < 10 detik |
| Tap untuk mencatat 5 menu | ≤ 8 |
| Render Beranda dari data lokal | < 1 detik |
| Kedalaman navigasi | ≤ 2 level |

---

## 9. Pemetaan ke materi kuliah

| Materi | Dibuktikan oleh |
|---|---|
| Widget dan layout | Sistem desain, grid kartu menu |
| Navigasi | Shell route 4 tab, rute bersarang, modal catat |
| State management | Provider Riverpod |
| Form dan validasi | Form menu, form biaya |
| REST API | Konsultan AI, penanganan loading dan error |
| Penyimpanan lokal | Database drift, seluruh fitur offline |
| Fitur perangkat | Notifikasi, berbagi PDF |
| Autentikasi | Login Supabase |
| Testing | Unit test lapisan domain |
| Build dan rilis | APK rilis bertanda tangan |

---

## 10. Risiko

| Risiko | Mitigasi |
|---|---|
| Fitur AI memakan waktu | F-01 sampai F-07 sudah aplikasi utuh, AI dikerjakan setelahnya |
| AI mengarang angka | Semua angka dihitung lokal, AI hanya menarasikan |
| Kuota API habis saat demo | Cache hasil, mode demo dengan respons tersimpan |
| Harga bahan berubah merusak data lama | Harga dan HPP disimpan sebagai snapshot di tiap transaksi |
| Kurva belajar Flutter | Urutan tahap dibuat bertahap, tiap tahap diverifikasi di HP |
