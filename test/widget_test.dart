import 'package:flutter_test/flutter_test.dart';
import 'package:fyco_site/constants.dart';

void main() {
  test('FYCO store currency is Moroccan dirham', () {
    expect(AppConstants.currency, 'MAD');
  });
}
