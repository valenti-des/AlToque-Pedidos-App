import 'package:app/models/product.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('product card flashes before opening its details', (
    WidgetTester tester,
  ) async {
    var opened = false;
    final product = Product(
      name: 'Tostado',
      description: 'Jamón y queso',
      price: '\$ 5.500',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductCard(
            product,
            () {},
            onOpen: () {
              opened = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tostado'));
    await tester.pump();

    final cardAnimation = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(ProductCard),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(
      (cardAnimation.decoration! as BoxDecoration).color,
      AppColors.paleBlue,
    );
    expect(opened, isFalse);

    await tester.pump(const Duration(milliseconds: 110));
    expect(opened, isTrue);

    await tester.pump(const Duration(milliseconds: 110));
    final resetAnimation = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(ProductCard),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect((resetAnimation.decoration! as BoxDecoration).color, Colors.white);
  });
}
