import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models.dart';

// Premium Visual Colors
class AppColors {
  // Dark Mode Static Constants (retaining names for backward compatibility)
  static const Color background = Color(0xFF0F172A); // Deep Slate Blue
  static const Color cardBg = Color(0xFF1E293B);      // Slate Card
  static const Color border = Color(0xFF334155);      // Slate Border
  static const Color textMuted = Color(0xFF94A3B8);   // Muted Grey
  
  // Light Mode Static Constants
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color cardBgLight = Colors.white;
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textMutedLight = Color(0xFF64748B);
  static const Color textMutedDark = Color(0xFF94A3B8);
  
  static const Color emerald = Color(0xFF10B981);     // Healthy/Income
  static const Color rose = Color(0xFFF43F5E);        // Alert/Expense
  static const Color violet = Color(0xFF8B5CF6);      // Premium/Portfolio
  static const Color amber = Color(0xFFF59E0B);       // Warning/Budget
  static const Color cyan = Color(0xFF06B6D4);        // Cash Wallet
  
  static Color getCategoryColor(String category, {List<AppCategory>? dynamicCategories}) {
    if (dynamicCategories != null) {
      final match = dynamicCategories.firstWhere(
        (c) => c.name.toLowerCase() == category.toLowerCase(),
        orElse: () => AppCategory(id: '', name: '', icon: '', colorValue: 0),
      );
      if (match.colorValue != 0) {
        return Color(match.colorValue);
      }
    }

    switch (category.toLowerCase()) {
      case 'food & drinks':
      case 'ăn uống / nhà hàng':
        return rose;
      case 'transportation':
      case 'di chuyển / đi lại':
        return violet;
      case 'bills & utilities':
      case 'hóa đơn & dịch vụ':
        return cyan;
      case 'shopping':
      case 'mua sắm cá nhân':
        return amber;
      case 'entertainment':
      case 'vui chơi & giải trí':
        return const Color(0xFF6366F1); // Indigo
      case 'salary income':
      case 'lương thu nhập':
      case 'invest dividends':
      case 'lợi tức đầu tư':
        return emerald;
      default:
        return textMuted;
    }
  }
}

// ==========================================
// 1. DYNAMIC GRADIENT PIE / ALLOCATION RING
// ==========================================

class AllocationRingChart extends StatelessWidget {
  final Map<String, double> data;
  final String centerText;
  final String centerSubtext;

  const AllocationRingChart({
    super.key,
    required this.data,
    required this.centerText,
    required this.centerSubtext,
  });

