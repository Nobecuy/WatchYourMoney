import 'package:watch_your_money/core/ai/system_prompt.dart';

/// Topic gate for restricting AI to finance-only conversations.
/// Uses deterministic keyword-based classification with allow/deny lists.
class TopicGate {
  // Finance-related keywords that indicate valid queries
  static const List<String> _financeKeywords = [
    // Core finance terms
    'saldo', 'balance', 'uang', 'duit', 'penghasilan', 'pemasukan', 'income',
    'pengeluaran', 'expense', 'belanja', 'spending', 'biaya', 'cost',
    'transaksi', 'transaction', 'catat', 'record', 'simpan', 'save',
    'kategori', 'category', 'makan', 'food', 'transport', 'transportasi',
    'belanja', 'shopping', 'tagihan', 'bill', 'hiburan', 'entertainment',
    'kesehatan', 'health', 'edukasi', 'education', 'lainnya', 'other',
    'gaji', 'salary', 'bonus', 'freelance', 'investasi', 'investment',
    'hadiah', 'gift', 'penjualan', 'sale', 'tabungan', 'savings',
    'target', 'goal', 'menabung', 'nabung', 'saving',
    'budget', 'anggaran', 'batas', 'limit', 'analisis', 'analysis',
    'laporan', 'report', 'ringkasan', 'summary', 'ringkasan',
    'kartu', 'card', 'tunai', 'cash', 'dompet', 'wallet', 'rekening',
    'edit', 'ubah', 'hapus', 'delete', 'koreksi', 'koreksi saldo',
    'hutang', 'debt', 'piutang', 'receivable', 'cicilan', 'installment',
    'aset', 'asset', 'liabilitas', 'liability', 'net worth',
    'cashflow', 'arus kas', 'pemasukkan', 'pengeluaran',
    'minggu ini', 'bulan ini', 'tahun ini', 'kemarin', 'yesterday',
    'minggu lalu', 'last week', 'bulan lalu', 'last month',
    'periode', 'period', 'rentang', 'range', 'dari', 'sampai',
    'berapa', 'how much', 'total', 'rata-rata', 'average',
    'terbesar', 'terkecil', 'max', 'min', 'paling', 'most',
    'tren', 'trend', 'pola', 'pattern', 'kebiasaan', 'habit',
    'tips', 'saran', 'advice', 'rekomendasi', 'recommendation',
    'hitung', 'calculate', 'kalkulasi', 'estimation', 'perkiraan',
    'rencana', 'plan', 'strategi', 'strategy',
  ];

  // Non-finance topics to explicitly reject
  static const List<String> _nonFinanceKeywords = [
    'presiden', 'president', 'politik', 'politics', 'pemerintah', 'government',
    'sejarah', 'history', 'geografi', 'geography', 'biologi', 'biology',
    'kimia', 'chemistry', 'fisika', 'physics', 'matematika', 'math',
    'sastra', 'literature', 'bahasa', 'language', 'grammar', 'tatabahasa',
    'coding', 'programming', 'program', 'code', 'script', 'developer',
    'website', 'web', 'aplikasi', 'app development', 'mobile app',
    'html', 'css', 'javascript', 'python', 'java', 'flutter', 'dart',
    'database', 'sql', 'api', 'backend', 'frontend', 'framework',
    'hiburan', 'entertainment', 'film', 'movie', 'musik', 'music',
    'game', 'gaming', 'main', 'play', 'olahraga', 'sport', 'sepak bola',
    'resep', 'recipe', 'masak', 'cook', 'makanan enak', 'delicious',
    'cuaca', 'weather', 'hari ini', 'today weather', 'besok', 'tomorrow',
    'artis', 'celebrity', 'selebriti', 'influencer', 'tiktok', 'instagram',
    'youtube', 'video', 'streaming', 'netflix', 'spotify',
    'belajar', 'study', 'kuliah', 'college', 'sekolah', 'school',
    'tugas', 'homework', 'pr', 'ujian', 'exam', 'test',
    'kesehatan mental', 'mental health', 'depresi', 'depression',
    'dokter', 'doctor', 'rumah sakit', 'hospital', 'obat', 'medicine',
    'hubungan', 'relationship', 'pacar', 'girlfriend', 'boyfriend',
    'menikah', 'marriage', 'keluarga', 'family', 'anak', 'children',
    'agama', 'religion', 'doa', 'prayer', 'ibadah', 'worship',
    'hukum', 'law', 'advokat', 'lawyer', 'pengadilan', 'court',
    'otomotif', 'automotive', 'mobil', 'car', 'motor', 'motorcycle',
    'properti', 'property', 'rumah', 'house', 'tanah', 'land',
    'asuransi', 'insurance', 'premi', 'premium', 'klaim', 'claim',
  ];

