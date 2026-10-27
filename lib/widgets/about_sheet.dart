import 'package:flutter/material.dart';

import '../core/palette.dart';
import '../core/text_styles.dart';
import '../core/motion.dart';
import 'editorial.dart';

Future<void> showAboutSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: Palette.ink.withValues(alpha: 0.45),
    builder: (context) => const _AboutSheet(),
  );
}

class _AboutSheet extends StatelessWidget {
  const _AboutSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Palette.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Palette.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  SunMark(size: 30, color: Palette.clay),
                  SizedBox(width: 10),
                  Text(
                    'elsewhere.',
                    style: TextStyle(
                      fontFamily: AppText.serif,
                      fontSize: 30,
                      color: Palette.ink,
                      height: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'A field journal for slow places.',
                style: AppText.display(28, height: 1.05),
              ),
              const SizedBox(height: 12),
              Text(
                'Elsewhere is a small, offline travel journal. Eight places, five silent films, and a little room to keep the ones that stay with you. Every still was generated for this project; every word was written for it.',
                style: AppText.body(14, height: 1.6),
              ),
              const SizedBox(height: 24),
              const Hairline(),
              const SizedBox(height: 18),
              _line('ISSUE', '07 · October 2026'),
              _line('BUILT WITH', 'Flutter · Dart'),
              _line('TYPE', 'DM Serif Display / Figtree (OFL)'),
              _line('VERSION', '1.0.0'),
              const SizedBox(height: 22),
              Text(
                'Made for the quiet part of the journey.',
                style: AppText.serifItalic(
                  17,
                  color: Palette.inkSoft,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Palette.ink,
                    side: const BorderSide(color: Palette.line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(
                    'Close',
                    style: AppText.ui(13, weight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppText.label(9, color: Palette.inkFaint, tracking: 1.2),
            ),
          ),
          Expanded(child: Text(value, style: AppText.body(12.5, height: 1.3))),
        ],
      ),
    );
  }
}