  @override
  Widget build(BuildContext context) {
    final double total = data.values.fold(0, (sum, val) => sum + val);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (total == 0) {
      return Center(
        child: Text(
          'No expenses recorded',
          style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 14),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _RingChartPainter(data: data, total: total, isDark: isDark),
              ),
              // Center Glassmorphic Text Label
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerText,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: size * 0.08,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    centerSubtext,
                    style: TextStyle(
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      fontSize: size * 0.045,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}

class _RingChartPainter extends CustomPainter {
  final Map<String, double> data;
  final double total;
  final bool isDark;

  _RingChartPainter({required this.data, required this.total, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = size.width * 0.12;
    final double radius = (size.width - strokeWidth) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -pi / 2;

    // Background track to look premium
    final Paint trackPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    data.forEach((category, amount) {
      if (amount <= 0) return;

      final double sweepAngle = (amount / total) * 2 * pi;
      final Color color = AppColors.getCategoryColor(category);

      // Glow paint
      final Paint glowPaint = Paint()
        ..color = color.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4
        ..strokeCap = StrokeCap.round
        ..imageFilter = ImageFilter.blur(sigmaX: 4, sigmaY: 4);

      // Main segment paint
      final Paint segmentPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Draw shadow glow then actual segment
      canvas.drawArc(rect, startAngle + 0.03, sweepAngle - 0.06, false, glowPaint);
      canvas.drawArc(rect, startAngle + 0.03, sweepAngle - 0.06, false, segmentPaint);

      startAngle += sweepAngle;
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==========================================
// 2. GLOWING BEZIER TREND AREA CHART
// ==========================================

class TrendPoint {
  final String label;
  final double income;
  final double expense;

  TrendPoint({required this.label, required this.income, required this.expense});
}

class TrendAreaChart extends StatelessWidget {
  final List<TrendPoint> points;

  const TrendAreaChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (points.isEmpty) {
      return Center(
        child: Text(
          'Insufficient data',
          style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _TrendChartPainter(points: points, isDark: isDark),
        );
      },
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<TrendPoint> points;
  final bool isDark;

  _TrendChartPainter({required this.points, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final double paddingLeft = size.width * 0.08;
    final double paddingRight = size.width * 0.04;
    final double paddingTop = size.height * 0.08;
    final double paddingBottom = size.height * 0.16;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    // Find Max Value
    double maxValue = 100.0; // Default baseline min height
    for (var p in points) {
      maxValue = max(maxValue, max(p.income, p.expense));
    }
    maxValue *= 1.15; // Give 15% breathing room at the top

    // Draw Gridlines and Labels
    final Paint gridPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)
      ..strokeWidth = 1.0;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw 3 horizontal gridlines
    for (int i = 0; i <= 3; i++) {
      final double y = paddingTop + (chartHeight * (3 - i) / 3);
      final double gridVal = maxValue * i / 3;

      // Draw gridline
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);

      // Y-Axis Labels
      textPainter.text = TextSpan(
        text: '\$${gridVal.toStringAsFixed(0)}',
        style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(paddingLeft - textPainter.width - 6, y - textPainter.height / 2));
    }

    final int len = points.length;
    if (len < 2) return;

    final double stepX = chartWidth / (len - 1);

    // Paths for Bezier Curves
    final Path incomePath = Path();
    final Path expensePath = Path();
    final Path incomeAreaPath = Path();
    final Path expenseAreaPath = Path();

    // Helper to get coordinates
    Offset getPointCoords(int index, double value) {
      final double x = paddingLeft + (index * stepX);
      final double y = paddingTop + chartHeight - (value / maxValue * chartHeight);
      return Offset(x, y);
    }

    // Generate Bezier Curves for Income & Expense
    for (int t = 0; t < 2; t++) {
      final bool isIncome = t == 0;
      final Path linePath = isIncome ? incomePath : expensePath;
      final Path areaPath = isIncome ? incomeAreaPath : expenseAreaPath;

      final List<Offset> coords = [];
      for (int i = 0; i < len; i++) {
        final val = isIncome ? points[i].income : points[i].expense;
        coords.add(getPointCoords(i, val));
      }

      // Start Line
      linePath.moveTo(coords[0].dx, coords[0].dy);
      areaPath.moveTo(coords[0].dx, paddingTop + chartHeight);
      areaPath.lineTo(coords[0].dx, coords[0].dy);

      for (int i = 0; i < len - 1; i++) {
        final Offset p0 = coords[i];
        final Offset p1 = coords[i + 1];

        // Beautiful cubic bezier control points
        final Offset cp1 = Offset(p0.dx + stepX / 2, p0.dy);
        final Offset cp2 = Offset(p1.dx - stepX / 2, p1.dy);

        linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
        areaPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
      }

      // Close Area Paths
      areaPath.lineTo(coords[len - 1].dx, paddingTop + chartHeight);
      areaPath.close();

      // Render Area Fill Gradients
      final Color baseColor = isIncome ? AppColors.emerald : AppColors.rose;
      final Paint fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            baseColor.withOpacity(isIncome ? 0.28 : 0.22),
            baseColor.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(paddingLeft, paddingTop, chartWidth, chartHeight));

      canvas.drawPath(areaPath, fillPaint);

      // Render glowing shadow behind the line
      final Paint glowPaint = Paint()
        ..color = baseColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..imageFilter = ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0);
      canvas.drawPath(linePath, glowPaint);

      // Render the actual foreground path
      final Paint strokePaint = Paint()
        ..color = baseColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(linePath, strokePaint);

      // Draw custom glowing endpoints
      for (int i = 0; i < len; i++) {
        final Offset dot = coords[i];
        canvas.drawCircle(dot, 6.0, Paint()..color = baseColor.withOpacity(0.2));
        canvas.drawCircle(dot, 3.5, Paint()..color = Colors.white);
        canvas.drawCircle(dot, 2.0, Paint()..color = baseColor);
      }
    }

    // X-Axis Labels (Timeline dates)
    for (int i = 0; i < len; i++) {
      final double x = paddingLeft + (i * stepX);
      textPainter.text = TextSpan(
        text: points[i].label,
        style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, paddingTop + chartHeight + 10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
