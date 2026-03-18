import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/collector_provider.dart';

class CompleteTaskScreen extends StatefulWidget {
  final dynamic task;

  const CompleteTaskScreen({super.key, required this.task});

  @override
  State<CompleteTaskScreen> createState() => _CompleteTaskScreenState();
}

class _CompleteTaskScreenState extends State<CompleteTaskScreen> {
  final List<WasteItem> _items = [];

  // Common waste categories (you can fetch from API later)
  final List<Map<String, dynamic>> _categories = [
    {'id': 1, 'name': 'Plastic', 'pointsPerKg': 10},
    {'id': 2, 'name': 'Paper', 'pointsPerKg': 8},
    {'id': 3, 'name': 'Metal', 'pointsPerKg': 15},
    {'id': 4, 'name': 'Glass', 'pointsPerKg': 12},
    {'id': 5, 'name': 'Organic', 'pointsPerKg': 5},
  ];

  void _addItem() {
    setState(() {
      _items.add(WasteItem(
        categoryId: _categories[0]['id'],
        categoryName: _categories[0]['name'],
        weight: 0,
        pointsPerKg: _categories[0]['pointsPerKg'],
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  int _calculateTotalPoints() {
    int total = 0;
    for (var item in _items) {
      total += (item.weight * item.pointsPerKg).toInt();
    }
    return total;
  }

  double _calculateTotalWeight() {
    double total = 0;
    for (var item in _items) {
      total += item.weight;
    }
    return total;
  }

  Future<void> _submitCompletion() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one waste item'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate all weights are > 0
    for (var item in _items) {
      if (item.weight <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All weights must be greater than 0'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    // Show confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Completion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Weight: ${_calculateTotalWeight().toStringAsFixed(2)} kg'),
            Text('Total Points: ${_calculateTotalPoints()}'),
            const SizedBox(height: 16),
            const Text('Complete this pickup task?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Prepare data
    final itemsData = _items
        .map((item) => {
              'category_id': item.categoryId,
              'weight': item.weight,
            })
        .toList();

    // Submit
    final provider = Provider.of<CollectorProvider>(context, listen: false);
    final result = await provider.completeTask(widget.task.id, itemsData);

    if (!mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task completed! +${result['total_points']} points awarded'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh tasks and go back
      provider.fetchMyTasks();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to complete task'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Task'),
        backgroundColor: Colors.green[700],
      ),
      body: Column(
        children: [
          // Task Info Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.green[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Completing Pickup:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.task.address,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.scale, size: 20, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Total: ${_calculateTotalWeight().toStringAsFixed(2)} kg',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.star, size: 20, color: Colors.amber[700]),
                    const SizedBox(width: 8),
                    Text(
                      '${_calculateTotalPoints()} pts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Items List
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No items added yet',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap "Add Item" to start',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      return _buildItemCard(index);
                    },
                  ),
          ),

          // Bottom Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                OutlinedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Consumer<CollectorProvider>(
                  builder: (context, provider, _) {
                    return ElevatedButton.icon(
                      onPressed: provider.isLoading || _items.isEmpty
                          ? null
                          : _submitCompletion,
                      icon: provider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle),
                      label: Text(provider.isLoading
                          ? 'Completing...'
                          : 'Complete Task'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 0),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(int index) {
    final item = _items[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Item ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeItem(index),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Category Dropdown
            DropdownButtonFormField<int>(
              value: item.categoryId,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((cat) {
                return DropdownMenuItem<int>(
                  value: cat['id'],
                  child: Text('${cat['name']} (${cat['pointsPerKg']} pts/kg)'),
                );
              }).toList(),
              onChanged: (value) {
                final category = _categories.firstWhere((c) => c['id'] == value);
                setState(() {
                  _items[index].categoryId = value!;
                  _items[index].categoryName = category['name'];
                  _items[index].pointsPerKg = category['pointsPerKg'];
                });
              },
            ),
            const SizedBox(height: 12),

            // Weight Input
            TextFormField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(),
                suffixText: 'kg',
              ),
              onChanged: (value) {
                setState(() {
                  _items[index].weight = double.tryParse(value) ?? 0;
                });
              },
            ),
            const SizedBox(height: 12),

            // Points Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Points: ${(item.weight * item.pointsPerKg).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[900],
                    ),
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

class WasteItem {
  int categoryId;
  String categoryName;
  double weight;
  int pointsPerKg;

  WasteItem({
    required this.categoryId,
    required this.categoryName,
    required this.weight,
    required this.pointsPerKg,
  });
}
