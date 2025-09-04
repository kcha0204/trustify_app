import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VcamsRow {
  final String state;
  final String indicator;
  final String subtype;
  final String subval;
  final int year;
  final double value; // 0..1

  VcamsRow({
    required this.state,
    required this.indicator,
    required this.subtype,
    required this.subval,
    required this.year,
    required this.value,
  });

  factory VcamsRow.fromJson(Map<String, dynamic> j) =>
      VcamsRow(
        state: (j['state'] ?? '') as String,
        indicator: (j['indicator'] ?? '') as String,
        subtype: (j['subdivision_type'] ?? '') as String,
        subval: (j['subdivision_value'] ?? '') as String,
        year: int.parse(j['year'].toString()),
        value: (j['value'] as num).toDouble(), // assume 0..1 in DB
      );
}

class CyberTrendsPage extends StatefulWidget {
  const CyberTrendsPage({super.key});

  @override
  State<CyberTrendsPage> createState() => _CyberTrendsPageState();
}

class _CyberTrendsPageState extends State<CyberTrendsPage> {
  late final SupabaseClient sb;

  String? indicator;
  String? subtype;
  bool asPercent = true;
  final Set<String> selectedValues = {}; // Subdivision values
  final Set<int> selectedYears = {}; // e.g., {2014,2016,2018}

  @override
  void initState() {
    super.initState();
    // Make sure .env is loaded in main.dart and re-use keys
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    sb = SupabaseClient(url, key);
  }

