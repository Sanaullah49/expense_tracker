import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/app.dart';

void main() {
  test('Core app routes are registered', () {
    final routes = AppRoutes.routes;

    expect(routes.containsKey(AppRoutes.splash), isTrue);
    expect(routes.containsKey(AppRoutes.home), isTrue);
    expect(routes.containsKey(AppRoutes.transactions), isTrue);
    expect(routes.containsKey(AppRoutes.settings), isTrue);
  });
}
