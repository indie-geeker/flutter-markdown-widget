// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class OptionSwitchTile extends StatelessWidget {
  const OptionSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final subtitleStyle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: icon != null
          ? Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary)
          : null,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle!, style: subtitleStyle) : null,
      trailing: Switch.adaptive(value: value, onChanged: onChanged),
    );
  }
}

class OptionSliderTile extends StatelessWidget {
  const OptionSliderTile({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.trailingLabel,
  });

  final String title;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final label = trailingLabel ?? value.toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
