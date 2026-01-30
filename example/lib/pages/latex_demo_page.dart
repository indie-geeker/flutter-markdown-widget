// Copyright 2026 The Flutter Markdown Widget Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_widget/flutter_markdown_widget.dart';

class LatexDemoPage extends StatelessWidget {
  const LatexDemoPage({super.key});

  static const _content = r'''
# 🧮 LaTeX Mathematics Demo

This page showcases the beautiful mathematical rendering capabilities of the library.

---

## Inline Math

Einstein's famous mass-energy equivalence: $E = mc^2$

The quadratic formula: $x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}$

Standard deviation in statistics: $\sigma = \sqrt{\frac{1}{N}\sum_{i=1}^{N}(x_i - \mu)^2}$

---

## Block Equations

### The Gaussian Integral

One of the most beautiful integrals in mathematics:

$$
\int_{-\infty}^{\infty} e^{-x^2} dx = \sqrt{\pi}
$$

### Taylor Series Expansion

The exponential function can be expressed as an infinite series:

$$
e^x = \sum_{n=0}^{\infty} \frac{x^n}{n!} = 1 + x + \frac{x^2}{2!} + \frac{x^3}{3!} + \cdots
$$

### Maxwell's Equations

The fundamental equations of electromagnetism:

$$
\nabla \times \mathbf{E} = -\frac{\partial \mathbf{B}}{\partial t}
$$

$$
\nabla \times \mathbf{B} = \mu_0 \mathbf{J} + \mu_0 \varepsilon_0 \frac{\partial \mathbf{E}}{\partial t}
$$

### Matrix Operations

Matrix multiplication visualized:

$$
\begin{pmatrix}
a & b \\
c & d
\end{pmatrix}
\begin{pmatrix}
x \\
y
\end{pmatrix}
=
\begin{pmatrix}
ax + by \\
cx + dy
\end{pmatrix}
$$

### Schrödinger Equation

The foundation of quantum mechanics:

$$
i\hbar\frac{\partial}{\partial t}\Psi(\mathbf{r},t) = \hat{H}\Psi(\mathbf{r},t)
$$

---

## Combined Content

In physics, we often use inline equations like $F = ma$ (Newton's second law) alongside more complex block equations:

$$
W = \int_C \mathbf{F} \cdot d\mathbf{r}
$$

This demonstrates how inline and block math coexist naturally in scientific documents.

---

*Beautiful math rendering powered by flutter_math_fork* ✨
''';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.functions_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Text('LaTeX Math'),
          ],
        ),
        centerTitle: true,
      ),
      body: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: StreamingMarkdownView(
            content: _content,
            padding: const EdgeInsets.all(28),
            theme: MarkdownTheme(
              textStyle: TextStyle(
                fontSize: 15,
                height: 1.8,
                color: isDark ? Colors.grey[300] : Colors.grey[800],
              ),
              headingSpacing: 32,
              blockSpacing: 20,
              codeBlockBackground: isDark 
                  ? const Color(0xFF0F172A) 
                  : const Color(0xFFFEF3C7),
              codeBlockBorderRadius: BorderRadius.circular(16),
              blockquoteBorderColor: const Color(0xFFF59E0B),
              blockquoteBackground: isDark
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
                  : const Color(0xFFFEF3C7),
            ),
            renderOptions: const RenderOptions(
              enableLatex: true,
              selectableText: true,
            ),
          ),
        ),
      ),
    );
  }
}
