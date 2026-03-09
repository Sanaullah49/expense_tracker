import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/icon_catalog.dart';

class IconPickerDialog extends StatefulWidget {
  final IconData selectedIcon;
  final Color? color;
  final Function(IconData) onSelect;

  const IconPickerDialog({
    super.key,
    required this.selectedIcon,
    this.color,
    required this.onSelect,
  });

  @override
  State<IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<IconPickerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  late Color _accentColor;

  @override
  void initState() {
    super.initState();
    _accentColor = widget.color ?? AppColors.primary;
    _tabController = TabController(
      length: kIconPickerCategories.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusXl),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outline.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Row(
                  children: [
                    const Text(
                      'Choose Icon',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search icons...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      borderSide: BorderSide(color: _accentColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.sm,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                ),
              ),
              const SizedBox(height: AppSizes.sm),

              if (_searchQuery.isEmpty)
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: _accentColor,
                  unselectedLabelColor: scheme.onSurface.withValues(
                    alpha: 0.65,
                  ),
                  indicatorColor: _accentColor,
                  tabs: kIconPickerCategories.keys
                      .map((category) => Tab(text: category))
                      .toList(),
                ),

              Expanded(
                child: _searchQuery.isNotEmpty
                    ? _buildSearchResults()
                    : TabBarView(
                        controller: _tabController,
                        children: kIconPickerCategories.entries.map((entry) {
                          return _buildIconGrid(entry.value);
                        }).toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    final scheme = Theme.of(context).colorScheme;
    final allIcons = <String, IconData>{};
    for (var category in kIconPickerCategories.values) {
      allIcons.addAll(category);
    }

    final filteredIcons = allIcons.entries
        .where((e) => e.key.toLowerCase().contains(_searchQuery))
        .toList();

    if (filteredIcons.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 16),
            Text(
              'No icons found',
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return _buildIconGrid(Map.fromEntries(filteredIcons));
  }

  Widget _buildIconGrid(Map<String, IconData> icons) {
    final scheme = Theme.of(context).colorScheme;
    return GridView.builder(
      padding: const EdgeInsets.all(AppSizes.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: AppSizes.sm,
        crossAxisSpacing: AppSizes.sm,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final entry = icons.entries.elementAt(index);
        final isSelected = widget.selectedIcon == entry.value;

        return Tooltip(
          message: entry.key,
          child: InkWell(
            onTap: () => widget.onSelect(entry.value),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected
                    ? _accentColor.withValues(alpha: 0.2)
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: isSelected
                    ? Border.all(color: _accentColor, width: 2)
                    : null,
              ),
              child: Icon(
                entry.value,
                color: isSelected
                    ? _accentColor
                    : scheme.onSurface.withValues(alpha: 0.75),
                size: 28,
              ),
            ),
          ),
        );
      },
    );
  }
}
