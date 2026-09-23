import 'package:intl/intl.dart';

final moneyFmt = NumberFormat.currency(locale: 'es_CO', symbol: r'$', decimalDigits: 0);
final dateFmt = DateFormat("EEE d MMM · HH:mm", 'es');
final shortDate = DateFormat("d MMM", 'es');

String prettyDate(String iso) {
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null || iso.isEmpty) return 'Sin fecha';
  return dateFmt.format(d);
}

String prettyStatus(String status) => status.replaceAll('_', ' ');
