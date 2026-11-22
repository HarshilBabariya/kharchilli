import 'package:flutter_test/flutter_test.dart';
import 'package:gharcha/core/capture.dart';
import 'package:gharcha/core/catalogs.dart';
import 'package:gharcha/core/models.dart';
import 'package:gharcha/core/parsers.dart';

void main() {
  group('SplitCalculator', () {
    test('equal shares keep every paisa', () {
      expect(SplitCalculator.equalShares(100, [1, 2, 3]), {1: 33.34, 2: 33.33, 3: 33.33});
      expect(SplitCalculator.equalShares(90, []), isEmpty);
    });

    test('settle-up pays the creditor from the largest debtor first', () {
      final plan = SplitCalculator.settlements(const [MemberBalance(1, 'A', 60), MemberBalance(2, 'B', -40), MemberBalance(3, 'C', -20)]);
      expect(plan.map((t) => (t.fromId, t.toId, t.amount)).toList(), [(2, 1, 40.0), (3, 1, 20.0)]);
    });

    test('settled balances need no payments', () {
      expect(SplitCalculator.settlements(const [MemberBalance(1, 'A', 0), MemberBalance(2, 'B', 0)]), isEmpty);
    });
  });

  group('MessageParser', () {
    test('reads a UPI debit', () {
      final r = MessageParser.parse('Rs.250.00 debited from A/c XX1234 to ZOMATO on 19-11-26. UPI Ref 4321', {})!;
      expect(r.amount, 250.0);
      expect(r.title, 'Zomato');
      expect(r.mode, PaymentMode.upi);
      expect(r.credit, isFalse);
    });

    test('reads a credit', () {
      final r = MessageParser.parse('Rs 500 credited to your a/c from PAYTM CASHBACK via UPI', {})!;
      expect(r.amount, 500.0);
      expect(r.title, 'Paytm Cashback');
      expect(r.credit, isTrue);
    });

    test('reads a card spend with thousands separators', () {
      final r = MessageParser.parse('INR 1,240.50 spent on HDFC Card xx9876 at BIG BAZAAR on 18-11', {})!;
      expect(r.amount, 1240.5);
      expect(r.mode, PaymentMode.card);
    });

    test('ignores text without a currency amount', () {
      expect(MessageParser.parse('see you at 5', {}), isNull);
    });
  });

  group('PaymentParser', () {
    test('accepts a completed debit', () {
      final p = PaymentParser.parse('Rs.250.00 debited from A/c XX1234 to ZOMATO on 19-11-26. UPI Ref 4321')!;
      expect(p.amount, 250.0);
      expect(p.merchant, 'ZOMATO');
    });

    test('money received is negative and names the sender', () {
      final p = PaymentParser.parse('Rahul paid you ₹300')!;
      expect(p.amount, -300.0);
      expect(p.merchant, 'Rahul');
    });

    test('rejects one-time passwords, promotions and chatter', () {
      expect(PaymentParser.parse('Your OTP for payment of Rs 500 is 123456'), isNull);
      expect(PaymentParser.parse('Flat Rs 200 off on your next order. Shop now'), isNull);
      expect(PaymentParser.parse('Dinner at 8?'), isNull);
    });
  });

  group('VoiceParser', () {
    test('picks up the amount and payment mode', () {
      final r = VoiceParser.parse('250 groceries by upi', {});
      expect(r.amount, 250.0);
      expect(r.mode, PaymentMode.upi);
      expect(r.credit, isFalse);
    });
  });

  group('Goal', () {
    test('spreads what is left over the months to the due month', () {
      final goal = Goal(name: 'Trip', target: 12000, dueMonth: 202703);
      expect(goal.monthly(DateTime(2026, 11, 19)), 2400.0);
      expect(Goal(name: 'Trip', target: 12000).monthly(DateTime(2026, 11, 19)), isNull);
    });

    test('a past due month asks for everything now', () {
      expect(Goal(name: 'Trip', target: 900, saved: 300, dueMonth: 202601).monthly(DateTime(2026, 11, 19)), 600.0);
    });
  });

  group('guessCategory', () {
    const custom = {'c_petrol': 'Petrol', 'c_veg': 'Vegitables & Fruits', 'c_dairy': 'Dairy'};

    test('a shop name finds the custom category it resembles', () {
      expect(VoiceParser.guessCategory('Xyz Petroleum', custom), 'c_petrol');
      expect(VoiceParser.guessCategory('HP Fuel Station', custom), 'c_petrol');
      expect(VoiceParser.guessCategory('Karnavati Milk Parlour', custom), 'c_dairy');
    });

    test('falls back to a built-in category, then to nothing', () {
      expect(VoiceParser.guessCategory('Xyz Petroleum', const {}), BuiltInCategories.transport);
      expect(VoiceParser.guessCategory('Ramesh Kumar', custom), isNull);
    });
  });

  group('Pin', () {
    test('matches only the PIN it was made from', () {
      final stored = Pin.hash('2580');
      expect(Pin.matches('2580', stored), isTrue);
      expect(Pin.matches('2581', stored), isFalse);
      expect(Pin.matches('2580', ''), isFalse);
    });

    test('rejects weak PINs', () {
      expect(Pin.isWeak('1111'), isTrue);
      expect(Pin.isWeak('1234'), isTrue);
      expect(Pin.isWeak('2580'), isFalse);
    });
  });

  group('Csv', () {
    test('round-trips commas, quotes and line breaks', () {
      const rows = [
        ['date', 'title'],
        ['2026-11-19', 'Milk, bread'],
        ['2026-11-20', 'He said "ok"\nthen left'],
      ];
      expect(Csv.parse(Csv.encode(rows)), rows);
    });

    test('reads both date orders', () {
      expect(Csv.parseDate('2026-11-19'), DateTime(2026, 11, 19));
      expect(Csv.parseDate('19/11/2026'), DateTime(2026, 11, 19));
      expect(Csv.parseDate('soon'), isNull);
    });
  });

  group('SpinWheelCatalog & RewardProgress', () {
    test('slice weights sum to 100 and pickWeighted covers full range', () {
      final total = SpinWheelCatalog.slices.fold(0, (sum, s) => sum + s.weight);
      expect(total, 100);
      expect(SpinWheelCatalog.pickWeighted(0).id, 'themes');
      expect(SpinWheelCatalog.pickWeighted(99).id, 'all_access');
    });

    test('RewardProgress round-trips through Settings JSON', () {
      final s = Settings()
        ..rewardProgress = RewardProgress(
          tempUnlocks: {'themes': 123456789},
          ownProgress: {'themes': 40},
          lastFreeSpinDay: 20261122,
          lastAdSpinDay: 20261122,
          adSpinsUsedToday: 2,
        );
      final restored = Settings.fromJson(s.toJson());
      expect(restored.rewardProgress.tempUnlocks['themes'], 123456789);
      expect(restored.rewardProgress.ownProgress['themes'], 40);
      expect(restored.rewardProgress.lastFreeSpinDay, 20261122);
      expect(restored.rewardProgress.adSpinsUsedToday, 2);
    });
  });
}
