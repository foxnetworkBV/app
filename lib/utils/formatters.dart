class AppFormatters {
  static const _months = <String>[
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static String dateTime(String value, {String empty = '—'}) {
    final parsed = _parse(value);
    if (parsed == null) return value.trim().isEmpty ? empty : value;
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '${parsed.day} ${_months[parsed.month - 1]} ${parsed.year} at $hour:$minute';
  }

  static String date(String value, {String empty = '—'}) {
    final parsed = _parse(value);
    if (parsed == null) return value.trim().isEmpty ? empty : value;
    return '${parsed.day} ${_months[parsed.month - 1]} ${parsed.year}';
  }

  static String relativeDate(String value, {String empty = '—'}) {
    final parsed = _parse(value);
    if (parsed == null) return value.trim().isEmpty ? empty : value;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(parsed.year, parsed.month, parsed.day);
    final difference = day.difference(today).inDays;
    final time = '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
    if (difference == 0) return 'Today at $time';
    if (difference == -1) return 'Yesterday at $time';
    if (difference == 1) return 'Tomorrow at $time';
    return dateTime(value, empty: empty);
  }

  static String money(double amount, String currency) {
    final code = currency.trim().isEmpty ? 'EUR' : currency.trim().toUpperCase();
    final symbol = switch (code) {
      'EUR' => '€',
      'USD' => r'$',
      'GBP' => '£',
      _ => '$code ',
    };
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  static DateTime? _parse(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }
}
