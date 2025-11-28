import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

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
    _tabController = TabController(length: _iconCategories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  color: Colors.grey.shade300,
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
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      borderSide: BorderSide(color: Colors.grey.shade300),
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
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: _accentColor,
                  tabs: _iconCategories.keys
                      .map((category) => Tab(text: category))
                      .toList(),
                ),

              Expanded(
                child: _searchQuery.isNotEmpty
                    ? _buildSearchResults()
                    : TabBarView(
                        controller: _tabController,
                        children: _iconCategories.entries.map((entry) {
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
    final allIcons = <String, IconData>{};
    for (var category in _iconCategories.values) {
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
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No icons found',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return _buildIconGrid(Map.fromEntries(filteredIcons));
  }

  Widget _buildIconGrid(Map<String, IconData> icons) {
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
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: isSelected
                    ? Border.all(color: _accentColor, width: 2)
                    : null,
              ),
              child: Icon(
                entry.value,
                color: isSelected ? _accentColor : Colors.grey.shade700,
                size: 28,
              ),
            ),
          ),
        );
      },
    );
  }
}

final Map<String, Map<String, IconData>> _iconCategories = {
  'Finance': {
    'Wallet': Icons.account_balance_wallet,
    'Bank': Icons.account_balance,
    'Credit Card': Icons.credit_card,
    'Savings': Icons.savings,
    'Money': Icons.attach_money,
    'Euro': Icons.euro,
    'Currency': Icons.currency_exchange,
    'Payment': Icons.payment,
    'Receipt': Icons.receipt,
    'Receipt Long': Icons.receipt_long,
    'Trending Up': Icons.trending_up,
    'Trending Down': Icons.trending_down,
    'Analytics': Icons.analytics,
    'Pie Chart': Icons.pie_chart,
    'Bar Chart': Icons.bar_chart,
    'Show Chart': Icons.show_chart,
    'Calculate': Icons.calculate,
    'Percent': Icons.percent,
    'Price Check': Icons.price_check,
    'Sell': Icons.sell,
  },
  'Shopping': {
    'Shopping Cart': Icons.shopping_cart,
    'Shopping Bag': Icons.shopping_bag,
    'Shopping Basket': Icons.shopping_basket,
    'Store': Icons.store,
    'Storefront': Icons.storefront,
    'Local Mall': Icons.local_mall,
    'Card Giftcard': Icons.card_giftcard,
    'Redeem': Icons.redeem,
    'Local Offer': Icons.local_offer,
    'Loyalty': Icons.loyalty,
  },
  'Food': {
    'Restaurant': Icons.restaurant,
    'Fastfood': Icons.fastfood,
    'Local Cafe': Icons.local_cafe,
    'Coffee': Icons.coffee,
    'Local Bar': Icons.local_bar,
    'Wine Bar': Icons.wine_bar,
    'Local Pizza': Icons.local_pizza,
    'Icecream': Icons.icecream,
    'Cake': Icons.cake,
    'Bakery Dining': Icons.bakery_dining,
    'Lunch Dining': Icons.lunch_dining,
    'Dinner Dining': Icons.dinner_dining,
    'Kitchen': Icons.kitchen,
    'Local Grocery': Icons.local_grocery_store,
  },
  'Transport': {
    'Directions Car': Icons.directions_car,
    'Local Taxi': Icons.local_taxi,
    'Directions Bus': Icons.directions_bus,
    'Train': Icons.train,
    'Subway': Icons.subway,
    'Tram': Icons.tram,
    'Flight': Icons.flight,
    'Local Shipping': Icons.local_shipping,
    'Two Wheeler': Icons.two_wheeler,
    'Pedal Bike': Icons.pedal_bike,
    'Electric Scooter': Icons.electric_scooter,
    'Directions Walk': Icons.directions_walk,
    'Local Gas Station': Icons.local_gas_station,
    'EV Station': Icons.ev_station,
    'Local Parking': Icons.local_parking,
  },
  'Home': {
    'Home': Icons.home,
    'House': Icons.house,
    'Apartment': Icons.apartment,
    'Cottage': Icons.cottage,
    'Bed': Icons.bed,
    'Chair': Icons.chair,
    'Table Restaurant': Icons.table_restaurant,
    'Bathtub': Icons.bathtub,
    'Shower': Icons.shower,
    'Cleaning Services': Icons.cleaning_services,
    'Lightbulb': Icons.lightbulb,
    'Power': Icons.power,
    'Water Drop': Icons.water_drop,
    'Local Laundry': Icons.local_laundry_service,
    'Microwave': Icons.microwave,
    'Tv': Icons.tv,
    'Weekend': Icons.weekend,
    'Yard': Icons.yard,
    'Roofing': Icons.roofing,
    'Plumbing': Icons.plumbing,
  },
  'Health': {
    'Favorite': Icons.favorite,
    'Health And Safety': Icons.health_and_safety,
    'Medical Services': Icons.medical_services,
    'Local Hospital': Icons.local_hospital,
    'Local Pharmacy': Icons.local_pharmacy,
    'Medication': Icons.medication,
    'Vaccines': Icons.vaccines,
    'Healing': Icons.healing,
    'Psychology': Icons.psychology,
    'Self Improvement': Icons.self_improvement,
    'Spa': Icons.spa,
    'Fitness Center': Icons.fitness_center,
    'Sports': Icons.sports,
    'Sports Soccer': Icons.sports_soccer,
    'Sports Basketball': Icons.sports_basketball,
    'Sports Tennis': Icons.sports_tennis,
    'Pool': Icons.pool,
    'Surfing': Icons.surfing,
  },
  'Entertainment': {
    'Movie': Icons.movie,
    'Theaters': Icons.theaters,
    'Music Note': Icons.music_note,
    'Headphones': Icons.headphones,
    'Gamepad': Icons.gamepad,
    'Sports Esports': Icons.sports_esports,
    'Casino': Icons.casino,
    'Attractions': Icons.attractions,
    'Park': Icons.park,
    'Beach Access': Icons.beach_access,
    'Nightlife': Icons.nightlife,
    'Celebration': Icons.celebration,
    'Party Mode': Icons.party_mode,
    'Camera': Icons.camera_alt,
    'Photo': Icons.photo,
    'Palette': Icons.palette,
    'Brush': Icons.brush,
  },
  'Education': {
    'School': Icons.school,
    'Menu Book': Icons.menu_book,
    'Auto Stories': Icons.auto_stories,
    'Library Books': Icons.library_books,
    'Class': Icons.class_,
    'Science': Icons.science,
    'Biotech': Icons.biotech,
    'Architecture': Icons.architecture,
    'Draw': Icons.draw,
    'Edit Note': Icons.edit_note,
    'Sticky Note': Icons.sticky_note_2,
    'Article': Icons.article,
    'Feed': Icons.feed,
    'Quiz': Icons.quiz,
    'Psychology Alt': Icons.psychology_alt,
  },
  'Work': {
    'Work': Icons.work,
    'Business Center': Icons.business_center,
    'Business': Icons.business,
    'Corporate Fare': Icons.corporate_fare,
    'Badge': Icons.badge,
    'Computer': Icons.computer,
    'Laptop': Icons.laptop,
    'Phone Android': Icons.phone_android,
    'Tablet': Icons.tablet,
    'Mouse': Icons.mouse,
    'Keyboard': Icons.keyboard,
    'Print': Icons.print,
    'Scanner': Icons.scanner,
    'Fax': Icons.fax,
    'Folder': Icons.folder,
    'Description': Icons.description,
    'Task': Icons.task,
    'Assignment': Icons.assignment,
    'Pending Actions': Icons.pending_actions,
  },
  'Travel': {
    'Luggage': Icons.luggage,
    'Flight Takeoff': Icons.flight_takeoff,
    'Flight Land': Icons.flight_land,
    'Hotel': Icons.hotel,
    'Holiday Village': Icons.holiday_village,
    'Houseboat': Icons.houseboat,
    'Sailing': Icons.sailing,
    'Kayaking': Icons.kayaking,
    'Hiking': Icons.hiking,
    'Terrain': Icons.terrain,
    'Forest': Icons.forest,
    'Landscape': Icons.landscape,
    'Map': Icons.map,
    'Explore': Icons.explore,
    'Tour': Icons.tour,
    'Flag': Icons.flag,
    'Photo Camera': Icons.photo_camera,
    'Compass Calibration': Icons.compass_calibration,
  },
  'Other': {
    'Category': Icons.category,
    'Label': Icons.label,
    'Bookmark': Icons.bookmark,
    'Star': Icons.star,
    'Diamond': Icons.diamond,
    'Workspace Premium': Icons.workspace_premium,
    'Verified': Icons.verified,
    'Pets': Icons.pets,
    'Child Care': Icons.child_care,
    'Family Restroom': Icons.family_restroom,
    'Elderly': Icons.elderly,
    'Accessibility': Icons.accessibility,
    'Volunteer Activism': Icons.volunteer_activism,
    'Handshake': Icons.handshake,
    'Public': Icons.public,
    'Language': Icons.language,
    'Translate': Icons.translate,
    'Help': Icons.help,
    'Info': Icons.info,
    'Settings': Icons.settings,
    'Build': Icons.build,
    'Construction': Icons.construction,
    'Handyman': Icons.handyman,
    'Hardware': Icons.hardware,
  },
};