  Future<List<String>> _distinct(String column) async {
    final res = await sb.from('vcams_long').select(column).limit(1000);
    final list = (res as List)
        .map((e) => (e[column] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return list;
  }

  Future<List<String>> _subtypesForIndicator(String ind) async {
    final res = await sb
        .from('vcams_long')
        .select('subdivision_type')
        .eq('indicator', ind)
        .limit(1000);
    final list = (res as List)
        .map((e) => e['subdivision_type'].toString())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return list;
  }

  List<String> _naturalYearSort(List<String> vals) {
    int tail(String s) {
      final m = RegExp(r'(\d+)').firstMatch(s);
      return m != null ? int.parse(m.group(1)!) : 1 << 30;
    }
    vals.sort((a, b) => tail(a).compareTo(tail(b)));
    return vals;
  }

  Future<List<String>> _valuesFor(String ind, String stype) async {
    final res = await sb
        .from('vcams_long')
        .select('subdivision_value')
        .eq('indicator', ind)
        .eq('subdivision_type', stype)
        .limit(5000);
    final list = (res as List).map((e) => e['subdivision_value'].toString())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    if (stype == 'Year level') return _naturalYearSort(list);
    list.sort();
    return list;
  }

  Future<List<int>> _yearsFor(String ind, {required String stype}) async {
    final res = await sb
        .from('vcams_long')
        .select('year')
        .eq('indicator', ind)
        .eq('subdivision_type', stype)
        .limit(100);
    final ys = (res as List)
        .map((e) => int.parse(e['year'].toString()))
        .toSet()
        .toList()
      ..sort();
    return ys;
  }

  Future<List<VcamsRow>> _fetchData({
    required String ind,
    required String stype,
    required List<String> subvals,
    required List<int> years,
  }) async {
    final q = sb
        .from('vcams_long')
        .select('state,indicator,subdivision_type,subdivision_value,year,value')
        .eq('indicator', ind)
        .eq('subdivision_type', stype)
        .inFilter('subdivision_value', subvals)
        .inFilter('year', years)
        .order('year', ascending: true)
        .limit(5000);
    final res = await q;
    return (res as List)
        .map((e) => VcamsRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Widget _buildBlurredBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/splash/cyberbullying_social_bg.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E3A8A),
                    Color(0xFFEC4899),
                    Color(0xFF10B981),
                    Color(0xFFFF3366),
                  ],
                ),
              ),
            );
          },
        ),
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        _distinct('indicator'),
        _yearsFor(indicator ?? '', stype: subtype ?? ''),
      ]),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(
            body: Stack(
              children: [
                _buildBlurredBackground(),
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF00FF88)),
                      SizedBox(height: 16),
                      Text('Loading Victorian Cyber Data...',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        final indicators = (snap.data![0] as List<String>);
        final years = (snap.data![1] as List<int>);
        indicator ??= indicators.isNotEmpty ? indicators.first : null;

        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          body: Stack(
            fit: StackFit.expand,
            children: [
              _buildBlurredBackground(),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                                Icons.arrow_back, color: Colors.white,
                                size: 28),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                    color: const Color(0xFF00FF88), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00FF88).withOpacity(
                                        0.3),
                                    blurRadius: 16,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                      colors: [
                                        Color(0xFF00FF88),
                                        Color(0xFF00D4FF),
                                        Color(0xFFFF3366),
                                        Color(0xFFFFDD00)
                                      ],
                                    ).createShader(bounds),
                                child: const Text(
                                  'VICTORIA CYBER INTEL',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Settings
                      Row(
                        children: [
                          const Text('Indicator:', style: TextStyle(
                              color: Colors.white)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButton<String>(
                                value: indicator,
                                dropdownColor: Colors.grey[800],
                                style: const TextStyle(color: Colors.white),
                                underline: Container(),
                                isExpanded: true,
                                items: indicators.map((e) =>
                                    DropdownMenuItem(
                                      value: e,
                                      child: Text(e,
                                          style: const TextStyle(fontSize: 12)),
                                    )).toList(),
                                onChanged: (v) =>
                                    setState(() {
                                      indicator = v;
                                      subtype = null;
                                      selectedValues.clear();
                                      selectedYears.clear();
                                    }),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              const Text('Percent',
                                  style: TextStyle(color: Colors.white)),
                              Switch(
                                  value: asPercent,
                                  activeColor: const Color(0xFF00FF88),
                                  onChanged: (v) =>
                                      setState(() => asPercent = v)
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (indicator != null)
                        FutureBuilder(
                          future: _subtypesForIndicator(indicator!),
                          builder: (context, s2) {
                            if (!s2.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator(
                                      color: Color(0xFF00FF88))
                              );
                            }
                            final subtypes = s2.data as List<String>;
                            subtype ??=
                            subtypes.isNotEmpty ? subtypes.first : null;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('Type:',
                                        style: TextStyle(color: Colors.white)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: DropdownButton<String>(
                                        value: subtype,
                                        dropdownColor: Colors.grey[800],
                                        style: const TextStyle(
                                            color: Colors.white),
                                        underline: Container(),
                                        items: subtypes.map((e) =>
                                            DropdownMenuItem(
                                              value: e,
                                              child: Text(e),
                                            )).toList(),
                                        onChanged: (v) {
                                          setState(() {
                                            subtype = v;
                                            selectedValues.clear();
                                            selectedYears.clear();
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                if (subtype != null)
                                  FutureBuilder(
                                    future: _valuesFor(indicator!, subtype!),
                                    builder: (context, s3) {
                                      if (!s3.hasData) {
                                        return const SizedBox(height: 80,
                                            child: Center(
                                                child: CircularProgressIndicator()));
                                      }
                                      final vals = s3.data as List<String>;
                                      if (selectedValues.isEmpty &&
                                          vals.isNotEmpty) {
                                        selectedValues.addAll(vals.take(5));
                                      }
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment
                                            .start,
                                        children: [
                                          const Text('Values:',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          const SizedBox(height: 10),
                                          Scrollbar(
                                            thumbVisibility: true,
                                            child: SizedBox(
                                              height: min(190, 36.0 *
                                                  (vals.length / 2).ceil() +
                                                  20),
                                              child: SingleChildScrollView(
                                                child: Wrap(
                                                  spacing: 8,
                                                  runSpacing: 10,
                                                  children: vals.map((v) {
                                                    final on = selectedValues
                                                        .contains(v);
                                                    return FilterChip(
                                                      label: Text(
                                                          v, style: TextStyle(
                                                        color: on
                                                            ? Colors.black
                                                            : Colors.white,
                                                        fontSize: 13,
                                                      )),
                                                      selected: on,
                                                      selectedColor: const Color(
                                                          0xFF00FF88),
                                                      backgroundColor: Colors
                                                          .grey.withOpacity(
                                                          0.3),
                                                      onSelected: (_) =>
                                                          setState(() {
                                                            on
                                                                ? selectedValues
                                                                .remove(v)
                                                                : selectedValues
                                                                .add(v);
                                                          }),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 18),
                                          const Text('Years:', style: TextStyle(
                                              color: Colors.white)),
                                          const SizedBox(height: 8),
                                          FutureBuilder(
                                            future: _yearsFor(
                                                indicator!, stype: subtype!),
                                            builder: (context, sYears) {
                                              if (!sYears.hasData) {
                                                return const SizedBox(
                                                    height: 40,
                                                    child: Center(
                                                        child:
                                                        CircularProgressIndicator()));
                                              }
                                              final years = sYears.data as List<
                                                  int>;
                                              if (selectedYears.isEmpty &&
                                                  years.isNotEmpty) {
                                                selectedYears.addAll(years);
                                              }
                                              selectedYears.removeWhere((
                                                  y) => !years.contains(y));
                                              return Column(
                                                crossAxisAlignment: CrossAxisAlignment
                                                    .start,
                                                children: [
                                                  Wrap(
                                                    spacing: 6,
                                                    children: years.map((y) {
                                                      final on = selectedYears
                                                          .contains(y);
                                                      return FilterChip(
                                                        label: Text('$y'),
                                                        selected: on,
                                                        onSelected: (_) =>
                                                            setState(() {
                                                              if (selectedYears
                                                                  .length ==
                                                                  1 && on)
                                                                return; // at least one year
                                                              on
                                                                  ? selectedYears
                                                                  .remove(y)
                                                                  : selectedYears
                                                                  .add(y);
                                                            }),
                                                      );
                                                    }).toList(),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  _ChartsBlock(
                                                    sb: sb,
                                                    indicator: indicator!,
                                                    subtype: subtype!,
                                                    selectedValues: selectedValues
                                                        .toList(),
                                                    yearsForPlot: selectedYears
                                                        .isEmpty
                                                        ? years
                                                        : selectedYears
                                                        .toList(),
                                                    asPercent: asPercent,
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                              ],
                            );
                          },
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: MediaQuery
                            .of(context)
                            .size
                            .height * 0.65,
                        child: (indicator == null || subtype == null ||
                            selectedValues.isEmpty)
                            ? const Center(child: Text(
                            'Select indicator, type, and at least one value.',
                            style: TextStyle(color: Colors.white70)))
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChartsBlock extends StatelessWidget {
  const _ChartsBlock({
    required this.sb,
    required this.indicator,
    required this.subtype,
    required this.selectedValues,
    required this.yearsForPlot,
    required this.asPercent,
  });

  final SupabaseClient sb;
  final String indicator;
  final String subtype;
  final List<String> selectedValues;
  final List<int> yearsForPlot;
  final bool asPercent;

  Future<List<VcamsRow>> _fetch(
      {required List<String> subvals, required List<int> years}) async {
    final q = sb
        .from('vcams_long')
        .select('state,indicator,subdivision_type,subdivision_value,year,value')
        .eq('indicator', indicator)
        .eq('subdivision_type', subtype)
        .inFilter('subdivision_value', subvals)
        .inFilter('year', years)
        .order('year', ascending: true)
        .limit(5000);
    final res = await q;
    return (res as List)
        .map((e) => VcamsRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (selectedValues.isEmpty || yearsForPlot.isEmpty) {
      return const SizedBox.shrink();
    }
    return FutureBuilder(
      future: _fetch(subvals: selectedValues, years: yearsForPlot),
      builder: (context, s4) {
        if (!s4.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = s4.data as List<VcamsRow>;
        if (rows.isEmpty) {
          return const Center(child: Text('No data for selection'));
        }
        final bySub = <String, List<VcamsRow>>{};
        for (final r in rows) {
          (bySub[r.subval] ??= []).add(r);
        }
        final xYears = yearsForPlot;
        final minYear = xYears.first.toDouble();
        final maxYear = xYears.last.toDouble();
        final series = bySub.entries.map((e) {
          final pts = e.value..sort((a, b) => a.year.compareTo(b.year));
          return LineChartBarData(
            isCurved: false,
            barWidth: 2,
            dotData: FlDotData(show: true),
            spots: pts.map((r) {
              final y = asPercent ? r.value * 100.0 : r.value;
              return FlSpot(r.year.toDouble(), y);
            }).toList(),
          );
        }).toList();
        final latestY = xYears.last;
        final latestRows = rows.where((r) => r.year == latestY).toList()
          ..sort((a, b) => a.value.compareTo(b.value));
        final barY = latestRows.map((r) =>
        asPercent ? r.value * 100.0 : r.value).toList();
        final barCats = latestRows.map((r) => r.subval).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trend over years', style: TextStyle(fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 260,
              child: LineChart(LineChartData(
                minY: 0,
                minX: minYear,
                maxX: maxYear,
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      getTitlesWidget: (v, _) =>
                          Text(v.toInt().toString(), style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (v, _) =>
                          Text(v.toStringAsFixed(1),
                              style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                      reservedSize: 38,
                      getTitlesWidget: (v, _) =>
                      const Text('', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                      reservedSize: 38,
                      getTitlesWidget: (v, _) =>
                      const Text('', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
                lineBarsData: series,
              )),
            ),
            const SizedBox(height: 16),
            Text('Current Situation ($latestY)', style: TextStyle(fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: max(200, 24.0 * barCats.length),
              child: BarChart(BarChartData(
                barGroups: [
                  for (int i = 0; i < barCats.length; i++)
                    BarChartGroupData(
                        x: i, barRods: [BarChartRodData(toY: barY[i])]),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                      reservedSize: 38,
                      getTitlesWidget: (v, _) =>
                      const Text('', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (v, _) =>
                          Text(v.toStringAsFixed(1),
                              style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                      reservedSize: 38,
                      getTitlesWidget: (v, _) =>
                      const Text('', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                      reservedSize: 38,
                      getTitlesWidget: (v, _) =>
                      const Text('', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              )),
            ),
          ],
        );
      },
    );
  }
}