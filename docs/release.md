# Rilis Android (Play Store)

## 1. Sekali saja: buat kunci upload

```sh
keytool -genkey -v -keystore ~/brass-tuner-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Simpan file `.jks` dan kata sandinya di tempat aman (password manager +
cadangan offline). Kunci yang hilang tidak bisa dipulihkan; dengan Play App
Signing, Google bisa mereset kunci upload, tetapi prosesnya lama.

Buat `android/key.properties` (sudah di-`.gitignore`, **jangan di-commit**):

```properties
storePassword=<kata sandi keystore>
keyPassword=<kata sandi kunci>
keyAlias=upload
storeFile=C:/Users/<anda>/brass-tuner-upload.jks
```

Tanpa file ini, build release memakai kunci debug (hanya untuk uji lokal;
Play Console akan menolaknya).

## 2. Sebelum rilis

1. Pastikan `applicationId` di `android/app/build.gradle.kts` sudah final
   (saat ini `com.brasstunner.brass_tunner`). **Tidak bisa diganti** setelah
   aplikasi pertama kali diunggah.
2. Naikkan versi di `pubspec.yaml`: `version: 1.0.1+2` (angka setelah `+`
   = versionCode, wajib naik tiap unggahan).
3. Jalankan:

   ```sh
   flutter analyze
   flutter test
   ```

4. Uji di perangkat sungguhan: lihat [device_testing.md](device_testing.md).

## 3. Build

```sh
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab
```

Ukuran (v1.0.0): AAB 49.6 MB (semua ABI + simbol); APK per ABI yang diunduh
pengguna sekitar 15.6 MB (armeabi-v7a) dan 18.1 MB (arm64-v8a).

## 4. Aset toko (dibuat dari kode)

| Aset | File | Perintah |
| --- | --- | --- |
| Ikon aplikasi + adaptive | `assets/brand/*.png` | `flutter test tool/generate_brand_test.dart` lalu `dart run flutter_launcher_icons` |
| Splash | `assets/brand/splash*.png` | `dart run flutter_native_splash:create` |
| Ikon Play 512×512 | `assets/brand/play_icon_512.png` | (ikut generate_brand) |
| Feature graphic 1024×500 | `store/feature_graphic.png` | `flutter test tool/screenshots_test.dart` |
| Screenshot ponsel 1080×1920 | `store/screenshots/*.png` | (ikut screenshots_test) |

Screenshot memakai font Roboto dari SDK Flutter dan Segoe UI Symbol (Windows)
untuk ♭/♯; di ponsel, glyph tersebut berasal dari font fallback sistem.

## 5. Play Console

- Teks listing: [`store/listing.md`](../store/listing.md)
- Kebijakan privasi (wajib karena izin mikrofon): host
  [`store/privacy_policy.md`](../store/privacy_policy.md) di URL publik,
  mis. GitHub Pages.
- Formulir Keamanan Data: [`store/data_safety.md`](../store/data_safety.md)
- Kategori: Musik & Audio. Rating konten: kuesioner IARC → semua "Tidak"
  (tanpa konten pengguna, tanpa iklan, tanpa pembelian).
- Mulai dari jalur **Pengujian internal**, lalu tertutup, lalu produksi.
  Akun developer pribadi baru wajib uji tertutup dengan minimal 12 penguji
  selama 14 hari sebelum bisa rilis produksi.
