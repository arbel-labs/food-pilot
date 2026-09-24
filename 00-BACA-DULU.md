# Baca dulu — konteks project FoodPilot

> Untuk Claude: file ini menjelaskan siapa aku, apa yang sedang aku bangun,
> dan bagaimana aku ingin dibantu. Baca ini sebelum file lain.

---

## Siapa aku

Abel, mahasiswa Teknik Informatika Universitas Esa Unggul semester 7.
Sedang magang sebagai frontend developer, sehari-hari memakai React,
Next.js, TypeScript, dan Tailwind.

**Baru di Flutter dan Dart.** Kalau ada konsep Flutter yang punya padanan
di React, bandingkan saja, itu membantuku paham lebih cepat.

---

## Konteks mata kuliah

- Pemrograman Mobile (CIE 511), 14 pertemuan
- Dosen **mewajibkan Flutter** dan **Jira** untuk pelaporan progres
- Kriteria penilaian project: UI/UX, kenyamanan pengguna, alur tidak
  berbelit, dan aplikasi tidak loading lama
- Dosen sudah menyetujui ide ini dan bilang bagian AI tidak harus pintar,
  karena yang dinilai adalah aplikasinya

---

## Cara membantuku

Aku mau **belajar**, bukan sekadar menerima hasil jadi.

1. **Satu langkah per giliran.** Jangan lompat ke tiga langkah sekaligus.
2. **Jelaskan kenapa**, bukan cuma apa. Pakai analogi atau bandingkan
   dengan React kalau membantu.
3. **Kode lengkap siap salin**, bukan potongan diff. Selalu sebutkan path
   filenya.
4. **Akhiri tiap langkah dengan cara verifikasi**: perintah apa yang
   dijalankan dan apa yang harus terlihat di HP.
5. **Jujur soal akar masalah.** Kalau ada error, jelaskan penyebab
   sebenarnya, jangan tambal sulam.
6. **Tegur aku** kalau permintaanku bertentangan dengan dokumen ini atau
   keputusan yang sudah diambil.

---

## Posisi sekarang

Project ini dimulai di **repo git baru yang bersih**. Kode **Tahap 0
sampai 9 sudah ditulis sekaligus** atas permintaanku, tapi **belum pernah
dikompilasi**: Claude tidak punya Flutter SDK di lingkungannya, jadi belum
ada satu butir pun yang terbukti. Anggap isi `lib/` sebagai draf lengkap
yang masih harus dibuktikan, bukan hasil jadi.

Langkah berikutnya ada di `SETUP.md`: buat folder `android/`, jalankan
`build_runner`, lalu `flutter analyze` dan `flutter test`. Perbaiki error
yang muncul, baru jalankan di HP dan centang butir `TASK.md` tahap demi
tahap sambil memverifikasi.

Karena kode ditulis di luar urutan belajar yang biasa, tiap file diberi
komentar yang menjelaskan alasan keputusannya, supaya masih bisa dipahami
dan dipertanggungjawabkan saat ditanya dosen.

Riwayat singkat: project ini sempat dibangun dengan React Native sampai
Tahap 1, lalu dipindah ke Flutter karena dosen mewajibkannya. Versi lama
tetap tersimpan di repo lamanya (tag `rn-final`) dan tidak dibawa ke repo
ini. Semua keputusan produk dan desain dari masa itu tetap berlaku, hanya
kodenya yang ditulis ulang.

---

## Lingkungan kerja

| Hal | Nilai |
|---|---|
| Sistem operasi | Windows, PowerShell |
| Flutter | 3.47.5, **jangan di-upgrade** |
| Target | Android saja, diuji di HP fisik |
| Lokasi project | `E:\FoodPilot` |
| Nama paket | `foodpilot` (huruf kecil) |
| Org | `com.arbelvalley` |
| Repo | Repo baru di GitHub `Arbel-valley`, private, terpisah dari repo React Native lama. Nama menyusul di Tahap 0 |
| Branch | `dev` untuk kerja harian, `main` untuk titik aman tiap tahap |

**Drive C: hampir penuh.** Cache yang sudah terbukti ada di E:
`PUB_CACHE` = `E:\dev-cache\pub` dan `GRADLE_USER_HOME` = `E:\Android\.gradle`.
Jangan pernah menyarankan sesuatu yang menulis file besar ke C:. Variabel
yang baru diset hanya terbaca oleh program yang dibuka setelahnya, jadi
VS Code harus ditutup penuh (File → Exit) lalu dibuka lagi. Variabel ini
tidak melindungi folder Android SDK dan Flutter SDK, jadi lokasi keduanya
ikut dicek di Tahap 0.

---

## Pelajaran dari percobaan sebelumnya

1. **Verifikasi di HP, bukan percaya laporan.** Analyzer bersih tidak
   menjamin aplikasi jalan. Beberapa kali kode lolos pemeriksaan tapi
   gagal total saat dibuka di HP.
2. **Commit tiap potongan yang berdiri sendiri**, jangan tunggu satu
   tahap selesai.
3. **Dokumen adalah sumber kebenaran.** Kalau keputusan berubah, ubah
   dokumennya dulu, baru kodenya.
4. **Cache tidak boleh masuk C:.** Sudah pernah membuat drive C: penuh
   total dan merusak instalasi.

---

## Soal desain

Arah desain di `CONTEXT.md` bagian 7 adalah arah saat ini: netral hangat,
aksi warna tinta, angka besar, tab bar pil melayang dengan tab aktif
berlabel, font Plus Jakarta Sans.

Referensi DocSpot (`referensi/docspot.png`) sudah ditinjau, dan bagian 7
sudah direvisi berdasarkan referensi itu, lengkap dengan daftar apa yang
diambil dan apa yang sengaja tidak diambil. **Kalau ada referensi baru
dan arahnya berubah lagi, perbarui `CONTEXT.md` bagian 7 dulu sebelum
menulis kode UI.**

---

## Daftar file

| File | Isi |
|---|---|
| `PRD.md` | Kenapa produk ini ada, fitur, dan lingkupnya |
| `CONTEXT.md` | Arsitektur, skema database, rumus, sistem desain |
| `TASK.md` | Urutan kerja per tahap |
| `DESAIN-catat.md` | Rancangan detail layar catat penjualan dan alasannya |
| `referensi/docspot.png` | Referensi visual untuk revisi sistem desain |
| `SETUP.md` | Langkah dari ZIP sampai jalan di HP, termasuk Supabase dan rilis |
| `README.md` | Ringkasan project dan cara menjalankan |
