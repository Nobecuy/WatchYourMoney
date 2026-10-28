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
  String get dashboard => _id ? 'Dasbor' : 'Dashboard';
  String get history => _id ? 'Riwayat' : 'History';
  String get statistics => _id ? 'Statistik' : 'Statistics';
  String get wallet => _id ? 'Dompet' : 'Wallet';
  String get profile => _id ? 'Profil' : 'Profile';
  String get goals => _id ? 'Target' : 'Goals';

  // ── Goals ────────────────────────────────────────────────────────
  String get goalsTitle => _id ? 'Target Keuangan' : 'Financial Goals';
  String get createGoal => _id ? 'Buat Target' : 'Create Goal';
  String get editGoal => _id ? 'Edit Target' : 'Edit Goal';
  String get goalTitle => _id ? 'Nama Target' : 'Goal Name';
  String get goalTargetAmount => _id ? 'Target Nominal' : 'Target Amount';
  String get goalCategory => _id ? 'Kategori' : 'Category';
  String get goalTargetDate => _id ? 'Tanggal Target' : 'Target Date';
  String get goalInitialAmount => _id ? 'Nominal Awal' : 'Initial Amount';
  String get goalCurrentAmount => _id ? 'Terkumpul' : 'Saved Amount';
  String get goalProgress => _id ? 'Progres' : 'Progress';
  String get goalRemaining => _id ? 'Sisa' : 'Remaining';
  String get goalDaysRemaining => _id ? 'Hari tersisa' : 'Days remaining';
  String get addSavings => _id ? 'Tambah Tabungan' : 'Add Savings';
  String get savingsAmount => _id ? 'Jumlah Tabungan' : 'Savings Amount';
  String get goalCompleted => _id ? 'Target Tercapai!' : 'Goal Completed!';
  String get goalOverdue => _id ? 'Target Terlewat' : 'Goal Overdue';
  String get noGoals => _id ? 'Belum ada target' : 'No goals yet';
  String get noActiveGoals => _id ? 'Belum ada target aktif' : 'No active goals';
  String get emptyStateTitle => _id ? 'Berikan arah pada uangmu.' : 'Give your money a direction.';
  String get emptyStateSubtitle =>
      _id ? 'Buat target keuangan pertama untuk mulai menabung.' : 'Create your first financial goal to start saving.';
  String get createFirstGoal => _id ? 'Buat Target Pertama' : 'Create First Goal';
  String get activeGoals => _id ? 'Target Aktif' : 'Active Goals';
  String get completedGoals => _id ? 'Target Selesai' : 'Completed Goals';
  String get totalSaved => _id ? 'Total Terkumpul' : 'Total Saved';
  String get goalDetail => _id ? 'Detail Target' : 'Goal Detail';
  String get goalHistory => _id ? 'Riwayat Kontribusi' : 'Contribution History';
  String get completeGoal => _id ? 'Selesaikan' : 'Complete';
  String get archiveGoal => _id ? 'Arsipkan' : 'Archive';
  String get deleteGoal => _id ? 'Hapus Target' : 'Delete Goal';
  String get confirmDeleteGoal =>
      _id ? 'Target ini akan dihapus permanen.' : 'This goal will be permanently deleted.';
  String get goalSaved => _id ? 'Target berhasil disimpan' : 'Goal saved successfully';
  String get goalUpdated => _id ? 'Target berhasil diperbarui' : 'Goal updated successfully';
  String get goalDeleted => _id ? 'Target berhasil dihapus' : 'Goal deleted successfully';
  String get savingsAdded => _id ? 'Tabungan ditambahkan' : 'Savings added';
  String get enterValidTargetAmount =>
      _id ? 'Masukkan nominal target yang valid' : 'Enter a valid target amount';
  String get enterValidSavingsAmount =>
      _id ? 'Masukkan nominal tabungan yang valid' : 'Enter a valid savings amount';
  String get targetDateRequired =>
      _id ? 'Tanggal target wajib diisi' : 'Target date is required';

  // ── Dashboard ────────────────────────────────────────────────────
  String get netWorth => _id ? 'Saldo Bersih (Net Worth)' : 'Net Worth Balance';
  String get cashFlow7d =>
      _id ? 'Analitik Arus Kas (7 Hari)' : 'Cash Flow Analytics (7 Days)';
  String get recentTx => _id ? 'Transaksi Terbaru' : 'Recent Transactions';
  String get income => _id ? 'Pemasukan' : 'Income';
  String get expense => _id ? 'Pengeluaran' : 'Expense';
  String get noTransactions =>
      _id ? 'Belum ada transaksi' : 'No transactions yet';

  // ── Quick Actions ────────────────────────────────────────────────
  String get recordCard => _id ? 'Catat Kartu' : 'Record Card';
  String get recordCash => _id ? 'Catat Tunai' : 'Record Cash';
  String get addIncome => _id ? 'Pemasukan' : 'Add Income';
  String get askAI => _id ? 'Tanya AI' : 'Ask AI';

  // ── Wallet ───────────────────────────────────────────────────────
  String get totalBalance =>
      _id ? 'Total Saldo Gabungan' : 'Total Combined Balance';
  String get cardBalance => _id ? 'Saldo Kartu' : 'Card Balance';
  String get cashBalance => _id ? 'Saldo Tunai' : 'Cash Balance';
  String get editBalance => _id ? 'Edit Saldo' : 'Edit Balance';
  String get activeWallet => _id ? 'Dompet Aktif' : 'Active Wallets';
  String get walletHistory => _id ? 'Riwayat Dompet' : 'Wallet History';
  String get debitPlatinum => 'DEBIT PLATINUM';
  String get cardHolderName =>
      _id ? 'DOMPET KARTU UTAMA' : 'PRIMARY CARD WALLET';
  String get cashWalletLabel =>
      _id ? 'DOMPET FISIK (CASH)' : 'PHYSICAL CASH WALLET';
  String get cardBalanceLabel => _id ? 'Saldo Kartu' : 'Card Balance';
  String get cashBalanceLabel => _id ? 'Saldo Uang Tunai' : 'Cash Balance';
  String get cashReady => _id ? 'Siap digunakan langsung' : 'Ready to use';
  String get noWalletTx => _id
      ? 'Belum ada transaksi di dompet ini'
      : 'No transactions in this wallet';
  String get useButtonsAbove => _id
      ? 'Gunakan tombol di atas untuk mencatat pengeluaran atau pemasukan.'
      : 'Use the buttons above to record expenses or income.';
  String get filterCard => _id ? 'Kartu' : 'Card';
  String get filterCash => _id ? 'Tunai' : 'Cash';
  String get casualDailyLabel => _id ? 'KAS FISIK & HARIAN' : 'DAILY CASH';
  String get myWallet => _id ? 'My Wallet' : 'My Wallet';
  String get manageWallet =>
      _id ? 'Kelola saldo kartu & uang tunai' : 'Manage card & cash balance';
  String get securitySync =>
      _id ? 'Keamanan & Sinkronisasi' : 'Security & Sync';
  String get securityAccount =>
      _id ? 'Keamanan & Sinkronisasi' : 'Security & Sync';
  String get encryptionNote => _id
      ? 'Terenkripsi end-to-end dengan Supabase'
      : 'End-to-end encrypted with Supabase';

  // ── Transactions ─────────────────────────────────────────────────
  String get addTransaction => _id ? 'Tambah Transaksi' : 'Add Transaction';
  String get editTransaction => _id ? 'Edit Transaksi' : 'Edit Transaction';
  String get deleteTransaction =>
      _id ? 'Hapus Transaksi?' : 'Delete Transaction?';
  String get confirmDelete => _id
      ? 'Tindakan ini tidak bisa dibatalkan.'
      : 'This action cannot be undone.';
  String get cancel => _id ? 'Batal' : 'Cancel';
  String get delete => _id ? 'Hapus' : 'Delete';
  String get save => _id ? 'Simpan' : 'Save';
  String get searchTx => _id ? 'Cari transaksi...' : 'Search transactions...';
  String get amount => _id ? 'Jumlah' : 'Amount';
  String get category => _id ? 'Kategori' : 'Category';
  String get note => _id ? 'Catatan' : 'Note';
  String get date => _id ? 'Tanggal' : 'Date';
  String get paymentMethod => _id ? 'Metode Pembayaran' : 'Payment Method';
  String get addCategory => _id ? 'Tambah Kategori Baru' : 'Add New Category';
  String get categoryName => _id ? 'Nama Kategori' : 'Category Name';
  String get saveChanges => _id ? 'Simpan Perubahan' : 'Save Changes';
  String get txDeleted =>
      _id ? 'Transaksi telah dihapus' : 'Transaction deleted';
  String get enterValidAmount =>
      _id ? 'Masukkan nominal transaksi yang valid' : 'Enter a valid amount';
  String get txSaved =>
      _id ? 'Transaksi berhasil disimpan' : 'Transaction saved successfully';
  String get txUpdated => _id
      ? 'Transaksi berhasil diperbarui'
      : 'Transaction updated successfully';
  String get paymentMethodLabel => _id ? 'METODE BAYAR' : 'PAYMENT METHOD';
  String get categoryLabel => _id ? 'KATEGORI' : 'CATEGORY';
  String get dateLabel => _id ? 'TANGGAL' : 'DATE';
  String get noteHint =>
      _id ? 'Catatan tambahan (opsional)...' : 'Additional note (optional)...';
  String get addCategoryShort => _id ? '+ Tambah Kategori' : '+ Add Category';

  // ── Profile & Settings ───────────────────────────────────────────
  String get profileTitle => _id ? 'Profil Akun' : 'Account Profile';
  String get accountInfo => _id ? 'Informasi Akun' : 'Account Information';
  String get preferences =>
      _id ? 'Pengaturan & Preferensi' : 'Settings & Preferences';
  String get language => _id ? 'Bahasa' : 'Language';
  String get currency => _id ? 'Mata Uang' : 'Currency';
  String get theme => _id ? 'Tema Tampilan' : 'Display Theme';
  String get themeValue =>
      _id ? 'Dark Onyx Neumorphism (Aktif)' : 'Dark Onyx Neumorphism (Active)';
  String get aiAssistant =>
      _id ? 'AI Financial Assistant' : 'AI Financial Assistant';
  String get aiSubtitle => _id
      ? 'Tanya analisis keuangan & tips hemat'
      : 'Ask for financial analysis & saving tips';
  String get registeredEmail => _id ? 'Email Terdaftar' : 'Registered Email';
  String get joinedSince => _id ? 'Bergabung Sejak' : 'Joined Since';
  String get security => _id ? 'Protokol Keamanan' : 'Security Protocol';
  String get securityValue => _id
      ? 'Enkripsi SSL & Supabase RLS Protected'
      : 'SSL Encryption & Supabase RLS Protected';
  String get logout => _id ? 'Keluar dari Akun' : 'Sign Out';
  String get logoutGuest =>
      _id ? 'Keluar dari Sesi Tamu' : 'Exit Guest Session';
  String get logoutConfirm => _id ? 'Keluar Akun?' : 'Sign Out?';
  String get logoutMessage => _id
      ? 'Apakah Anda yakin ingin keluar dari sesi akun ini?'
      : 'Are you sure you want to sign out?';
  String get connectAccount =>
      _id ? 'Masuk / Hubungkan Akun' : 'Sign In / Connect Account';
  String get connectGoogle => _id
      ? 'Masuk / Hubungkan Akun Google'
      : 'Sign In / Connect Google Account';
  String get guestMode => _id ? 'MODE TAMU (LOKAL)' : 'GUEST MODE (LOCAL)';
  String get cloudActive => _id ? 'CLOUD VAULT AKTIF' : 'CLOUD VAULT ACTIVE';
  String get offlineLabel => _id ? 'Offline' : 'Offline';
  String get guestUser =>
      _id ? 'Pengguna Tamu (Offline)' : 'Guest User (Offline)';
  String get secure => 'SECURE';
  String get notConnectedEmail =>
      _id ? 'Tidak terhubung email' : 'Not connected to email';
  String get ollamaActiveLabel => _id ? 'Aktif' : 'Active';
  String get ollamaInactive => _id
      ? 'Nonaktif - gunakan engine offline'
      : 'Inactive - using offline engine';
  String get checkUpdate => _id ? 'Periksa Pembaruan' : 'Check for Updates';
  String get feedback => _id ? 'Saran & Kritik' : 'Feedback';
  String get feedbackSubtitle =>
      _id ? 'Bantu kami tingkatkan aplikasi' : 'Help us improve the app';
  String get appVersionLabel => 'watchh v1.0.0 - Dark Onyx Edition';

  // ── Update Dialog ───────────────────────────────────────────────
  String get updateAvailable => _id ? 'Update Telah Tersedia' : 'Update Available';
  String get newVersion => _id ? 'Versi baru' : 'New Version';
  String get releaseNotes => _id ? 'Catatan Rilis' : 'Release Notes';
  String get downloading => _id ? 'Mengunduh...' : 'Downloading...';
  String get installing => _id ? 'Memasang update...' : 'Installing update...';
  String get downloadFailed => _id ? 'Gagal mengunduh update' : 'Failed to download update';
  String get installFailed => _id ? 'Gagal memasang update' : 'Failed to install update';
  String get later => _id ? 'Nanti' : 'Later';
  String get downloadAndInstall => _id ? 'Unduh & Pasang' : 'Download & Install';
  String get updateInBrowser => _id ? 'Update di Browser' : 'Update in Browser';
  String get retry => _id ? 'Coba Lagi' : 'Retry';
  String get skipVersion => _id ? 'Lewati Versi Ini' : 'Skip This Version';
  String get alreadyLatest => _id ? 'Sudah Terkini' : 'Already Up to Date';
  String get usingLatestVersion =>
      _id ? 'Kamu sudah menggunakan versi terbaru' : 'You are using the latest version';

  // ── Wallet / Adjust Balance ───────────────────────────────────
  String get adjustBalanceCategory => _id ? 'Penyesuaian Saldo' : 'Balance Adjustment';
  String get correctCardBalance => _id ? 'Koreksi saldo riil kartu kredit/debit' : 'Correct actual card balance';
  String get correctCashBalance => _id ? 'Koreksi saldo riil kas tunai' : 'Correct actual cash balance';
  String get adjustmentNoteHint => _id ? 'Keterangan penyesuaian...' : 'Adjustment note...';
  String get incomeAdjustment => _id ? 'Pemasukan penyesuaian' : 'Income adjustment';
  String get expenseAdjustment => _id ? 'Pengeluaran penyesuaian' : 'Expense adjustment';
  String get balanceUpdated => _id ? 'Saldo berhasil diubah' : 'Balance updated successfully';
  String get balanceSameAsCurrent =>
      _id ? 'Nominal saldo baru sama dengan saldo saat ini.' : 'New balance is the same as current balance.';
  String get balanceUpdatedCard =>
      _id ? 'Saldo Kartu / Kredit berhasil diubah ke' : 'Card / Credit balance updated to';
  String get balanceUpdatedCash =>
      _id ? 'Saldo Tunai berhasil diubah ke' : 'Cash balance updated to';
  String get failedToUpdateBalance =>
      _id ? 'Gagal memperbarui saldo' : 'Failed to update balance';

  // ── Dashboard extras ──────────────────────────────────────────────
  String get editSaldo => _id ? 'Edit Saldo' : 'Edit Balance';
  String get pickWallet => _id
      ? 'Pilih dompet yang ingin disesuaikan'
      : 'Choose which wallet to adjust';
  String get currentBalance => _id ? 'Saldo saat ini' : 'Current balance';
  String get cardCredit => _id ? 'Kartu / Kredit' : 'Card / Credit';
  String get cashWalletName => _id ? 'Uang Tunai' : 'Cash Wallet';
  String get cashFlowSubtitle =>
      _id ? 'Arus kas 7 hari terakhir' : 'Last 7 days cash flow';

  // ── Statistics ───────────────────────────────────────────────────
  String get weekLabel => _id ? 'Minggu' : 'Week';
  String get monthLabel => _id ? 'Bulan' : 'Month';
  String get allLabel => _id ? 'Semua' : 'All';
  String get spendingDetail =>
      _id ? 'RINCIAN PENGELUARAN' : 'SPENDING BREAKDOWN';
  String get categoriesCount => _id ? 'Kategori' : 'Categories';
  String get noSpendingData =>
      _id ? 'Belum ada data pengeluaran' : 'No spending data yet';
  String get spendingByCat => _id
      ? 'Proporsi Pengeluaran per Kategori'
      : 'Spending Proportion by Category';
  String get cashFlowChart => _id ? 'Arus Kas' : 'Cash Flow';
  String get analyticsTitle =>
      _id ? 'Analitik Keuangan' : 'Financial Analytics';
  String get analyticsSubtitle =>
      _id ? 'Pantau arus kas kamu' : 'Monitor your cash flow';
  String get chartStats => _id ? 'GRAFIK STATISTIK' : 'CHART STATISTICS';
  String get weekShort => _id ? 'Mgg' : 'Wk';

  // ── History ──────────────────────────────────────────────────────
  String get transactionsTitle => _id ? 'Transaksi' : 'Transactions';
  String get noTxFound => _id ? 'Tidak ada transaksi' : 'No transactions found';

  // ── Toggle ────────────────────────────────────────────────────────
  String get hide => _id ? 'Sembunyikan' : 'Hide';
  String get show => _id ? 'Tampilkan' : 'Show';
}
