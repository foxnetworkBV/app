class AppFormatters {
  static const _months = <String>[
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static String dateTime(String value, {String empty = '—'}) {
    final raw = value.trim();
    if (raw.isEmpty) return empty;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final local = parsed.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${_months[local.month - 1]} ${local.year}, $hour:$minute';
  }

  static String date(String value, {String empty = '—'}) {
    final raw = value.trim();
    if (raw.isEmpty) return empty;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final local = parsed.toLocal();
    return '${local.day} ${_months[local.month - 1]} ${local.year}';
  }
}
