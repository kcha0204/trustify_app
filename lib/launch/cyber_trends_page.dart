import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/vcams_api.dart';

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

class _CyberTrendsPageState extends State<CyberTrendsPage>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _sparkleController;
  final VcamsApi _api = VcamsApi();

  // State variables
  List<String> _indicators = [];
  List<String> _subdivisionTypes = [];
  List<String> _subdivisionValues = [];
  List<int> _years = [2014, 2016, 2018];

  String _selectedIndicator = 'Cyber bullying';
  String _selectedSubdivisionType = 'Year level';
  List<String> _selectedSubdivisionValues = [];
  List<int> _selectedYears = [2018];

  List<SeriesData> _kpiSeriesData = [];
  List<SeriesData> _trendData = [];
  List<VcamsData> _breakdownData = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
        duration: const Duration(milliseconds: 3200), vsync: this)
      ..repeat();
    _initializeData();
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load indicators first
      final indicators = await _api.getIndicators();
      setState(() {
        _indicators = indicators;
        if (_indicators.isNotEmpty &&
            !_indicators.contains(_selectedIndicator)) {
          _selectedIndicator = _indicators.first;
        }
      });

      // Load subdivision types for the selected indicator
      await _loadSubdivisionTypes();
      await _loadData();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load dashboard data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSubdivisionTypes() async {
    try {
      final types = await _api.getSubdivisionTypes(_selectedIndicator);
      setState(() {
        _subdivisionTypes = types;
        if (_subdivisionTypes.isNotEmpty &&
            !_subdivisionTypes.contains(_selectedSubdivisionType)) {
          _selectedSubdivisionType = _subdivisionTypes.first;
        }
      });
      await _loadSubdivisionValues();
    } catch (e) {
      print('Error loading subdivision types: $e');
    }
  }

  Future<void> _loadSubdivisionValues() async {
    try {
      final values = await _api.getSubdivisionValues(
          _selectedIndicator, _selectedSubdivisionType);
      setState(() {
        _subdivisionValues = values;
        _selectedSubdivisionValues = []; // Reset selection
      });
    } catch (e) {
      print('Error loading subdivision values: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load KPI series data
      final kpiSeries = await _api.getSeriesData(
        _selectedIndicator,
        _selectedSubdivisionType,
        values: _selectedSubdivisionValues.isEmpty
            ? null
            : _selectedSubdivisionValues,
      );

      // Load trend data (always statewide)
      final trendData = await _api.getStatewideTrend(_selectedIndicator);

      // Load breakdown data for the latest selected year
      final latestYear = _selectedYears.isEmpty ? 2018 : _selectedYears.last;
      final breakdownData = await _api.getBreakdownData(
        _selectedIndicator,
        _selectedSubdivisionType,
        latestYear,
        values: _selectedSubdivisionValues.isEmpty
            ? null
            : _selectedSubdivisionValues,
      );

      setState(() {
        _kpiSeriesData = kpiSeries;
        _trendData = trendData;
        _breakdownData = breakdownData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildBlurredBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/aftersplash/after_splash_bg.jpeg',
          fit: BoxFit.cover,
        ),
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.22),
                      Colors.black.withOpacity(0.39),
                      Colors.black.withOpacity(0.63),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SparkleOverlayContent(sparkleController: _sparkleController)
      ],
    );
  }

  Widget _buildDropdowns() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981), width: 2),
      ),
      child: Column(
        children: [
          // Indicator dropdown
          _buildDropdown(
            'Indicator',
            _selectedIndicator,
            _indicators,
                (value) async {
              setState(() {
                _selectedIndicator = value!;
              });
              await _loadSubdivisionTypes();
              await _loadData();
            },
          ),
          const SizedBox(height: 12),

          // Subdivision Type dropdown
          _buildDropdown(
            'Subdivision Type',
            _selectedSubdivisionType,
            _subdivisionTypes,
                (value) async {
              setState(() {
                _selectedSubdivisionType = value!;
              });
              await _loadSubdivisionValues();
              await _loadData();
            },
          ),
          const SizedBox(height: 12),

          // Subdivision Values multi-select
          if (_subdivisionValues.isNotEmpty) ...[
            Text(
              'Subdivision Values (optional)',
              style: TextStyle(
                color: const Color(0xFF10B981),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _subdivisionValues.map((value) {
                final isSelected = _selectedSubdivisionValues.contains(value);
                return FilterChip(
                  label: Text(value),
                  selected: isSelected,
                  onSelected: (selected) async {
                    setState(() {
                      if (selected) {
                        _selectedSubdivisionValues.add(value);
                      } else {
                        _selectedSubdivisionValues.remove(value);
                      }
                    });
                    await _loadData();
                  },
                  selectedColor: const Color(0xFF10B981),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF10B981),
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Year selection
          Text(
            'Years',
            style: TextStyle(
              color: const Color(0xFF10B981),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _years.map((year) {
              final isSelected = _selectedYears.contains(year);
              return FilterChip(
                label: Text(year.toString()),
                selected: isSelected,
                onSelected: (selected) async {
                  setState(() {
                    if (selected) {
                      _selectedYears.add(year);
                    } else {
                      _selectedYears.remove(year);
                    }
                  });
                  await _loadData();
                },
                selectedColor: const Color(0xFF176CB8),
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF176CB8),
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF10B981),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: Colors.black.withOpacity(0.9),
              style: const TextStyle(color: Colors.white),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendAnalysisBox() {
    if (_trendData.isEmpty) return SizedBox.shrink();
    final indicator = _selectedIndicator;
    final yearList = _selectedYears.isEmpty ? [2018] : _selectedYears;
    final yearsText = yearList.length == 1
        ? 'the year ${yearList.first}'
        : 'the years ${yearList.join(", ")}';
    final subdivisionType = _selectedSubdivisionType;
    final valuesSelected = _selectedSubdivisionValues;
    String filterText = '';
    if (subdivisionType == 'All of state' || valuesSelected.isEmpty) {
      filterText = '';
    } else {
      final groupLabel = valuesSelected.length == 1
          ? valuesSelected[0].toLowerCase()
          : valuesSelected.take(3).map((v) => v.toLowerCase()).join(", ") +
          (valuesSelected.length > 3 ? ', ...' : '');
      filterText = 'of the $groupLabel population ';
    }
    double avg = 0;
    List<double> values = [];
    for (var y in yearList) {
      final found = _trendData.where((e) => e.year == y).toList();
      if (found.isNotEmpty) values.add(found.first.value);
    }
    if (values.isNotEmpty) {
      avg = values.reduce((a, b) => a + b) / values.length;
    }
    final percentText = avg > 0 ? '${(avg * 100).toStringAsFixed(1)}%' : '';
    final indicatorSimple = indicator == 'Electronic media >= 2'
        ? 'spent 2+ hours daily on electronic media'
        : indicator.toLowerCase();

    String message = '';
    if (indicator == 'Electronic media >= 2') {
      message =
      "Hey! $percentText $filterText used mobile devices or social media for 2+ hours a day in $yearsText.";
    } else if (indicator.toLowerCase().contains('bullying') &&
        indicator != 'Cyber bullying') {
      message =
      "Remember, $percentText $filterText experienced ${indicatorSimple
          .replaceAll('bullying', 'bullying (all types)')} in $yearsText.";
    } else if (indicator == 'Cyber bullying') {
      message =
      "Heads up! $percentText $filterText experienced cyberbullying in $yearsText.";
    } else {
      message =
      'Heads up! About $percentText $filterText were $indicatorSimple$filterText in $yearsText.';
    }

    if (valuesSelected.length > 1) {
      message = message.replaceAll('population', 'groups');
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF283463).withOpacity(0.86),
        border: Border.all(
            color: const Color(0xFF10B981).withOpacity(0.43), width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.18),
            blurRadius: 18,
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.info, color: const Color(0xFF10B981), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13.4,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownAnalysisBox() {
    if (_breakdownData.isEmpty) return SizedBox.shrink();
    final indicator = _selectedIndicator;
    final year = _selectedYears.isEmpty ? 2018 : _selectedYears.last;
    final subdivisionType = _selectedSubdivisionType;
    String groupSummary = '';
    if (_subdivisionValues.isNotEmpty &&
        _selectedSubdivisionValues.isNotEmpty) {
      groupSummary = ' for ${_selectedSubdivisionValues.take(3).join(
          ", ")}${_selectedSubdivisionValues.length > 3 ? ', ...' : ''}';
    }
    String message = "Here's how different groups compare for $indicator in $year.";
    if (_breakdownData.isNotEmpty) {
      final top = _breakdownData.first;
      final bot = _breakdownData.last;
      final topName = top.subdivisionValue;
      final botName = bot.subdivisionValue;
      final topPct = (top.value * 100).toStringAsFixed(1);
      final botPct = (bot.value * 100).toStringAsFixed(1);
      message =
      "In $year, $topName had the highest rate of ${indicator
          .toLowerCase()} ($topPct%) while $botName had the lowest ($botPct%)$groupSummary.";
      if (_breakdownData.length == 1) {
        message =
        "Breakdown for $indicator$groupSummary in $year: $topName was at $topPct%.";
      } else if (top.value > 0.3) {
        message =
        "Alert: In $year, $topName stood out in ${indicator
            .toLowerCase()} ($topPct%)$groupSummary.";
      } else if (bot.value < 0.10) {
        message =
        "Good job! In $year, only $botPct% of $botName were affected by ${indicator
            .toLowerCase()}$groupSummary.";
      }
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF302a49).withOpacity(0.91),
        border: Border.all(
            color: const Color(0xFFF3B11E).withOpacity(0.3), width: 1.2),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF3B11E).withOpacity(0.09),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.monitor_heart, color: const Color(0xFFF3B11E), size: 20),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13.2,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendAxisLabelBox() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF20363e).withOpacity(0.85),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.label_important, color: Color(0xFF10B981), size: 17),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'X: Year          Y: Proportion of Young People (%)',
              style: const TextStyle(color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownLegendBox() {
    if (_breakdownData.isEmpty) return SizedBox.shrink();
    bool isPie = _breakdownData.length <= 5;
    final type = _selectedSubdivisionType;
    // match colours to bar/pie for legend
    final List<Color> pieColors = [
      const Color(0xFF10B981),
      const Color(0xFF176CB8),
      const Color(0xFFF3B11E),
      const Color(0xFFE18616),
      const Color(0xFF8B5CF6),
    ];
    final barGradient = [const Color(0xFFF3B11E), const Color(0xFFE18616)];

    // Compose legend items
    List<Widget> legendItems = [];
    for (int i = 0; i < _breakdownData.length; i++) {
      final group = _breakdownData[i].subdivisionValue;
      Color color;
      if (isPie) {
        color = pieColors[i % pieColors.length];
      } else {
        // Use mid of vertical gradient for bar color display
        color = Color.lerp(barGradient[0], barGradient[1], 0.6)!;
      }
      legendItems.add(Padding(
        padding: const EdgeInsets.only(right: 13, bottom: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white24, width: 1),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              group,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.7,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ));
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF41365d).withOpacity(0.82),
        border: Border.all(color: const Color(0xFFF3B11E).withOpacity(0.22)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: legendItems,
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    if (_trendData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.all(16),
          height: 250,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF10B981), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Statewide Trend',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${(value * 100).toInt()}%',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _trendData
                            .map((data) =>
                            FlSpot(data.year.toDouble(), data.value))
                            .toList(),
                        isCurved: true,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF176CB8)],
                        ),
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: _selectedYears.contains(spot.x.toInt())
                                  ? const Color(0xFFF3B11E)
                                  : const Color(0xFF10B981),
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF10B981).withOpacity(0.3),
                              const Color(0xFF176CB8).withOpacity(0.1),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildTrendAxisLabelBox(),
        _buildTrendAnalysisBox(),
      ],
    );
  }

  Widget _buildBreakdownChart() {
    if (_breakdownData.isEmpty) {
      return const SizedBox.shrink();
    }

    // Compute dynamic height based on label/text length and bar count
    final int barCount = _breakdownData.length;
    // If there are long subdivision values, bump up height
    final bool hasLongLabels = _breakdownData.any(
          (d) => d.subdivisionValue.length > 14,
    );
    final double chartHeight = barCount > 12
        ? 420
        : hasLongLabels
        ? 390
        : 320;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.all(16),
          height: chartHeight,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF176CB8), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Breakdown (${_selectedYears.isEmpty ? 2018 : _selectedYears
                    .last})',
                style: const TextStyle(
                  color: Color(0xFF176CB8),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _breakdownData.length <= 5
                    ? _buildPieChart()
                    : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _breakdownData.map((d) => d.value).reduce(max) * 1.2,
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: hasLongLabels ? 50 : 40,
                          getTitlesWidget: (value, meta) {
                            // Slant if labels are long or too many bars
                            if (value.toInt() < _breakdownData.length) {
                              return Transform.rotate(
                                angle: -0.7, // ~ -40deg
                                child: SizedBox(
                                  width: hasLongLabels ? 54 : 40,
                                  child: Text(
                                    _breakdownData[value.toInt()]
                                        .subdivisionValue,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${(value * 100).toInt()}%',
                              style: const TextStyle(
                                  color: Colors.orangeAccent, fontSize: 10),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: _breakdownData
                        .asMap()
                        .entries
                        .map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.value,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF3B11E), Color(0xFFE18616)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            width: 16,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildBreakdownLegendBox(),
        _buildBreakdownAnalysisBox(),
      ],
    );
  }

  Widget _buildPieChart() {
    final colors = [
      const Color(0xFF10B981),
      const Color(0xFF176CB8),
      const Color(0xFFF3B11E),
      const Color(0xFFE18616),
      const Color(0xFF8B5CF6),
    ];

    return PieChart(
      PieChartData(
        sections: _breakdownData
            .asMap()
            .entries
            .map((entry) {
          final index = entry.key;
          final data = entry.value;
          return PieChartSectionData(
            color: colors[index % colors.length],
            value: data.value,
            title: '${(data.value * 100).toStringAsFixed(1)}%',
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF10B981), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading Dashboard Data...',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(preferredSize: Size.zero, child: Container()),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBlurredBackground(),
          SafeArea(
            child: Column(
              children: [
                // Header with back button
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 18, 0, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 9, top: 7),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF127C82),
                            size: 27,
                          ),
                          splashRadius: 26,
                          onPressed: () {
                            _audioPlayer.play(AssetSource('sounds/tap.wav'));
                            Navigator.of(context).pop();
                          },
                          tooltip: 'Back',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 1,
                            minHeight: 1,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(0, 12, 16, 0),
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            border: Border.all(
                              color: const Color(0xFF10B981),
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.5),
                                blurRadius: 28,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ShaderMask(
                                shaderCallback: (Rect bounds) =>
                                    const LinearGradient(
                                  colors: [
                                    Color(0xFF10B981),
                                    Color(0xFF176CB8),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ).createShader(bounds),
                                child: const Text(
                                  "STAY AHEAD OF THE GAME",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22.5,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                    height: 1.2,
                                    shadows: [
                                      Shadow(
                                        color: Color(0xFF10B981),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ShaderMask(
                                shaderCallback: (Rect bounds) =>
                                    const LinearGradient(
                                      colors: [
                                        Color(0xFF176CB8),
                                        Color(0xFF10B981),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ).createShader(bounds),
                                child: const Text(
                                  "Know the Trends, Dodge the Drama! 🛡️✨",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: Colors.white,
                                    letterSpacing: 0.65,
                                    shadows: [
                                      Shadow(
                                        color: Color(0xFF176CB8),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main content
                Expanded(
                  child: _isLoading
                      ? _buildLoadingWidget()
                      : _errorMessage != null
                      ? _buildErrorWidget()
                      : SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      children: [
                        _buildDropdowns(),
                        _buildTrendChart(),
                        const SizedBox(height: 16),
                        _buildBreakdownChart(),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SparkleOverlayContent extends StatelessWidget {
  final AnimationController sparkleController;

  const SparkleOverlayContent({Key? key, required this.sparkleController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sparkleAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: sparkleController, curve: Curves.linear));
    return AnimatedBuilder(
      animation: sparkleAnimation,
      builder: (context, _) {
        return Stack(
          children: List.generate(15, (index) {
            final offset = (sparkleAnimation.value * 2 * 3.14159 +
                index * 0.4) % (2 * 3.14159);
            final screenH = MediaQuery
                .of(context)
                .size
                .height;
            return Positioned(
              left: 50 + (index % 5) * 70.0 + 20 * sin(offset),
              top: ((sparkleAnimation.value + index * 0.07) % 1.0) *
                  (screenH - 40) + 15,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: [
                    const Color(0xFF176CB8),
                    const Color(0xFF127C82),
                    const Color(0xFFF3B11E),
                    const Color(0xFFE18616),
                  ][index % 4].withOpacity(0.67 + 0.18 * sin(offset)),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}