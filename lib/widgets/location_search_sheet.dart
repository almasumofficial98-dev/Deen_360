import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/theme.dart';
import '../data/salah_repository.dart';

class LocationSearchSheet extends StatefulWidget {
  final Color primaryColor;
  final Function(LocationData) onLocationSelected;
  final VoidCallback onResetToGPS;

  const LocationSearchSheet({
    super.key,
    required this.primaryColor,
    required this.onLocationSelected,
    required this.onResetToGPS,
  });

  @override
  State<LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<LocationSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.length > 2) {
        _searchCity(query);
      } else {
        setState(() => _results = []);
      }
    });
  }

  Future<void> _searchCity(String query) async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'Deen360-App',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _results = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.modal),
          topRight: Radius.circular(AppRadius.modal),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Change Location',
                  style: AppTheme.subheading,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textLight),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              autofocus: true,
              style: AppTheme.body,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.inputBg,
                hintText: 'Search city or area...',
                hintStyle: AppTheme.caption,
                prefixIcon: Icon(Icons.search_rounded, color: widget.primaryColor),
                suffixIcon: _isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: widget.primaryColor,
                          ),
                        ),
                      )
                    : _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _results = []);
                            },
                          )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            onTap: () {
              widget.onResetToGPS();
              Navigator.pop(context);
            },
            leading: CircleAvatar(
              backgroundColor: widget.primaryColor.withValues(alpha: 0.1),
              child: Icon(Icons.my_location_rounded, color: widget.primaryColor, size: 20),
            ),
            title: Text('Use Current Location', style: AppTheme.body),
            subtitle: Text('Automatic GPS detection', style: AppTheme.small),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.border),
          ),
          const Divider(height: 1),
          if (_results.isEmpty && !_isLoading && _searchController.text.length > 2)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_off_rounded, size: 48, color: AppTheme.border),
                    const SizedBox(height: 16),
                    Text('No locations found', style: AppTheme.caption),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final item = _results[index];
                  final displayName = item['display_name'] ?? '';
                  final mainName = item['address']?['city'] ?? 
                                   item['address']?['town'] ?? 
                                   item['address']?['village'] ?? 
                                   item['name'] ?? 'Unknown Location';
                  
                  return ListTile(
                    onTap: () {
                      final lat = double.tryParse(item['lat'] ?? '0') ?? 0;
                      final lon = double.tryParse(item['lon'] ?? '0') ?? 0;
                      final city = mainName;
                      final country = item['address']?['country'] ?? '';
                      
                      widget.onLocationSelected(LocationData(
                        latitude: lat,
                        longitude: lon,
                        city: city,
                        country: country,
                        isManual: true,
                      ));
                      Navigator.pop(context);
                    },
                    leading: const Icon(Icons.location_on_outlined, color: AppTheme.textLight),
                    title: Text(mainName, style: AppTheme.body),
                    subtitle: Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.small,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
