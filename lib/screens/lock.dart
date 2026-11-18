import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../core/biometrics.dart';
import '../core/l10n.dart';
import '../core/models.dart';
import '../core/parsers.dart';
import '../ui/avatar.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  Member? _picked;

  Future<void> _biometric(Member m) async {
    final app = AppScope.read(context);
    if (app.settings.biometricMemberId == m.id && await Biometrics.confirm(tr('biometric_reason'))) await app.login(m);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final picked = _picked;
    return Scaffold(
      body: Backdrop(
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            child: picked == null
                ? ListView(key: const ValueKey('picker'), padding: const EdgeInsets.all(24), children: [
                    const SizedBox(height: 30),
                    Text(tr('who_logging_in'), textAlign: TextAlign.center, style: context.tt.headlineMedium),
                    const SizedBox(height: 6),
                    Text(tr('pick_profile'), textAlign: TextAlign.center, style: context.tt.bodyMedium!.copyWith(color: context.cs.onSurfaceVariant)),
                    const SizedBox(height: 30),
                    Wrap(alignment: WrapAlignment.center, spacing: 18, runSpacing: 22, children: [
                      for (final (i, m) in app.members.indexed)
                        Entrance(
                          index: i,
                          child: Pressable(
                            scale: 0.9,
                            onTap: () {
                              if (m.hasPin) {
                                setState(() => _picked = m);
                                _biometric(m);
                              } else {
                                app.login(m);
                              }
                            },
                            child: SizedBox(
                              width: 120,
                              child: Column(children: [
                                AvatarView(m.avatar.copyWith(mood: Mood.happy), size: 104, animate: true),
                                const SizedBox(height: 10),
                                Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleMedium),
                                Text(m.hasPin ? tr('pin_set') : tr('rel_${m.relation}'), style: context.tt.bodySmall),
                              ]),
                            ),
                          ),
                        ),
                    ]),
                  ])
                : SingleChildScrollView(
                    key: ValueKey('pin${picked.id}'),
                    padding: const EdgeInsets.all(24),
                    child: Column(children: [
                      const SizedBox(height: 16),
                      AvatarView(picked.avatar.copyWith(mood: Mood.happy), size: 96, animate: true, action: AvatarAction.wave),
                      const SizedBox(height: 12),
                      Text(tr('hi_name', [picked.name]), style: context.tt.headlineSmall),
                      const SizedBox(height: 18),
                      PinPad(hint: tr('enter_pin'), onComplete: (pin) async {
                        if (!Pin.matches(pin, picked.pinHash)) return tr('wrong_pin');
                        await app.login(picked);
                        return null;
                      }),
                      if (app.settings.biometricMemberId == picked.id) ...[
                        const SizedBox(height: 14),
                        KButton(tr('biometric_unlock'), tonal: true, expand: false, icon: Icons.fingerprint_rounded, onTap: () => _biometric(picked)),
                      ],
                      const SizedBox(height: 10),
                      TextButton(onPressed: () => setState(() => _picked = null), child: Text(tr('switch_profile', [picked.name]))),
                    ]),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Four dots and a keypad. [onComplete] returns an error message to shake and clear, or null on success.
class PinPad extends StatefulWidget {
  const PinPad({super.key, required this.hint, required this.onComplete});
  final String hint;
  final Future<String?> Function(String pin) onComplete;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  String _pin = '';
  String? _error;

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Future<void> _press(String key) async {
    HapticFeedback.lightImpact();
    if (key == '⌫') {
      if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
      return;
    }
    if (_pin.length >= Pin.length) return;
    setState(() {
      _pin += key;
      _error = null;
    });
    if (_pin.length < Pin.length) return;
    final error = await widget.onComplete(_pin);
    if (!mounted) return;
    setState(() {
      _pin = '';
      _error = error;
    });
    if (error != null) {
      HapticFeedback.heavyImpact();
      _shake.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];
    return Column(children: [
      AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: Text(_error ?? widget.hint, key: ValueKey(_error ?? widget.hint), textAlign: TextAlign.center, style: context.tt.bodyMedium!.copyWith(color: _error == null ? cs.onSurfaceVariant : cs.error, fontWeight: FontWeight.w600))),
      const SizedBox(height: 18),
      AnimatedBuilder(
        animation: _shake,
        builder: (_, child) => Transform.translate(offset: Offset(sin(_shake.value * pi * 5) * 12 * (1 - _shake.value), 0), child: child),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < Pin.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              margin: const EdgeInsets.symmetric(horizontal: 9),
              width: i < _pin.length ? 20 : 16,
              height: i < _pin.length ? 20 : 16,
              decoration: BoxDecoration(shape: BoxShape.circle, color: i < _pin.length ? cs.primary : cs.surfaceContainerHighest),
            ),
        ]),
      ),
      const SizedBox(height: 26),
      SizedBox(
        width: 290,
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.25,
          children: [
            for (final k in keys)
              if (k.isEmpty)
                const SizedBox()
              else
                Pressable(
                  scale: 0.84,
                  onTap: () => _press(k),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: cs.outlineVariant)),
                    child: k == '⌫' ? Icon(Icons.backspace_rounded, color: cs.onSurface) : Text(k, style: context.tt.headlineSmall),
                  ),
                ),
          ],
        ),
      ),
    ]);
  }
}

/// Asks for a new PIN twice. Returns it, or null when the sheet is closed.
Future<String?> askNewPin(BuildContext context) {
  String? first;
  return showKSheet<String>(
    context,
    title: tr('set_pin'),
    builder: (sheet) => StatefulBuilder(
      builder: (_, setState) => PinPad(
        key: ValueKey(first),
        hint: first == null ? '${tr('pin_create')} · ${tr('pin_create_hint')}' : '${tr('pin_confirm')} · ${tr('pin_confirm_hint')}',
        onComplete: (pin) async {
          if (first == null) {
            if (Pin.isWeak(pin)) return tr('pin_weak');
            setState(() => first = pin);
            return null;
          }
          if (pin != first) {
            setState(() => first = null);
            return tr('pin_mismatch');
          }
          Navigator.of(sheet).pop(pin);
          return null;
        },
      ),
    ),
  );
}
