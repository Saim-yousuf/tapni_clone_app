import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors Add Links close → child → reopen-on-back sequencing.
void main() {
  testWidgets(
    'picker closes before child opens, then reopens after child back',
    (tester) async {
      var pickerOpenCount = 0;
      var childOpen = false;

      Future<String?> presentPicker(BuildContext context) {
        pickerOpenCount++;
        return showModalBottomSheet<String>(
          context: context,
          builder: (ctx) => Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx, 'whatsapp'),
              child: const Text('Pick WhatsApp'),
            ),
          ),
        );
      }

      Future<void> openChild(BuildContext context) {
        childOpen = true;
        return showModalBottomSheet<void>(
          context: context,
          builder: (ctx) => Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Child Back'),
            ),
          ),
        ).whenComplete(() => childOpen = false);
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
                        // Same guard as production: wait out dismiss animation.
                        await Future<void>.delayed(
                          const Duration(milliseconds: 420),
                        );
                        if (!context.mounted) return;
                        await openChild(context);
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
      expect(find.text('Pick WhatsApp'), findsOneWidget);
      expect(pickerOpenCount, 1);

      await tester.tap(find.text('Pick WhatsApp'));
      // Drive dismiss + post-pop delay + child open.
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 420));
      await tester.pumpAndSettle();

      expect(find.text('Pick WhatsApp'), findsNothing);
      expect(find.text('Child Back'), findsOneWidget);
      expect(childOpen, isTrue);

      await tester.tap(find.text('Child Back'));
      await tester.pumpAndSettle();
      expect(find.text('Child Back'), findsNothing);
      expect(find.text('Pick WhatsApp'), findsOneWidget);
      expect(pickerOpenCount, 2);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Pick WhatsApp'), findsNothing);
    },
  );

  testWidgets(
    'if child future is not awaited, picker reopens too early (regression)',
    (tester) async {
      var sawPickerWhileChildVisible = false;

      Future<String?> presentPicker(BuildContext context) {
        return showModalBottomSheet<String>(
          context: context,
          builder: (ctx) => Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx, 'x'),
              child: const Text('Pick'),
            ),
          ),
        );
      }

      void openChildBroken(BuildContext context) {
        showModalBottomSheet<void>(
          context: context,
          builder: (ctx) => const Center(child: Text('Child Sheet')),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () async {
                      final selected = await presentPicker(context);
                      if (!context.mounted || selected == null) return;
                      openChildBroken(context); // not awaited
                      await presentPicker(context);
                    },
                    child: const Text('Start'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();

      if (find.text('Pick').evaluate().isNotEmpty) {
        sawPickerWhileChildVisible = true;
      }

      expect(
        sawPickerWhileChildVisible,
        isTrue,
        reason: 'documents the old fire-and-forget reopen race',
      );
    },
  );
}
