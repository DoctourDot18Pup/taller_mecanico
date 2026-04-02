import 'package:intl/intl.dart';

class Fmt {
  static final _fecha = DateFormat('dd/MM/yyyy');
  static final _mes = DateFormat('MMMM yyyy', 'es_MX');
  static final _moneda = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);

  static String fecha(DateTime d) => _fecha.format(d);
  static String mes(DateTime d) => _mes.format(d);
  static String moneda(double amount) => _moneda.format(amount);
}
