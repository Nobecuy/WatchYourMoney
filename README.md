# watchh - Watch Your Money

App keuangan pribadi buat nge-track pemasukan dan pengeluaran harian. Dibangun pakai Flutter dengan tema gelap Onyx Neumorphism, semua data tersimpan lokal di device (Hive) dan bisa sync ke cloud via Supabase kalau login.

## Fitur

**Dashboard**
- Kartu saldo bersih dengan toggle sembunyi/tampilkan
- Ringkasan pemasukan vs pengeluaran dengan ratio bar
- Grafik batang arus kas 7 hari terakhir
- 4 tombol shortcut cepat (Catat Kartu, Catat Tunai, Pemasukan, Tanya AI)
- List 5 transaksi terbaru

**Wallet**
- Carousel kartu debit (indigo) dan dompet tunai (emerald)
- Edit saldo langsung di tiap kartu (buat koreksi selisih dengan uang riil)
- Total saldo gabungan dengan distribusi bar
- Filter riwayat transaksi per dompet (Semua / Kartu / Tunai)

**Riwayat Transaksi**
- Search berdasarkan catatan atau kategori
- Filter tipe (Semua / Pemasukan / Pengeluaran)
- Filter metode bayar (Semua / Cash / Card)
- Swipe untuk hapus dengan konfirmasi

**Statistik**
- Grafik batang dan pie chart
- Filter periode (Minggu / Bulan / Semua)
- Rincian pengeluaran per kategori dengan progress bar
- Summary card pemasukan dan pengeluaran

**AI Assistant (Noir)**
- Engine offline 100% lokal buat ngecek saldo, rekap pengeluaran, dan tips hemat
- Shortcut chips buat akses cepat (Sisa Uang, Pengeluaran, Pemasukan, Bisa Apa)
- Integrasi Ollama (mode developer) buat percakapan natural dengan function calling
- Auto fallback ke engine offline kalau server Ollama gagal atau timeout

**Profil & Settings**
- Ganti bahasa: English atau Bahasa Indonesia
- Ganti mata uang: IDR (Rp), USD ($), EUR, GBP
- Toggle Local AI (Ollama) - khusus akun developer
- Cek pembaruan otomatis dari GitHub Releases
- Halaman Saran & Kritik (kirim via email atau simpan ke Supabase)

**Auth & Storage**
- Mode Tamu: semua data disimpan lokal di Hive, tanpa perlu internet
- Mode Login: sync data ke Supabase, bisa akses dari device lain
- Toggle dark Onyx Neumorphism di semua screen

## Teknologi

- Flutter 3.x + Dart 3.x
- Riverpod buat state management
- Hive buat local database (offline-first)
- Supabase buat auth dan cloud sync
- fl_chart buat grafik
- flutter_animate buat animasi
- Onyx Neumorphism design system (custom)

## Cara Jalanin

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Setup Supabase (Opsional)

Kalau mau pakai cloud sync dan auth, isi URL dan key di `lib/main.dart`. Kalau nggak, mode tamu udah cukup buat dipakai sehari-hari.

## Setup Ollama (Khusus Developer)

1. Install Ollama di PC: https://ollama.ai
2. Pull model: `ollama pull llama3.2:3b`
3. Set host agar bisa diakses dari luar: `OLLAMA_HOST=0.0.0.0:11434 ollama serve`
4. Di app, aktifkan toggle Ollama di Profile dan isi URL server (10.0.2.2:11434 buat emulator, IP LAN buat device fisik)

Email developer yang bisa akses toggle Ollama di-set di `lib/core/auth/developer_config.dart`.

## Struktur Project

```
lib/
  core/
    ai/            - LocalFinancialEngine, NoirAIService, OllamaClient
    auth/          - Developer whitelist config
    i18n/          - AppTranslations (EN/ID)
    settings/      - SettingsData model + Riverpod provider
    theme/         - Onyx Neumorphism design tokens
    updates/       - UpdateHelper (GitHub Releases checker)
    utils/         - CurrencyFormatter (multi-currency)
  data/            - Repository implementations (Hive, Supabase)
  domain/          - Models & repository interfaces
  features/
    ai_assistant/  - AI chat screen
    analytics/     - Statistics screen
    auth/          - Login, register, auth wrapper
    dashboard/     - Home dashboard
    feedback/      - Saran & kritik screen
    profile/       - Profile & settings
    transactions/   - Add/edit transaction modal, history
    wallet/        - Wallet screen, adjust balance
    main_screen.dart
  main.dart
```

## Versi

v1.0.0 - Dark Onyx Edition
