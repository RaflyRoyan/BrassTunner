# Formulir Keamanan Data (Play Console)

| Pertanyaan | Jawaban |
| --- | --- |
| Apakah aplikasi mengumpulkan atau membagikan jenis data pengguna yang diwajibkan? | **Tidak** |
| Apakah semua data pengguna dienkripsi saat transit? | Tidak berlaku (tidak ada data yang dikirim) |
| Apakah pengguna dapat meminta penghapusan data? | Data hanya ada di perangkat; dapat dihapus dari layar Riwayat atau dengan mencopot aplikasi |

Alasan "Tidak": menurut definisi Google, data yang diproses hanya di
perangkat dan tidak pernah dikirim keluar perangkat **tidak dihitung**
sebagai "dikumpulkan". Audio mikrofon diproses di memori dan dibuang;
riwayat latihan hanya disimpan di database lokal.

## Izin

| Izin | Alasan (untuk deklarasi bila diminta) |
| --- | --- |
| `RECORD_AUDIO` | Mendeteksi nada alat musik secara real-time; audio tidak disimpan atau dikirim |

Aplikasi tidak meminta izin `INTERNET` di build release (terverifikasi
v1.0.0: hanya `RECORD_AUDIO` + izin internal androidx
`DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`).

Verifikasi sebelum mengisi formulir:

```sh
# Daftar izin di APK release
"$ANDROID_HOME/build-tools/<versi>/aapt" dump permissions \
  build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```
