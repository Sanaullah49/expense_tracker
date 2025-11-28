import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider with ChangeNotifier {
  static const String _currencyKey = 'currency_code';
  static const String _symbolKey = 'currency_symbol';

  String _currencyCode = 'USD';
  String _currencySymbol = '\$';

  String get currencyCode => _currencyCode;
  String get currencySymbol => _currencySymbol;

  CurrencyProvider() {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _currencyCode = prefs.getString(_currencyKey) ?? 'USD';
    _currencySymbol = prefs.getString(_symbolKey) ?? '\$';
    notifyListeners();
  }

  Future<void> setCurrency(String code, String symbol) async {
    _currencyCode = code;
    _currencySymbol = symbol;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, code);
    await prefs.setString(_symbolKey, symbol);

    notifyListeners();
  }

  String formatAmount(double amount, {bool showSymbol = true}) {
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: showSymbol ? _currencySymbol : '',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  String formatCompactAmount(double amount) {
    final formatter = NumberFormat.compactCurrency(
      locale: 'en_US',
      symbol: _currencySymbol,
    );
    return formatter.format(amount);
  }
}
