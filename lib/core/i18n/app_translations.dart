/// Simple in-app translation dictionary.
/// English is the canonical default; Indonesian is the alternative.
///
/// Usage:
///   final t = AppTranslations.of(languageCode);
///   Text(t.dashboard)
class AppTranslations {
  const AppTranslations._({required this.languageCode});

  final String languageCode;

  /// Returns translations for the given [code] ('en' | 'id').
  factory AppTranslations.of(String code) {
    return code == 'id'
        ? const AppTranslations._(languageCode: 'id')
        : const AppTranslations._(languageCode: 'en');
  }

  bool get _id => languageCode == 'id';

  // ── Navigation ───────────────────────────────────────────────────
  String get dashboard     => _id ? 'Dasbor'       : 'Dashboard';
  String get history       => _id ? 'Riwayat'      : 'History';
  String get statistics    => _id ? 'Statistik'    : 'Statistics';
  String get wallet        => _id ? 'Dompet'       : 'Wallet';
  String get profile       => _id ? 'Profil'       : 'Profile';

  // ── Dashboard ────────────────────────────────────────────────────
  String get netWorth      => _id ? 'Saldo Bersih (Net Worth)' : 'Net Worth Balance';
  String get cashFlow7d    => _id ? 'Analitik Arus Kas (7 Hari)' : 'Cash Flow Analytics (7 Days)';
  String get recentTx      => _id ? 'Transaksi Terbaru'        : 'Recent Transactions';
  String get income        => _id ? 'Pemasukan'   : 'Income';
  String get expense       => _id ? 'Pengeluaran' : 'Expense';
  String get noTransactions => _id ? 'Belum ada transaksi' : 'No transactions yet';

  // ── Quick Actions ────────────────────────────────────────────────
  String get recordCard    => _id ? 'Catat Kartu'  : 'Record Card';
  String get recordCash    => _id ? 'Catat Tunai'  : 'Record Cash';
  String get addIncome     => _id ? 'Pemasukan'    : 'Add Income';
  String get askAI         => _id ? 'Tanya AI'     : 'Ask AI';

  // ── Wallet ───────────────────────────────────────────────────────
  String get totalBalance  => _id ? 'Total Saldo Gabungan' : 'Total Combined Balance';
  String get cardBalance   => _id ? 'Saldo Kartu'  : 'Card Balance';
  String get cashBalance   => _id ? 'Saldo Tunai'  : 'Cash Balance';
  String get editBalance   => _id ? 'Edit Saldo'   : 'Edit Balance';
  String get activeWallet  => _id ? 'Dompet Aktif' : 'Active Wallets';
  String get walletHistory => _id ? 'Riwayat Dompet' : 'Wallet History';

  // ── Transactions ─────────────────────────────────────────────────
  String get addTransaction   => _id ? 'Tambah Transaksi'   : 'Add Transaction';
  String get editTransaction  => _id ? 'Edit Transaksi'     : 'Edit Transaction';
  String get deleteTransaction => _id ? 'Hapus Transaksi?'  : 'Delete Transaction?';
  String get confirmDelete    => _id ? 'Tindakan ini tidak bisa dibatalkan.' : 'This action cannot be undone.';
  String get cancel           => _id ? 'Batal'  : 'Cancel';
  String get delete           => _id ? 'Hapus'  : 'Delete';
  String get save             => _id ? 'Simpan' : 'Save';
  String get searchTx         => _id ? 'Cari transaksi...' : 'Search transactions...';
  String get amount           => _id ? 'Jumlah'    : 'Amount';
  String get category         => _id ? 'Kategori'  : 'Category';
  String get note             => _id ? 'Catatan'   : 'Note';
  String get date             => _id ? 'Tanggal'   : 'Date';
  String get paymentMethod    => _id ? 'Metode Pembayaran' : 'Payment Method';

  // ── Profile & Settings ───────────────────────────────────────────
  String get profileTitle     => _id ? 'Profil Akun'          : 'Account Profile';
  String get accountInfo      => _id ? 'Informasi Akun'        : 'Account Information';
  String get preferences      => _id ? 'Pengaturan & Preferensi' : 'Settings & Preferences';
  String get language         => _id ? 'Bahasa'               : 'Language';
  String get currency         => _id ? 'Mata Uang'            : 'Currency';
  String get theme            => _id ? 'Tema Tampilan'        : 'Display Theme';
  String get themeValue       => _id ? 'Dark Onyx Neumorphism (Aktif)' : 'Dark Onyx Neumorphism (Active)';
  String get aiAssistant      => _id ? 'AI Financial Assistant' : 'AI Financial Assistant';
  String get aiSubtitle       => _id ? 'Tanya analisis keuangan & tips hemat' : 'Ask for financial analysis & saving tips';
  String get registeredEmail  => _id ? 'Email Terdaftar'      : 'Registered Email';
  String get joinedSince      => _id ? 'Bergabung Sejak'      : 'Joined Since';
  String get security         => _id ? 'Protokol Keamanan'    : 'Security Protocol';
  String get securityValue    => _id ? 'Enkripsi SSL & Supabase RLS Protected' : 'SSL Encryption & Supabase RLS Protected';
  String get logout           => _id ? 'Keluar dari Akun'     : 'Sign Out';
  String get logoutGuest      => _id ? 'Keluar dari Sesi Tamu' : 'Exit Guest Session';
  String get logoutConfirm    => _id ? 'Keluar Akun?'         : 'Sign Out?';
  String get logoutMessage    => _id ? 'Apakah Anda yakin ingin keluar dari sesi akun ini?' : 'Are you sure you want to sign out?';
  String get connectAccount   => _id ? 'Masuk / Hubungkan Akun' : 'Sign In / Connect Account';
  String get guestMode        => _id ? 'MODE TAMU (LOKAL)'    : 'GUEST MODE (LOCAL)';
  String get cloudActive      => _id ? 'CLOUD VAULT AKTIF'    : 'CLOUD VAULT ACTIVE';
  String get offlineLabel     => _id ? 'Offline'              : 'Offline';
  String get guestUser        => _id ? 'Pengguna Tamu (Offline)' : 'Guest User (Offline)';

  // ── AI Assistant ────────────────────────────────────────────────
  String get aiWelcome => _id
      ? 'Halo! Saya asisten keuanganmu. Tanyakan apa saja tentang pola pengeluaranmu, atau gunakan tombol saran di bawah.'
      : 'Hello! I\'m your financial assistant. Ask me anything about your spending patterns, or use the suggestion buttons below.';
  String get aiInputHint   => _id ? 'Tanyakan pola keuanganmu...' : 'Ask about your finances...';
  String get aiNoLLM       => _id
      ? 'Maaf, integrasi AI LLM belum aktif. Gunakan tombol saran di bawah untuk analisis otomatis.'
      : 'Sorry, LLM integration is not active yet. Use the suggestion buttons below for automatic analysis.';
  String get analyzeSpend  => _id ? '✦ Analisis Pengeluaran'    : '✦ Analyze Spending';
  String get paymentRatio  => _id ? '✦ Rasio Kartu vs Tunai'    : '✦ Card vs Cash Ratio';

  // ── Statistics ───────────────────────────────────────────────────
  String get weekLabel  => _id ? 'Minggu' : 'Week';
  String get monthLabel => _id ? 'Bulan'  : 'Month';
  String get allLabel   => _id ? 'Semua'  : 'All';
}
