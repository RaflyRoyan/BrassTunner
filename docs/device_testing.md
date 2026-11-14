# Uji di perangkat (target: HP low-end)

Target minimum: Android 7.0+ (minSdk 24), CPU 4× Cortex-A53, RAM 2–3 GB
(contoh: Samsung Galaxy A03, Redmi 9A/10A).

## 0. Patokan dari host

```sh
dart compile exe tool/benchmark_dsp.dart -o build/bench.exe && build/bench.exe
```

Hasil di laptop pengembang (AOT, 13 Nov 2026): ~0.37 ms per update DSP
(1.6% dari jatah hop 23.2 ms). Cortex-A53 kira-kira 5–10× lebih lambat,
jadi perkiraan 2–4 ms per update (≤ 17% jatah). Angka ini **perkiraan**;
konfirmasi dengan langkah di bawah.

## 1. Latensi

Update tuner datang tiap hop 1024 sampel (23.2 ms @ 44.1 kHz), target < 50 ms.

1. `flutter run --profile` di HP.
2. DevTools → Performance: rekam 30 detik sambil memainkan nada.
   - Frame UI dan raster < 16 ms (tanpa jank merah).
3. DevTools → CPU Profiler, pilih isolate DSP (`PitchWorker`):
   - `PitchTracker.process` median < 10 ms.
4. Uji subjektif: mainkan nada terputus-putus (staccato); nama nada harus
   muncul tanpa jeda terasa. Rekam layar + audio 60 fps, hitung frame dari
   awal bunyi sampai nada tampil (≤ 6 frame ≈ 100 ms termasuk window
   4096 sampel).

## 2. CPU

```sh
adb shell top -d 2 -o PID,%CPU,RES,ARGS | grep brass
```

- Tuner aktif: target < 25% satu inti rata-rata.
- Tab Drone/Metronom (mic mati): tidak ada beban DSP.
- App di latar belakang: CPU ~0% (mic & suara berhenti saat app disembunyikan).

## 3. Baterai

1. Isi penuh, kecerahan 50%, mode pesawat.
2. `adb shell dumpsys batterystats --reset`
3. Jalankan tuner 30 menit sambil bermain (layar tetap menyala otomatis).
4. `adb shell dumpsys batterystats > stats.txt` atau unggah bugreport ke
   Battery Historian.
- Target: ≤ 8% baterai per 30 menit di HP 5000 mAh (sebagian besar dari
  layar).

## 4. Fungsional

- [ ] Izin mikrofon: tolak → layar penjelasan + "Coba lagi"; izinkan → jalan.
- [ ] Tuba B♭1 (58 Hz) dan pedal tone terbaca tanpa salah oktaf.
- [ ] Trumpet C6 tertulis (≈ 932 Hz) terbaca.
- [ ] Layar tidak mati selama tuner mendengar; mati normal di tab Drone.
- [ ] Drone + tuner bersamaan memakai earphone.
- [ ] Ganti tema terang/gelap/sistem; tersimpan setelah restart.
- [ ] Sesi muncul di Riwayat setelah ≥ 10 detik bermain lalu pindah tab.
- [ ] Rotasi layar & layar kecil (5"): tidak ada overflow.
- [ ] Splash & ikon adaptif tampil benar (Android 12+ dan < 12).

Catat hasil (model HP, Android, angka) di bawah sebelum rilis.

| Tanggal | HP | Android | DSP median | CPU tuner | Baterai/30 mnt | Catatan |
| --- | --- | --- | --- | --- | --- | --- |
| | | | | | | |
