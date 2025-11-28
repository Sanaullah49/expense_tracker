import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class ColorPickerDialog extends StatefulWidget {
  final Color selectedColor;
  final Function(Color) onSelect;
  final List<Color>? colors;

  const ColorPickerDialog({
    super.key,
    required this.selectedColor,
    required this.onSelect,
    this.colors,
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.selectedColor;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              children: [
                const Text(
                  'Choose Color',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    boxShadow: [
                      BoxShadow(
                        color: _selectedColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected Color',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#${_selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),

          TabBar(
            controller: _tabController,
            labelColor: _selectedColor,
            indicatorColor: _selectedColor,
            tabs: const [
              Tab(text: 'Basic'),
              Tab(text: 'Material'),
            ],
          ),

          SizedBox(
            height: 280,
            child: TabBarView(
              controller: _tabController,
              children: [_buildBasicColors(), _buildMaterialColors()],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onSelect(_selectedColor);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedColor,
                    ),
                    child: const Text('Select'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicColors() {
    final colors = widget.colors ?? AppColors.categoryColors;

    return GridView.builder(
      padding: const EdgeInsets.all(AppSizes.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: AppSizes.sm,
        crossAxisSpacing: AppSizes.sm,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final color = colors[index];
        final isSelected = _selectedColor.toARGB32() == color.toARGB32();

        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 4)
                  : Border.all(color: Colors.grey.shade300, width: 1),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? Icon(Icons.check, color: _getContrastColor(color), size: 24)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildMaterialColors() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSizes.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: AppSizes.sm,
        crossAxisSpacing: AppSizes.sm,
      ),
      itemCount: _materialColors.length,
      itemBuilder: (context, index) {
        final color = _materialColors[index];
        final isSelected = _selectedColor.toARGB32() == color.toARGB32();

        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 4)
                  : Border.all(color: Colors.grey.shade300, width: 1),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? Icon(Icons.check, color: _getContrastColor(color), size: 24)
                : null,
          ),
        );
      },
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

final List<Color> _materialColors = [
  Colors.red.shade300,
  Colors.red.shade500,
  Colors.red.shade700,
  Colors.red.shade900,

  Colors.pink.shade300,
  Colors.pink.shade500,
  Colors.pink.shade700,
  Colors.pink.shade900,

  Colors.purple.shade300,
  Colors.purple.shade500,
  Colors.purple.shade700,
  Colors.purple.shade900,

  Colors.deepPurple.shade300,
  Colors.deepPurple.shade500,
  Colors.deepPurple.shade700,
  Colors.deepPurple.shade900,

  Colors.indigo.shade300,
  Colors.indigo.shade500,
  Colors.indigo.shade700,
  Colors.indigo.shade900,

  Colors.blue.shade300,
  Colors.blue.shade500,
  Colors.blue.shade700,
  Colors.blue.shade900,

  Colors.lightBlue.shade300,
  Colors.lightBlue.shade500,
  Colors.lightBlue.shade700,
  Colors.lightBlue.shade900,

  Colors.cyan.shade300,
  Colors.cyan.shade500,
  Colors.cyan.shade700,
  Colors.cyan.shade900,

  Colors.teal.shade300,
  Colors.teal.shade500,
  Colors.teal.shade700,
  Colors.teal.shade900,

  Colors.green.shade300,
  Colors.green.shade500,
  Colors.green.shade700,
  Colors.green.shade900,

  Colors.lightGreen.shade300,
  Colors.lightGreen.shade500,
  Colors.lightGreen.shade700,
  Colors.lightGreen.shade900,

  Colors.lime.shade300,
  Colors.lime.shade500,
  Colors.lime.shade700,
  Colors.lime.shade900,

  Colors.yellow.shade300,
  Colors.yellow.shade600,
  Colors.yellow.shade800,
  Colors.yellow.shade900,

  Colors.amber.shade300,
  Colors.amber.shade500,
  Colors.amber.shade700,
  Colors.amber.shade900,

  Colors.orange.shade300,
  Colors.orange.shade500,
  Colors.orange.shade700,
  Colors.orange.shade900,

  Colors.deepOrange.shade300,
  Colors.deepOrange.shade500,
  Colors.deepOrange.shade700,
  Colors.deepOrange.shade900,

  Colors.brown.shade300,
  Colors.brown.shade500,
  Colors.brown.shade700,
  Colors.brown.shade900,

  Colors.grey.shade400,
  Colors.grey.shade600,
  Colors.grey.shade800,
  Colors.grey.shade900,

  Colors.blueGrey.shade300,
  Colors.blueGrey.shade500,
  Colors.blueGrey.shade700,
  Colors.blueGrey.shade900,
];
