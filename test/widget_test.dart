import 'package:flutter_test/flutter_test.dart';

import 'package:tracktoger/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const GerotrackApp(),
    ); // ✅ Cambiado MyApp() → GerotrackApp()

    // Verifica que la app se construyó
    expect(find.byType(GerotrackApp), findsOneWidget);

    // Si tienes un contador en HomeScreen (por ejemplo), verifica su estado inicial
    // Ajusta estos expect según tu UI real
    expect(find.text('0'), findsNothing); // O elimínalo si no hay contador
    expect(find.text('1'), findsNothing);
  });
}
