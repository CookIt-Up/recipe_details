import 'package:cookitup/camera_search.dart';
import 'package:flutter/material.dart';

class SelectionPage extends StatefulWidget {
  @override
  _SelectionPageState createState() => _SelectionPageState();
}

class _SelectionPageState extends State<SelectionPage> {
  Set<String> detectedLabels = {};

  void toggleSelection(String item) {
    setState(() {
      if (detectedLabels.contains(item)) {
        detectedLabels.remove(item);
      } else {
        detectedLabels.add(item);
      }
    });
  }

  bool isItemSelected(String item) {
    return detectedLabels.contains(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD1E7D2),
      
      appBar: AppBar(
        title: Text('Cook with what I have'),
        backgroundColor: Color(0xFFD1E7D2),
      ),
      
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Fruits', ['apple', 'banana', 'orange']),
            _buildSection('Vegetables', ['carrot', 'potato', 'tomato', 'onion']),
            _buildSection('Pantry Essentials', ['rice', 'pasta', 'beans']),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: detectedLabels.isNotEmpty ? () => _applySelection() : null,
              
              child: Text(
                'Apply',
                style: TextStyle(
                  color: detectedLabels.isNotEmpty ? Colors.black : Colors.grey, 
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: items.map((item) {
            bool isSelected = isItemSelected(item);
            return GestureDetector(
              onTap: () {
                toggleSelection(item);
              },
              child: Chip(
                label: Text(item),
                backgroundColor: isSelected ? Colors.green[200] : Color(0xFFD1E7D2),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  void _applySelection() {
    // Implement your logic for applying the selected items here
    print('Applying selected items: $detectedLabels');
    // Optionally, you can reset the selection after applying
    setState(() {
         Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (ctx) {
                              return CameraSearch(documentIds: detectedLabels);
                            },
                          ),
                        );
    });
  }
}