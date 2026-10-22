/// Tips and how-to hints shown on the Dashboard.
/// Each tip is a short, actionable sentence about a feature.
class AppTip {
  final String icon;   // Material icon codepoint label (kept as IconData ref)
  final String text;

  const AppTip({required this.icon, required this.text});
}

class AppTips {
  AppTips._();

  static const List<AppTip> all = [
    AppTip(
      icon: 'wallet',
      text: 'Catat pengeluaran kartu dan tunai secara terpisah lewat tombol di Dashboard.',
    ),
    AppTip(
      icon: 'swap',
      text: 'Geser kiri pada riwayat transaksi untuk menghapusnya dengan cepat.',
    ),
    AppTip(
      icon: 'edit',
      text: 'Tap kartu di Wallet untuk mengedit saldo agar sesuai dengan uang aslimu.',
    ),
    AppTip(
      icon: 'ai',
      text: 'Tanya Noir AI untuk melihat ringkasan keuangan, pengeluaran terbesar, atau tips hemat.',
    ),
    AppTip(
      icon: 'chart',
      text: 'Lihat grafik arus kas 7 hari di bagian bawah Dashboard untuk memantau pola pengeluaranmu.',
    ),
    AppTip(
      icon: 'stats',
      text: 'Buka tab Statistik untuk melihat breakdown pengeluaran per kategori dalam bentuk pie chart.',
    ),
    AppTip(
      icon: 'filter',
      text: 'Di tab Riwayat, filter transaksi berdasarkan jenis (Pemasukan/Pengeluaran) atau metode bayar.',
    ),
    AppTip(
      icon: 'currency',
      text: 'Ganti mata uang tampilan (IDR, USD, EUR, GBP) di menu Profil tanpa menghapus data.',
    ),
    AppTip(
      icon: 'language',
      text: 'Ubah bahasa aplikasi ke English atau Bahasa Indonesia di Profil > Pengaturan.',
    ),
    AppTip(
      icon: 'guest',
      text: 'Mode Guest menyimpan semua data lokal di HP. Login untuk sinkronisasi ke cloud.',
    ),
    AppTip(
      icon: 'balance',
      text: 'Tap ikon mata di kartu saldo untuk menyembunyikan nominal — berguna saat layar terlihat orang lain.',
    ),
    AppTip(
      icon: 'feedback',
      text: 'Punya saran atau nemuin bug? Kirim lewat Profil > Saran & Kritik.',
    ),
  ];
}
