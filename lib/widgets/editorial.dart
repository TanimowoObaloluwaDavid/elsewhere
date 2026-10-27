import 'package:flutter/material.dart';

import '../core/palette.dart';
import '../core/text_styles.dart';

class Kicker extends StatelessWidget {
  const Kicker(this.text, {super.key, this.color, this.line = true});

  final String text;
  final Color? color;
  final bool line;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (line) ...[
          Container(
            width: 22,
            height: 1,
            color: (color ?? Palette.inkSoft).withValues(alpha: 0.55),
          ),
          const SizedBox(width: 10),
        ],
        Text(
          text.toUpperCase(),
          style: AppText.label(
            10.5,
            color: color ?? Palette.inkSoft,
            tracking: 1.8,
          ),
        ),
      ],
    );
  }
}

class Hairline extends StatelessWidget {
  const Hairline({super.key, this.color, this.indent = 0, this.endIndent = 0});

  final Color? color;
  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent, right: endIndent),
      child: Container(height: 1, color: color ?? Palette.line),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.padding = EdgeInsets.zero,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(title, style: AppText.display(26, height: 1.05)),
          ),
          if (action != null)
            if (onAction == null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 10,
                ),
                child: Text(
                  action!.toUpperCase(),
                  style: AppText.label(
                    10,
                    color: Palette.inkFaint,
                    tracking: 1.5,
                  ),
                ),
              )
            else
              InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        action!.toUpperCase(),
                        style: AppText.label(
                          10,
                          color: Palette.clay,
                          tracking: 1.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Palette.clay,
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.background,
    this.foreground,
    this.size = 44,
    this.iconSize = 20,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? background;
  final Color? foreground;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: background ?? Palette.paperBright.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: iconSize, color: foreground ?? Palette.ink),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.color, this.background, this.border});

  final String text;
  final Color? color;
  final Color? background;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background ?? Palette.ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(30),
        border: border == null ? null : Border.all(color: border!, width: 0.7),
      ),
      child: Text(
        text.toUpperCase(),
        style: AppText.label(9, color: color ?? Palette.inkSoft, tracking: 1.3),
      ),
    );
  }
}

class AssetPhoto extends StatelessWidget {
  const AssetPhoto({
    super.key,
    required this.asset,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  final String asset;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.medium,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) => const ColoredBox(
        color: Palette.paperWarm,
        child: Center(
          child: Icon(Icons.landscape_outlined, color: Palette.inkFaint),
        ),
      ),
    );
  }
}

class PhotoScrim extends StatelessWidget {
  const PhotoScrim({super.key, this.top = 0.2, this.bottom = 0.95});

  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Palette.ink.withValues(alpha: top * 0.55),
            Palette.ink.withValues(alpha: 0.0),
            Palette.ink.withValues(alpha: bottom),
          ],
          stops: const [0.0, 0.42, 1.0],
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.expanded = true,
    this.background,
    this.foreground,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool expanded;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: expanded ? double.infinity : null,
      height: 56,
      child: Material(
        color: background ?? Palette.ink,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: foreground ?? Palette.cream),
                  const SizedBox(width: 10),
                ],
                Text(
                  label,
                  style: AppText.ui(
                    14,
                    color: foreground ?? Palette.cream,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
