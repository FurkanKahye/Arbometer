import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'history_page.dart';

class MeasurementPage extends StatefulWidget {
  const MeasurementPage({super.key});

  @override
  State<MeasurementPage> createState() => _MeasurementPageState();
}

class _MeasurementPageState extends State<MeasurementPage> {
  double _angle = 0.0;
  double _distance = 0.0;
  double _baseAngle = 0.0;
  double _topAngle = 0.0;
  double _treeHeight = 0.0;
  bool _isBaseAngleMeasured = false;
  bool _isTopAngleMeasured = false;

  @override
  void initState() {
    super.initState();
    _startAccelerometer();
  }

  void _startAccelerometer() {
    accelerometerEventStream().listen((AccelerometerEvent event) {
      setState(() {
        double calculatedAngle = atan2(event.y, sqrt(event.x * event.x + event.z * event.z)) * (180 / pi);
        _angle = calculatedAngle;
      });
    });
  }

  void _setDistance(String value) {
    setState(() {
      _distance = double.tryParse(value) ?? 0.0;
    });
  }

  void _measureBaseAngle() {
    setState(() {
      _baseAngle = _angle;
      _isBaseAngleMeasured = true;
    });
  }

  void _measureTopAngle() {
    setState(() {
      _topAngle = _angle;
      _isTopAngleMeasured = true;
    });
  }

  void _clearBaseAngle() {
    setState(() {
      _baseAngle = 0.0;
      _isBaseAngleMeasured = false;
    });
  }

  void _clearTopAngle() {
    setState(() {
      _topAngle = 0.0;
      _isTopAngleMeasured = false;
    });
  }

  void _resetMeasurements() {
    setState(() {
      _isBaseAngleMeasured = false;
      _isTopAngleMeasured = false;
      _baseAngle = 0.0;
      _topAngle = 0.0;
      _treeHeight = 0.0;
    });
  }

  Future<void> _saveMeasurement() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/measurements.json');

    List<Map<String, dynamic>> existingMeasurements = [];
    if (await file.exists()) {
      final contents = await file.readAsString();
      existingMeasurements = List<Map<String, dynamic>>.from(
        json.decode(contents),
      );
    }

    existingMeasurements.add({
      'date': DateTime.now().toIso8601String(),
      'distance': _distance,
      'baseAngle': _baseAngle,
      'topAngle': _topAngle,
      'height': _treeHeight,
    });

    await file.writeAsString(json.encode(existingMeasurements));
  }

  void _calculateHeight() {
    if (_distance > 0 && _isBaseAngleMeasured && _isTopAngleMeasured) {
      double baseRadians = _baseAngle * (pi / 180);
      double topRadians = _topAngle * (pi / 180);

      setState(() {
        _treeHeight = _distance * (tan(topRadians) + tan(baseRadians.abs()));
      });

      _saveMeasurement().then((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tree height successfully calculated and saved!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all measurements!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildCircularButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isSelected,
    VoidCallback? onLongPress,
    Color? color,
  }) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? Colors.green : (color ?? Colors.grey[200]),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              onLongPress: onLongPress,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Icon(
                  icon,
                  size: 40,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (isSelected) 
          Text(
            'Hold to clear',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildAngleDisplay(String label, double angle, bool isMeasured) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isMeasured ? '${angle.toStringAsFixed(1)}°' : '---',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isMeasured ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tree Height Measurer'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Current Angle',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_angle.toStringAsFixed(1)}°',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Distance to tree (meters)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.straighten),
                      ),
                      onChanged: _setDistance,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCircularButton(
                          icon: Icons.arrow_downward,
                          label: 'Base Angle',
                          onPressed: _measureBaseAngle,
                          onLongPress: _clearBaseAngle,
                          isSelected: _isBaseAngleMeasured,
                        ),
                        _buildCircularButton(
                          icon: Icons.arrow_upward,
                          label: 'Top Angle',
                          onPressed: _measureTopAngle,
                          onLongPress: _clearTopAngle,
                          isSelected: _isTopAngleMeasured,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _calculateHeight,
                      child: const Text('Calculate Height'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Measurement Results',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_treeHeight > 0)
                          TextButton.icon(
                            onPressed: _resetMeasurements,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildAngleDisplay('Base Angle', _baseAngle, _isBaseAngleMeasured),
                        _buildAngleDisplay('Top Angle', _topAngle, _isTopAngleMeasured),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tree Height',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _treeHeight > 0 ? '${_treeHeight.toStringAsFixed(2)} m' : '---',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}