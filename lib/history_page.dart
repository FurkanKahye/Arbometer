import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

// Rest of the code remains exactly the same
class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _measurements = [];

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/measurements.json');
    
    if (await file.exists()) {
      final contents = await file.readAsString();
      if (!mounted) return;
      setState(() {
        _measurements = List<Map<String, dynamic>>.from(
          json.decode(contents),
        );
      });
    }
  }

  Future<void> _deleteMeasurement(int index) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/measurements.json');
    
    setState(() {
      _measurements.removeAt(index);
    });
    
    await file.writeAsString(json.encode(_measurements));
  }

  Future<void> _deleteAllMeasurements() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/measurements.json');
    
    setState(() {
      _measurements.clear();
    });
    
    await file.writeAsString(json.encode(_measurements));
  }

  Future<void> _exportMeasurements() async {
    try {
      // Create a temporary file in the cache directory
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/tree_measurements_export.json');
      
      // Convert measurements to a more readable format
      final exportData = _measurements.map((measurement) => {
        'date': measurement['date'],
        'height': '${measurement['height'].toStringAsFixed(2)} meters',
        'distance': '${measurement['distance']} meters',
        'baseAngle': '${measurement['baseAngle'].toStringAsFixed(1)}°',
        'topAngle': '${measurement['topAngle'].toStringAsFixed(1)}°',
      }).toList();
      
      // Write the formatted data to the temporary file
      await tempFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(exportData),
      );

      // Share the file
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: 'Tree Measurements Export',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing measurements: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Measurement'),
          content: const Text('Are you sure you want to delete this measurement?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _deleteMeasurement(index);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Measurement deleted'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete All Measurements'),
          content: const Text('Are you sure you want to delete all measurements?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete All', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _deleteAllMeasurements();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All measurements deleted'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Measurement History'),
        actions: [
          if (_measurements.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _exportMeasurements,
              tooltip: 'Export measurements',
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showDeleteAllDialog(context),
              tooltip: 'Delete all records',
            ),
          ],
        ],
      ),
      body: _measurements.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No measurements yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: _measurements.length,
            itemBuilder: (context, index) {
              final measurement = _measurements[_measurements.length - 1 - index];
              return Dismissible(
                key: Key(measurement['date'].toString()),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _deleteMeasurement(_measurements.length - 1 - index);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Measurement deleted'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(
                      'Tree Height: ${measurement['height'].toStringAsFixed(2)} meters',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Distance: ${measurement['distance']} meters'),
                        Text('Base Angle: ${measurement['baseAngle'].toStringAsFixed(1)}°'),
                        Text('Top Angle: ${measurement['topAngle'].toStringAsFixed(1)}°'),
                        Text('Date: ${measurement['date'].toString().split('.')[0]}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _showDeleteConfirmationDialog(
                          context,
                          _measurements.length - 1 - index,
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }
}