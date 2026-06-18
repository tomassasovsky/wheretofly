import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_repository/social_repository.dart';
import 'package:where_to_fly/l10n/gen/app_localizations.dart';
import 'package:where_to_fly/social/view/widgets/reel_feed_item.dart';

void main() {
  SocialPost postWith(Map<String, dynamic>? snapshot) => SocialPost(
        id: 'p1',
        caption: 'caption',
        createdAt: DateTime(2026),
        author: const SocialAuthor(handle: 'pilot', displayName: 'Test Pilot'),
        verdictSnapshot: snapshot,
        media: const [
          PostMedia(
            id: 'm1',
            type: PostMediaType.photo,
            url: 'https://x/y.jpg',
          ),
        ],
      );

  Future<void> pump(WidgetTester tester, SocialPost post) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ReelFeedItem(post: post, isActive: false),
        ),
      ),
    );
    // Single pump only — Image.network's loading spinner never settles.
    await tester.pump();
  }

  testWidgets('v1 snapshot (verdict only) renders via legacy fallback',
      (tester) async {
    await pump(tester, postWith({'verdict': 'notAllowed'}));
    expect(find.text("You can't fly here"), findsOneWidget);
  });

  testWidgets('v2 snapshot prefers status: uncertain (arm not dead)',
      (tester) async {
    await pump(
      tester,
      postWith({'verdict': 'notAllowed', 'status': 'uncertain'}),
    );
    expect(find.text('Verify manually'), findsOneWidget);
    expect(find.text("You can't fly here"), findsNothing);
  });

  testWidgets('v2 allowed, conditional and blocked render sanely',
      (tester) async {
    await pump(tester, postWith({'status': 'allowed'}));
    expect(find.text('You can fly here'), findsOneWidget);

    await pump(tester, postWith({'status': 'conditional'}));
    expect(find.text('You can fly with your permit'), findsOneWidget);

    await pump(tester, postWith({'status': 'blocked'}));
    expect(find.text("You can't fly here"), findsOneWidget);
  });

  testWidgets('unknown token degrades to neutral verdict-unavailable label',
      (tester) async {
    await pump(tester, postWith({'status': 'martian'}));
    expect(find.text('Verdict unavailable'), findsOneWidget);
  });
}