  // Phrases that strongly indicate non-finance intent
  static const List<String> _nonFinancePhrases = [
    'siapa', 'who is', 'apa itu', 'what is', 'mengapa', 'why',
    'bagaimana cara', 'how to', 'tutorial', 'cara membuat',
    'bantu aku', 'help me', 'tolong', 'please',
    'cerita', 'story', 'dongeng', 'fairy tale',
    'lucu', 'funny', 'joke', 'lelucon',
  ];

  /// Classifies a user message as finance-related or not.
  /// Returns (isFinance, reason).
  static (bool, String) classify(String message) {
    final lower = message.toLowerCase().trim();

    // Check for explicit non-finance phrases first
    for (final phrase in _nonFinancePhrases) {
      if (lower.contains(phrase)) {
        // But allow if it also contains strong finance keywords
        final hasFinanceKeyword = _financeKeywords.any((kw) => lower.contains(kw));
        if (!hasFinanceKeyword) {
          return (false, 'Non-finance phrase detected: "$phrase"');
        }
      }
    }

    // Check for explicit non-finance keywords
    for (final keyword in _nonFinanceKeywords) {
      if (lower.contains(keyword)) {
        // Allow if finance context is strong
        final financeCount = _financeKeywords.where((kw) => lower.contains(kw)).length;
        if (financeCount == 0) {
          return (false, 'Non-finance keyword detected: "$keyword"');
        }
        // If only 1 weak finance keyword, still reject
        if (financeCount == 1 && !_isStrongFinanceKeyword(lower)) {
          return (false, 'Weak finance context with non-finance keyword: "$keyword"');
        }
      }
    }

    // Check for finance keywords
    final financeMatches = _financeKeywords.where((kw) => lower.contains(kw)).toList();
    if (financeMatches.isNotEmpty) {
      return (true, 'Finance keywords: ${financeMatches.take(3).join(", ")}');
    }

    // Ambiguous - no clear keywords either way
    // Allow but will trigger clarification in system prompt
    return (true, 'Ambiguous - allowing with clarification');
  }

  static bool _isStrongFinanceKeyword(String lower) {
    const strongKeywords = [
      'saldo', 'balance', 'pengeluaran', 'pemasukan', 'transaksi', 'catat',
      'tabungan', 'budget', 'anggaran', 'hutang', 'piutang', 'investasi',
      'gaji', 'bonus', 'cicilan', 'net worth', 'cashflow', 'arus kas',
    ];
    return strongKeywords.any((kw) => lower.contains(kw));
  }

  /// Get the polite rejection message in Indonesian
  static String getRejectionMessage() {
    return SystemPrompt.rejectionMessage;
  }

  /// Check if message is likely a clarification to a previous finance query
  static bool isClarification(String message, String? previousContext) {
    if (previousContext == null) return false;
    final lower = message.toLowerCase().trim();
    // Short responses that could be clarifications
    if (lower.length < 30) {
      final clarificationPatterns = [
        'ya', 'yes', 'oke', 'ok', 'baik', 'bisa', 'boleh',
        'tidak', 'no', 'jangan', 'batal', 'cancel',
        'ubah', 'ganti', 'change', 'edit',
        '15000', '15rb', '15k', 'rp', 'rupiah',
        'makan', 'transport', 'belanja',
        'kartu', 'cash', 'tunai',
      ];
      return clarificationPatterns.any((p) => lower.contains(p));
    }
    return false;
  }
}