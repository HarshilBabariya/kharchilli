import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../core/app_state.dart';
import '../core/format.dart';
import '../core/l10n.dart';
import '../core/parsers.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

Future<File> _temp(String name, List<int> bytes) async {
  final file = File('${(await getTemporaryDirectory()).path}/$name');
  return file.writeAsBytes(bytes, flush: true);
}

String _stamp(DateTime? month) => month == null ? 'all' : '${month.year}-${month.month.toString().padLeft(2, '0')}';

Future<void> shareCsv(AppState app, {DateTime? month}) async {
  final file = await _temp('kharchili-${_stamp(month)}.csv', utf8.encode('﻿${app.exportCsv(month: month)}'));
  await Share.shareXFiles([XFile(file.path, mimeType: 'text/csv')]);
}

/// The PDF uses the built-in Latin font, so amounts carry the currency code instead of its symbol.
Future<void> sharePdf(AppState app, {DateTime? month}) async {
  final list = (month == null ? [...app.expenses] : app.inMonth(month))..sort((a, b) => a.day.compareTo(b.day));
  String amount(num v) => '${v < 0 ? '+' : ''}${Fmt.currencyCode} ${Fmt.number(v)}';
  final doc = pw.Document()
    ..addPage(pw.MultiPage(
      build: (_) => [
        pw.Header(level: 0, text: 'Kharchili · ${month == null ? 'All expenses' : Csv.isoDate(month).substring(0, 7)}'),
        pw.Paragraph(text: '${list.length} expenses · total ${amount(AppState.net(list))}'),
        pw.TableHelper.fromTextArray(
          headers: ['Date', 'Title', 'Category', 'Mode', 'Paid by', 'Amount'],
          data: [
            for (final e in list) [Csv.isoDate(e.date), e.title, app.category(e.category).name, e.mode.name.toUpperCase(), app.memberName(e.paidBy), amount(e.amount)],
          ],
        ),
      ],
    ));
  final file = await _temp('kharchili-${_stamp(month)}.pdf', await doc.save());
  await Share.shareXFiles([XFile(file.path, mimeType: 'application/pdf')]);
}

Future<void> importCsvFile(BuildContext context) async {
  final app = AppScope.read(context);
  final picked = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv'], withData: true);
  final bytes = picked?.files.single.bytes;
  if (bytes == null || !context.mounted) return;
  final result = await app.importCsv(utf8.decode(bytes, allowMalformed: true));
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(result == null ? tr('import_failed') : tr('import_done')),
      content: Text(result == null ? tr('import_failed_body') : tr('import_summary', [result.added, result.duplicates, result.invalid])),
      actions: [TextButton(onPressed: () => Navigator.of(d).pop(), child: Text(tr('ok')))],
    ),
  );
}

/// Previews the weekly summary card and shares it as an image.
Future<void> shareWeeklyCard(BuildContext context) async {
  final boundary = GlobalKey();
  await showDialog<void>(
    context: context,
    builder: (d) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        RepaintBoundary(key: boundary, child: const _WeeklyCard()),
        const SizedBox(height: 14),
        KButton(tr('share'), icon: Icons.ios_share_rounded, onTap: () async {
          final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 3);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = await _temp('kharchili-week.png', data!.buffer.asUint8List());
          await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')], text: tr('weekly_card_footer'));
        }),
      ]),
    ),
  );
}

class _WeeklyCard extends StatelessWidget {
  const _WeeklyCard();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final today = Days.today();
    final week = app.between(DateTime(today.year, today.month, today.day - 6), today);
    final before = app.between(DateTime(today.year, today.month, today.day - 13), DateTime(today.year, today.month, today.day - 7));
    final total = max(AppState.net(week), 0.0), last = max(AppState.net(before), 0.0);
    final top = app.byCategory(week).take(3).toList();
    final payers = app.byPayer(week);
    final change = last <= 0 ? null : ((total - last) / last * 100).round();
    const white = Colors.white;
    return AspectRatio(
      aspectRatio: 1080 / 1350,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(gradient: context.heroGradient, borderRadius: BorderRadius.circular(28)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('weekly_card_title'), style: context.tt.titleLarge!.copyWith(color: white)),
          const Spacer(),
          Text(tr('weekly_card_spent'), style: TextStyle(color: white.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
          FittedBox(child: Text(Fmt.money(total), style: context.tt.displaySmall!.copyWith(color: white, fontSize: 48))),
          if (change != null) Pill(tr(change <= 0 ? 'weekly_card_less' : 'weekly_card_more', [change.abs()]), onDark: true),
          const Spacer(),
          if (top.isNotEmpty) Text(tr('weekly_card_top'), style: TextStyle(color: white.withValues(alpha: 0.8), fontWeight: FontWeight.w600, fontSize: 12)),
          for (final c in top)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(children: [
                Row(children: [Expanded(child: Text(c.key.name, style: const TextStyle(color: white, fontWeight: FontWeight.w600))), Text(Fmt.money(c.value), style: const TextStyle(color: white, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 4),
                KProgress(c.value / top.first.value, color: white, track: white.withValues(alpha: 0.2), height: 6),
              ]),
            ),
          if (payers.length > 1) ...[
            const SizedBox(height: 12),
            Text('${tr('weekly_card_who')}: ${payers.map((p) => '${p.key.name} ${Fmt.money(p.value)}').join(' · ')}', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: white.withValues(alpha: 0.9), fontSize: 12)),
          ],
          const Spacer(),
          Row(children: [
            Pill('🔥 ${app.streak}', onDark: true),
            const SizedBox(width: 8),
            Pill('⭐ ${Fmt.number(app.settings.points)}', onDark: true),
            const Spacer(),
            Flexible(child: Text(tr('weekly_card_footer'), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: white.withValues(alpha: 0.8), fontSize: 11))),
          ]),
        ]),
      ),
    );
  }
}
