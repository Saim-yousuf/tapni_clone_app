import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Add Links: reopen picker only when child pops with back=true.
void main() {
  testWidgets(
    'picker reopens after child back, not after child save',
    (tester) async {
      var pickerOpenCount = 0;

      Future<String?> presentPicker(BuildContext context) {
        pickerOpenCount++;
        return showModalBottomSheet<String>(
          context: context,
          builder: (ctx) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 'whatsapp'),
                  child: const Text('Pick WhatsApp'),
                ),
              ],
            ),
          ),
        );
      }

      Future<bool> openChild(BuildContext context) {
        return showModalBottomSheet<bool>(
          context: context,
          builder: (ctx) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Child Back'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Child Save'),
                ),
              ],
            ),
          ),
        ).then((r) => r == true);
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () async {
                      while (context.mounted) {
                        final selected = await presentPicker(context);
                        if (!context.mounted || selected == null) return;
                        await Future<void>.delayed(
                          const Duration(milliseconds: 420),
                        );
                        if (!context.mounted) return;
                        final reopen = await openChild(context);
                        if (!context.mounted || !reopen) return;
                      }
                    },
                    child: const Text('Open Add Links'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Add Links'));
      await tester.pumpAndSettle();
      expect(pickerOpenCount, 1);

      await tester.tap(find.text('Pick WhatsApp'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 420));
      await tester.pumpAndSettle();

      expect(find.text('Child Back'), findsOneWidget);

      await tester.tap(find.text('Child Back'));
      await tester.pumpAndSettle();
      expect(find.text('Pick WhatsApp'), findsOneWidget);
      expect(pickerOpenCount, 2);

      await tester.tap(find.text('Pick WhatsApp'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 420));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Child Save'));
      await tester.pumpAndSettle();
      expect(find.text('Pick WhatsApp'), findsNothing);
      expect(pickerOpenCount, 2);
    },
  );
}
