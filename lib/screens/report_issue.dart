import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_state.dart';
import '../core/l10n.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'me.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _desc = TextEditingController();
  String _type = 'bug';
  bool _includeDeviceInfo = true;
  XFile? _screenshot;

  static const _types = [
    ('bug', 'report_type_bug', Icons.bug_report_rounded, Color(0xFFE53935)),
    ('crash', 'report_type_crash', Icons.warning_rounded, Color(0xFFFB8C00)),
    ('ui', 'report_type_ui', Icons.palette_rounded, Color(0xFF8E24AA)),
    ('idea', 'report_type_idea', Icons.lightbulb_rounded, Color(0xFF039BE5)),
  ];

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (file != null && mounted) setState(() => _screenshot = file);
  }

  Future<void> _send() async {
    final text = _desc.text.trim();
    if (text.isEmpty) {
      toast(context, tr('report_empty_hint'));
      return;
    }
    final app = AppScope.read(context);
    final typeLabel = _types.firstWhere((t) => t.$1 == _type).$2;
    final buf = StringBuffer()
      ..writeln('Gharcha Feedback — ${tr(typeLabel)}')
      ..writeln()
      ..writeln(text);
    if (_includeDeviceInfo) {
      buf
        ..writeln()
        ..writeln('---')
        ..writeln('App version: $appVersion')
        ..writeln('Platform: ${Platform.operatingSystem} (${Platform.operatingSystemVersion})')
        ..writeln('Language: ${app.settings.language}')
        ..writeln('Theme: ${app.activeThemeId}');
    }
    final subject = 'Gharcha ${tr(typeLabel)} (v$appVersion)';
    if (_screenshot != null) {
      await Share.shareXFiles([_screenshot!], text: buf.toString(), subject: subject);
    } else {
      await Share.share(buf.toString(), subject: subject);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final cs = context.cs;
    final infoLine = 'v$appVersion · ${Platform.operatingSystem} · ${app.settings.language}';

    return KPage(
      title: tr('report_issue'),
      bottom: KButton(
        tr('report_send'),
        icon: Icons.send_rounded,
        onTap: _desc.text.trim().isEmpty ? null : _send,
      ),
      children: [
        KCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('report_what_happened'), style: context.tt.labelMedium),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final t in _types)
                KChip(
                  tr(t.$2),
                  selected: _type == t.$1,
                  icon: t.$3,
                  color: t.$4,
                  onTap: () => setState(() => _type = t.$1),
                ),
            ]),
            const SizedBox(height: 18),
            KField(
              controller: _desc,
              label: tr('report_describe'),
              hint: tr('report_describe_hint'),
              lines: 5,
              onChanged: (_) => setState(() {}),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        KCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(children: [
            NavRow(
              icon: Icons.add_photo_alternate_rounded,
              color: const Color(0xFF039BE5),
              title: tr('report_screenshot'),
              subtitle: _screenshot == null ? tr('report_screenshot_sub') : _screenshot!.name,
              onTap: _pickScreenshot,
              trailing: _screenshot == null
                  ? null
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(File(_screenshot!.path), width: 42, height: 42, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 6),
                      Pressable(
                        onTap: () => setState(() => _screenshot = null),
                        child: Icon(Icons.close_rounded, size: 18, color: cs.onSurfaceVariant),
                      ),
                    ]),
            ),
            NavRow(
              icon: Icons.perm_device_information_rounded,
              color: const Color(0xFF26A69A),
              title: tr('report_device_info'),
              subtitle: infoLine,
              trailing: KSwitch(value: _includeDeviceInfo, onChanged: (v) => setState(() => _includeDeviceInfo = v)),
            ),
          ]),
        ),
      ],
    );
  }
}
