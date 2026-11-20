import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_actions/quick_actions.dart';

import '../core/app_state.dart';
import '../core/l10n.dart';
import '../core/notifier.dart';
import '../ui/effects.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'add_expense.dart';
import 'budgets.dart';
import 'expenses.dart';
import 'groups.dart';
import 'home.dart';
import 'household.dart';
import 'insights.dart';
import 'lists.dart';
import 'me.dart';
import 'reminders.dart';
import 'rewards.dart';
import 'tour.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  static void switchTab(BuildContext context, int index) => context.findAncestorStateOfType<_ShellState>()?._select(index);

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late final AppLifecycleListener _lifecycle;
  int _tab = 0;
  DateTime? _lastBack;
  String? _shortcutLanguage;

  @override
  void initState() {
    super.initState();
    Notifier.routeTaps.addListener(_followRoute);
    _lifecycle = AppLifecycleListener(onResume: () => AppScope.read(context).syncCaptures());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final showTips = Notifier.pendingRoute == null && !AppScope.read(context).settings.tourSeen;
      _followRoute();
      if (showTips) showTour(context);
    });
    const QuickActions().initialize(Notifier.open);
  }

  @override
  void dispose() {
    Notifier.routeTaps.removeListener(_followRoute);
    _lifecycle.dispose();
    super.dispose();
  }

  void _select(int index) => setState(() => _tab = index);

  void _back() {
    if (_tab != 0) {
      _select(0);
      return;
    }
    final now = DateTime.now();
    if (_lastBack != null && now.difference(_lastBack!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _lastBack = now;
    toast(context, tr('back_again_exit'));
  }

  void _followRoute() {
    final route = Notifier.pendingRoute;
    if (!mounted || route == null) return;
    Notifier.pendingRoute = null;
    Navigator.of(context).popUntil((r) => r.isFirst);
    switch (route) {
      case 'add':
        open(context, const AddExpenseScreen(), rise: true);
      case 'voice':
        open(context, const AddExpenseScreen(startWithVoice: true), rise: true);
      case 'first':
        open(context, const AddExpenseScreen(firstTime: true), rise: true);
      case 'rewards':
        open(context, const RewardsScreen());
      case 'badges':
        open(context, const RewardsScreen(initialTab: 1));
      case 'budgets':
        open(context, const BudgetsScreen());
      case 'reminders':
        open(context, const RemindersScreen());
      case 'shopping':
        open(context, const ShoppingScreen());
      case 'goals':
        open(context, const GoalsScreen());
      case 'loans':
        open(context, const LoansScreen());
      case 'papers':
        open(context, const PapersScreen());
      case 'accounts':
        open(context, const AccountsScreen());
      case 'services':
        open(context, const ServicesScreen());
      case 'savings':
        open(context, const SavingsScreen());
      case 'insights':
        open(context, const InsightsScreen());
      case 'expenses':
        _select(1);
      default:
        _select(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    const tabs = [HomeTab(), ExpensesTab(), GroupsTab(), MeTab()];
    final language = AppScope.of(context).settings.language;
    if (language != _shortcutLanguage) {
      _shortcutLanguage = language;
      const QuickActions().setShortcutItems([
        for (final (route, title) in [('add', 'add_transaction'), ('voice', 'shortcut_voice'), ('reminders', 'shortcut_bills'), ('shopping', 'shopping_list')])
          ShortcutItem(type: route, localizedTitle: tr(title), icon: 'shortcut_$route'),
      ]);
    }
    return CelebrationHost(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back();
        },
        child: Scaffold(
        extendBody: true,
        body: Stack(children: [
          for (var i = 0; i < tabs.length; i++)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: _tab != i,
                child: AnimatedOpacity(
                  opacity: _tab == i ? 1 : 0,
                  duration: const Duration(milliseconds: 260),
                  child: AnimatedScale(scale: _tab == i ? 1 : 0.97, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic, child: TickerMode(enabled: _tab == i, child: tabs[i])),
                ),
              ),
            ),
        ]),
        bottomNavigationBar: _NavBar(tab: _tab, onSelect: _select, onAdd: () => open(context, const AddExpenseScreen(), rise: true)),
        ),
      ),
    );
  }
}

const _barHeight = 78.0;

class _NavBar extends StatelessWidget {
  const _NavBar({required this.tab, required this.onSelect, required this.onAdd});
  final int tab;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    Widget item(int index, IconData icon, IconData active, String label) {
      final on = tab == index;
      return Expanded(
        child: Pressable(
          scale: 0.86,
          onTap: () => onSelect(index),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutBack,
              padding: EdgeInsets.symmetric(horizontal: on ? 16 : 8, vertical: 6),
              decoration: BoxDecoration(color: on ? cs.primaryContainer : Colors.transparent, borderRadius: BorderRadius.circular(999)),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                child: Icon(on ? active : icon, key: ValueKey(on), size: 24, color: on ? cs.primary : cs.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 3),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: on ? FontWeight.w700 : FontWeight.w500, color: on ? cs.primary : cs.onSurfaceVariant)),
          ]),
        ),
      );
    }

    final inset = MediaQuery.viewPaddingOf(context).bottom;
    return SizedBox(
      height: _barHeight + inset + 22,
      child: Stack(alignment: Alignment.bottomCenter, clipBehavior: Clip.none, children: [
        Container(
          height: _barHeight + inset,
          padding: EdgeInsets.fromLTRB(8, 10, 8, inset),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(top: BorderSide(color: cs.outlineVariant)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: context.isDark ? 0.5 : 0.1), blurRadius: 30, offset: const Offset(0, -6))],
          ),
          child: Row(children: [
            item(0, Icons.home_outlined, Icons.home_rounded, tr('tab_home')),
            item(1, Icons.receipt_long_outlined, Icons.receipt_long_rounded, tr('tab_expenses')),
            const SizedBox(width: 76),
            item(2, Icons.groups_outlined, Icons.groups_rounded, tr('tab_groups')),
            item(3, Icons.person_outline_rounded, Icons.person_rounded, tr('tab_me')),
          ]),
        ),
        Positioned(top: 0, child: _AddButton(onTap: onAdd)),
      ]),
    );
  }
}

class _AddButton extends StatefulWidget {
  const _AddButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
  double _turns = 0;

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Pressable(
      scale: 0.86,
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() => _turns += 0.25);
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _glow,
        builder: (_, child) => Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: context.heroGradient,
            border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 4),
            boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.35 + 0.25 * _glow.value), blurRadius: 16 + 12 * _glow.value, offset: const Offset(0, 8))],
          ),
          child: child,
        ),
        child: AnimatedRotation(turns: _turns, duration: const Duration(milliseconds: 420), curve: Curves.easeOutBack, child: Icon(Icons.add_rounded, color: Colors.white, size: 34, semanticLabel: tr('add_transaction'))),
      ),
    );
  }
}
