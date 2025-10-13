// File: lib/launch/cyber_trends_page.dart
// Purpose: VCAMS dashboard screen. Fetches indicators and data from Azure
// Functions and renders Statewide Trend and Breakdown charts with dynamic
// legend/axis boxes and teen‑friendly analysis that reacts to filters.
// Key responsibilities:
// - Manage filters (indicator, subdivision type/values, years)
// - Draw line (trend) and bar/pie (breakdown) with adaptive labels/height
// - Build analysis/legend/axis label boxes from live chart values
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import '../services/vcams_api.dart';

// Data models for dashboard  
class BreakdownData {
  final String subdivisionValue;
  final double value;

  BreakdownData({required this.subdivisionValue, required this.value});
}

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
  List<BreakdownData> _breakdownData = [];

  bool _isLoading = true;
  String? _errorMessage;
  bool _showIntroCard = true; // Add this to track if intro card should be shown

  // PageView controller & tracking
  late PageController _pageController;
  int _currentChartPage = 0;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
        duration: const Duration(milliseconds: 3200), vsync: this)
      ..repeat();
    _pageController = PageController(initialPage: 0);
    _initializeData();
    // Show the intro card after a brief delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_showIntroCard) {
        _showIntroPopup();
      }
    });
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    _audioPlayer.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('[DEBUG] Loading real data from API...');

      // Load indicators from API only
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

      print('[DEBUG] Successfully loaded data from API');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load dashboard data: $e';
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
      print('Error loading subdivision types from API: $e');
      throw e; // Re-throw to handle in main error handler
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
      print('Error loading subdivision values from API: $e');
      throw e; // Re-throw to handle in main error handler
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
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
        _breakdownData = breakdownData.map((vcamsData) =>
            BreakdownData(
              subdivisionValue: vcamsData.subdivisionValue,
              value: vcamsData.value,
            )).toList();
        _isLoading = false;
      });

      print('[DEBUG] Successfully loaded data from API');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load dashboard data: $e';
      });
    }
  }


  void _showIntroPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.of(ctx).pop();
            setState(() {
              _showIntroCard = false;
            });
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: GestureDetector(
                  onTap: () {},
                  // Prevents tap from dismissing popup when tapping inside
                  child: Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 40),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery
                                .of(context)
                                .size
                                .height * 0.70,
                            minWidth: 0,
                            maxWidth: MediaQuery
                                .of(context)
                                .size
                                .width * 0.85,
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 70),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFF176CB8),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF176CB8)
                                            .withOpacity(0.6),
                                        blurRadius: 20,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment
                                        .center,
                                    children: [
                                      // Icon for cyber intel
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF176CB8),
                                                Color(0xFF10B981)
                                              ]),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF176CB8)
                                                  .withOpacity(0.6),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            )
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.analytics,
                                          size: 30,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Cyber Intel heading with gradient
                                      ShaderMask(
                                        shaderCallback: (bounds) =>
                                            const LinearGradient(colors: [
                                              Color(0xFF176CB8),
                                              Color(0xFF10B981)
                                            ]).createShader(bounds),
                                        child: const Text(
                                          'CYBER INTEL',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Main content text using the specified colors
                                      Text(
                                        'Explore interactive data on cyberbullying and online behaviour across regions and years.',
                                        style: TextStyle(
                                          color: const Color(0xFF10B981)
                                              .withOpacity(0.9),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15.5,
                                          letterSpacing: 0.2,
                                          height: 1.3,
                                          shadows: [
                                            Shadow(blurRadius: 4,
                                                color: Colors.black45)
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),

                                      // Second line text with different color
                                      Text(
                                        'Apply different filters to reveal patterns, trends, and insights shaping the digital world.',
                                        style: TextStyle(
                                          color: const Color(0xFF176CB8)
                                              .withOpacity(0.9),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15.5,
                                          letterSpacing: 0.2,
                                          height: 1.3,
                                          shadows: [
                                            Shadow(blurRadius: 4,
                                                color: Colors.black45)
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Close button
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                _audioPlayer.play(
                                    AssetSource('sounds/tap.wav'));
                                Navigator.of(ctx).pop();
                                setState(() {
                                  _showIntroCard = false;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF176CB8),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              child: const Text(
                                'Explore Dashboard',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
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

  Widget _buildKPIs() {
    if (_trendData.isEmpty) return const SizedBox.shrink();

    // Calculate KPI values from current trend data
    final latestYear = _selectedYears.isEmpty ? 2018 : _selectedYears.last;
    final currentData = _trendData.where((d) => d.year == latestYear).toList();

    double currentRate = 0.0;
    if (currentData.isNotEmpty) {
      currentRate = currentData.first.value;
    }

    // For demonstration, create three KPI values based on current indicator
    double cyberbullyingRate = 0.0;
    double electronicMediaRate = 0.0;
    double overallBullyingRate = 0.0;

    if (_selectedIndicator.toLowerCase().contains('cyber')) {
      cyberbullyingRate = currentRate;
      electronicMediaRate = currentRate * 0.7; // Approximate related metric
      overallBullyingRate = currentRate * 1.2; // Approximate related metric
    } else if (_selectedIndicator.toLowerCase().contains('electronic')) {
      electronicMediaRate = currentRate;
      cyberbullyingRate = currentRate * 0.4; // Approximate related metric
      overallBullyingRate = currentRate * 0.3; // Approximate related metric
    } else {
      overallBullyingRate = currentRate;
      cyberbullyingRate = currentRate * 0.6; // Approximate related metric
      electronicMediaRate = currentRate * 1.3; // Approximate related metric
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: _buildKPICard(
              title: 'Cyberbullying Rate',
              value: '${(cyberbullyingRate * 100).toStringAsFixed(1)}%',
              icon: Icons.security,
              color: const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildKPICard(
              title: 'Screen Time 2h+',
              value: '${(electronicMediaRate * 100).toStringAsFixed(1)}%',
              icon: Icons.tv,
              color: const Color(0xFF176CB8),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildKPICard(
              title: 'Overall Bullying',
              value: '${(overallBullyingRate * 100).toStringAsFixed(1)}%',
              icon: Icons.report_problem,
              color: const Color(0xFFF3B11E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          // Left side - 2 filters
          Expanded(
            child: Column(
              children: [
                _buildSimpleRadioSelectDropdown(
                  'Indicator',
                  _selectedIndicator,
                  _indicators,
                      (value) async {
                    setState(() {
                      _selectedIndicator = value;
                    });
                    await _loadSubdivisionTypes();
                    await _loadData();
                  },
                ),
                const SizedBox(height: 8),
                _buildSimpleRadioSelectDropdown(
                  'Subdivision Type',
                  _selectedSubdivisionType,
                  _subdivisionTypes,
                      (value) async {
                    setState(() {
                      _selectedSubdivisionType = value;
                    });
                    await _loadSubdivisionValues();
                    await _loadData();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right side - 2 filters
          Expanded(
            child: Column(
              children: [
                // Subdivision Values multi-select dropdown (looks like regular dropdown)
                if (_subdivisionValues.isNotEmpty) ...[
                  _buildSimpleMultiSelectDropdown(
                    'Subdivision Values',
                    _selectedSubdivisionValues.isEmpty
                        ? 'Select All'
                        : '${_selectedSubdivisionValues.length} Selected',
                    _subdivisionValues,
                    _selectedSubdivisionValues,
                        (selectedValues) async {
                      setState(() {
                        _selectedSubdivisionValues = selectedValues;
                      });
                      await _loadData();
                    },
                  ),
                ] else
                  ...[
                    _buildCompactDropdown(
                      'Subdivision Values',
                      'No values available',
                      ['No values available'],
                          (value) {},
                    ),
                ],
                const SizedBox(height: 8),
                // Years multi-select dropdown (looks like regular dropdown)
                _buildSimpleMultiSelectDropdown(
                  'Years',
                  _selectedYears.isEmpty ? 'Select All' : '${_selectedYears
                      .length} Selected',
                  _years.map((year) => year.toString()).toList(),
                  _selectedYears.map((year) => year.toString()).toList(),
                      (selectedValues) async {
                    setState(() {
                      _selectedYears = selectedValues.map((year) =>
                          int.parse(year)).toList();
                    });
                    await _loadData();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Container(
      width: double.infinity,
      height: 70,
      // Reduced height for better space usage
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: Colors.black.withOpacity(0.9),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleMultiSelectDropdown(String label,
      String valueLabel,
      List<String> items,
      List<String> selectedValues,
      ValueChanged<List<String>> onChanged,) {
    return Container(
      width: double.infinity,
      height: 70,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final values = await showDialog<List<String>>(
                  context: context,
                  builder: (ctx) {
                    final Set<String> tempSelected = Set.from(selectedValues);
                    return StatefulBuilder(
                      builder: (context, setDialogState) {
                        return AlertDialog(
                          backgroundColor: Colors.black.withOpacity(0.96),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(
                                  color: Color(0xFF176CB8), width: 2)),
                          title: Text(
                            'Select $label',
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: SizedBox(
                            width: 320,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: items.map((item) {
                                  return CheckboxListTile(
                                    value: tempSelected.contains(item),
                                    title: Text(
                                      item,
                                      style: const TextStyle(
                                          color: Colors.white),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    controlAffinity: ListTileControlAffinity
                                        .leading,
                                    activeColor: const Color(0xFF10B981),
                                    checkboxShape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6)),
                                    onChanged: (checked) {
                                      setDialogState(() {
                                        if (checked == true) {
                                          tempSelected.add(item);
                                        } else {
                                          tempSelected.remove(item);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(ctx).pop(selectedValues),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Color(0xFF176CB8)),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.of(ctx).pop(tempSelected.toList());
                              },
                              child: const Text('Apply'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
                if (values != null) {
                  onChanged(values);
                }
              },
              child: Container(
                width: double.infinity,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        valueLabel,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    // Deprecated for radio/select dialogs
    return const SizedBox.shrink();
  }

  Widget _buildSimpleRadioSelectDropdown(String label,
      String selectedValue,
      List<String> items,
      ValueChanged<String> onChanged,) {
    return Container(
      width: double.infinity,
      height: 70,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final value = await showDialog<String>(
                  context: context,
                  builder: (ctx) {
                    String? tempSelected = selectedValue;
                    return StatefulBuilder(
                      builder: (context, setDialogState) {
                        return AlertDialog(
                          backgroundColor: Colors.black.withOpacity(0.96),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(
                                  color: Color(0xFF176CB8), width: 2)),
                          title: Text(
                            'Select $label',
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: SizedBox(
                            width: 320,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: items.map((item) {
                                  return RadioListTile<String>(
                                    value: item,
                                    groupValue: tempSelected,
                                    title: Text(
                                      item,
                                      style: const TextStyle(
                                          color: Colors.white),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    activeColor: const Color(0xFF10B981),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6)),
                                    onChanged: (newValue) {
                                      setDialogState(() {
                                        tempSelected = newValue;
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(ctx).pop(selectedValue),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Color(0xFF176CB8)),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.of(ctx).pop(
                                    tempSelected ?? selectedValue);
                              },
                              child: const Text('Apply'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
                if (value != null && value != selectedValue) {
                  onChanged(value);
                }
              },
              child: Container(
                width: double.infinity,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        selectedValue,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendAnalysisBox() {
    if (_trendData.isEmpty) return const SizedBox.shrink();

    // Find the peak year for alert-focused messaging
    final sortedData = List<SeriesData>.from(_trendData)
      ..sort((a, b) => b.value.compareTo(a.value));
    final peakData = sortedData.first;
    final peakYear = peakData.year;
    final peakValue = peakData.value;
    final peakPercentage = (peakValue * 100).toStringAsFixed(1);

    String message;
    Color messageColor;

    if (peakValue > 0.4) {
      message =
      "Alert! Peak cyberbullying rates reached $peakPercentage% in $peakYear.\nThis represents a high-risk period requiring attention.";
      messageColor = const Color(0xFFEF4444);
    } else if (peakValue > 0.25) {
      message =
      "Heads up! Highest rates of $peakPercentage% occurred in $peakYear.\nMonitor these concerning trends closely.";
      messageColor = const Color(0xFFF59E0B);
    } else {
      message =
      "Notice: Peak rate was $peakPercentage% in $peakYear.\nStay vigilant as rates can change over time.";
      messageColor = const Color(0xFFF59E0B);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: messageColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: messageColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            peakValue > 0.4 ? Icons.warning : Icons.trending_up,
            color: messageColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownAnalysisBox() {
    if (_breakdownData.isEmpty) return const SizedBox.shrink();

    final topEntry = _breakdownData.reduce((a, b) => a.value > b.value ? a : b);
    final percentage = (topEntry.value * 100).toStringAsFixed(1);
    final year = _selectedYears.isEmpty ? 2018 : _selectedYears.last;

    String message;
    Color messageColor;

    if (topEntry.value > 0.35) {
      message = "Alert! ${topEntry
          .subdivisionValue} shows high risk at $percentage% in $year.\nImmediate attention and intervention needed.";
      messageColor = const Color(0xFFEF4444);
    } else if (topEntry.value > 0.2) {
      message = "Warning: ${topEntry
          .subdivisionValue} leads with $percentage% in $year.\nThis area requires monitoring and support.";
      messageColor = const Color(0xFFF59E0B);
    } else {
      message = "Heads up: ${topEntry
          .subdivisionValue} at $percentage% in $year.\nStay aware of potential risks in this area.";
      messageColor = const Color(0xFFF59E0B);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: messageColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: messageColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            topEntry.value > 0.35 ? Icons.warning : Icons.info,
            color: messageColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              maxLines: 2,
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

  // Swipeable charts container with indicator and charts
  Widget _buildSwipeableChartsContainer() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF176CB8), width: 2),
      ),
      child: Column(
        children: [
          // Page indicator and swipe hint - reduced padding
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF176CB8).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF176CB8), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.swipe, color: Color(0xFF176CB8),
                              size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'Swipe to view charts',
                            style: TextStyle(
                              color: Color(0xFF176CB8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, color: Color(
                              0xFF176CB8), size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8), // Reduced from 12
                // Page dots indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _currentChartPage == 0 ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentChartPage == 0
                            ? const Color(0xFF10B981)
                            : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _currentChartPage == 1 ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentChartPage == 1
                            ? const Color(0xFF176CB8)
                            : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Charts container
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentChartPage = index;
                });
              },
              children: [
                // Page 1: Trend Chart
                _buildTrendChartPage(),
                // Page 2: Breakdown Chart
                _buildBreakdownChartPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // The swipeable trend chart page
  Widget _buildTrendChartPage() {
    if (_trendData.isEmpty) {
      return const Center(
        child: Text(
          'No trend data available',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Chart title (limit lines to 2)
          const Text(
            'Statewide Trend',
            style: TextStyle(
              color: Color(0xFF10B981),
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Page dots & analysis box closer together
          _buildTrendAnalysisBox(),
          const SizedBox(height: 8),
          // Chart
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
                        .map((data) => FlSpot(data.year.toDouble(), data.value))
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
          const SizedBox(height: 8),
          // Legend below chart
          _buildTrendAxisLabelBox(),
        ],
      ),
    );
  }

  // The swipeable breakdown chart page
  Widget _buildBreakdownChartPage() {
    if (_breakdownData.isEmpty) {
      return const Center(
        child: Text(
          'No breakdown data available',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    // Compute dynamic height based on label/text length and bar count
    final int barCount = _breakdownData.length;
    final bool hasLongLabels = _breakdownData.any((d) =>
    d.subdivisionValue.length > 14);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Chart title (limit lines to 2)
          Text(
            'Breakdown (${_selectedYears.isEmpty ? 2018 : _selectedYears
                .last})',
            style: const TextStyle(
              color: Color(0xFF176CB8),
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Analysis box closer to heading
          _buildBreakdownAnalysisBox(),
          const SizedBox(height: 8),
          // Chart
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
                        if (value.toInt() < _breakdownData.length) {
                          return Transform.rotate(
                            angle: -0.7,
                            child: SizedBox(
                              width: hasLongLabels ? 54 : 40,
                              child: Text(
                                _breakdownData[value.toInt()].subdivisionValue,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 9),
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
          const SizedBox(height: 8),
          // Legend below chart
          _buildBreakdownLegendBox(),
        ],
      ),
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

    // Reduce pie chart size for a cleaner layout
    return Center(
      child: SizedBox(
        width: 168,
        height: 168,
        child: PieChart(
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
                radius: 62,
                titleStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            }).toList(),
            centerSpaceRadius: 35,
            sectionsSpace: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFF10B981),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Loading Dashboard Data...',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Almost there!',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(),
        toolbarHeight: 0,
      ),
      body: WillPopScope(
        onWillPop: () async {
          _audioPlayer.play(AssetSource('sounds/tap.wav'));
          return true; // Allow back navigation
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildBlurredBackground(),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8), // Small top padding
                  // KPI cards in horizontal arrangement
                  _buildKPIs(),
                  // 2x2 filters with reduced spacing
                  _buildFilters(),
                  const SizedBox(height: 8), // Reduced spacing before charts
                  Expanded(
                    child: _isLoading
                        ? _buildLoadingWidget()
                        : _errorMessage != null
                        ? _buildErrorWidget()
                        : _buildSwipeableChartsContainer(),
                  ),
                ],
              ),
            ),
          ],
        ),
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