# Rancangan layar catat penjualan

> Fitur paling menentukan nilai UX. Kalau layar ini berat, tidak akan ada
> data, dan semua fitur lain tidak ada gunanya.

**Target:** mencatat penjualan satu hari dalam kurang dari 10 detik.

---

## Tiga zona, tidak lebih

```
┌───────────────────────────────┐
│ ✕  Catat penjualan            │  ← header
│    Rabu, 16 September         │
├───────────────────────────────┤
│ ┌──────────┐ ┌──────────┐     │
│ │Ayam     3│ │Es teh   5│     │  ← grid kartu menu
│ │Rp 18.000 │ │Rp 5.000  │     │
│ │        ⊖ │ │        ⊖ │     │
│ └──────────┘ └──────────┘     │
│ ┌──────────┐ ┌──────────┐     │
│ │Nasi gor. │ │Tempe     │     │
│ │Rp 20.000 │ │Rp 3.000  │     │
│ └──────────┘ └──────────┘     │
├───────────────────────────────┤
│ 8 porsi terjual               │  ← bar aksi
│ Rp 79.000           [Simpan]  │
└───────────────────────────────┘
```

---

## Keputusan dan alasannya

**Kartu itu sendiri adalah tombolnya.** Bukan kartu berisi tombol tambah.
Target sentuhnya jadi besar, jauh di atas minimum 44. Penggunanya menekan
sambil berdiri, mungkin tangan basah, tidak sedang fokus ke layar.

**Tombol kurang kecil, hanya muncul saat jumlah di atas nol.** Menambah
terjadi puluhan kali, mengurangi jarang. Ukuran tombol mengikuti frekuensi
pemakaian, bukan simetri. Dibuat kecil juga mengurangi salah tekan.

**Tidak ada dialog konfirmasi.** Aksinya bisa dibatalkan dengan mencatat
ulang, jadi konfirmasi cuma menambah satu tap tanpa melindungi apa pun.
Gantinya: snackbar "Tersimpan" dengan tombol urungkan selama 5 detik.

**Tanggal sudah terisi hari ini.** Pilihan tanggal lain ada, tapi tidak
pernah menghalangi jalur utama.

**Total berjalan terus di bawah.** Pengguna bisa mencocokkan dengan uang
di laci sambil mencatat. Ini fungsi verifikasi, bukan dekorasi.

**Angka tabular.** Total berubah tiap tap. Tanpa angka tabular, digitnya
bergeser dan terlihat bergoyang.

---

## Kasus yang harus ditangani

**Menu banyak.** Di atas 12 menu, urutkan berdasarkan frekuensi penjualan
30 hari terakhir. Menu yang sering laku selalu ada di layar pertama.
Jangan tambah kolom pencarian, karena itu menambah elemen di jalur utama.

**Sudah mencatat hari ini.** Isi jumlah dari data yang ada, jangan mulai
dari nol. Tombol berubah jadi "Perbarui", header menampilkan "terakhir
disimpan 14.30". Simpan menimpa baris yang sama.

**Nama menu panjang.** Batasi dua baris dengan elipsis supaya grid tetap
seragam.

**Belum ada menu.** Kondisi kosong dengan satu kalimat dan tombol yang
langsung membuka form tambah menu.

**Jumlah besar.** Tekan lama pada kartu membuka input angka langsung,
untuk yang mau memasukkan 40 porsi tanpa menekan 40 kali.

---

## Detail kecil yang berpengaruh besar

- Getaran halus tiap jumlah bertambah (`HapticFeedback.lightImpact`)
- Badge muncul dengan animasi skala singkat, sekitar 120 ms
- Draf disimpan di state Riverpod, bukan state widget, supaya tidak hilang
  kalau modal tertutup tanpa sengaja. State Riverpod hidup di memori dan
  ikut hilang kalau sistem mematikan aplikasi, jadi supaya draf selamat
  juga saat aplikasi tertutup mendadak, draf ikut ditulis ke penyimpanan
  lokal. Caranya diputuskan di Tahap 4

---

## Yang sengaja tidak ada

Pencarian, filter kategori, metode pembayaran, diskon, catatan per item,
pilihan jam transaksi. Semuanya masuk akal di aplikasi kasir, dan
semuanya merusak target 10 detik.

**Aturan:** sebelum menambah apa pun ke layar ini, hitung berapa tap
tambahan untuk skenario paling umum. Kalau bertambah, jawabannya tidak.
