import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/models.dart';
import '../../services/firebase_services.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AddEditListingScreen extends StatefulWidget {
  final ServiceListing? listing;
  const AddEditListingScreen({super.key, this.listing});

  @override
  State<AddEditListingScreen> createState() => _AddEditListingScreenState();
}

class _AddEditListingScreenState extends State<AddEditListingScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _priceCtrl    = TextEditingController();
  final _locationCtrl = TextEditingController();
  bool _submitted = false;

  final _phoneCtrl    = TextEditingController();

  String? _selectedCategory;
  String _selectedPriceUnit = 'per visit';
  int    _durationMinutes   = 60;
  bool   _isActive          = true;
  bool   _saving            = false;

  List<String> _whatsIncluded = [];
  final _newItemCtrl = TextEditingController();

  final _firestore  = FirestoreService();
  bool get _isEditing => widget.listing != null;
  final _priceUnits = ['per visit', 'per hour', 'fixed'];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final l = widget.listing!;
      _titleCtrl.text    = l.title;
      _descCtrl.text     = l.description;
      _priceCtrl.text    = l.price.toStringAsFixed(0);
      _locationCtrl.text = l.providerLocation;
      _phoneCtrl.text    = l.providerPhone;
      _selectedCategory  = l.category;
      _selectedPriceUnit = l.priceUnit;
      _durationMinutes   = l.durationMinutes;
      _isActive          = l.isActive;
      _whatsIncluded     = l.whatsIncluded.isNotEmpty
          ? List<String>.from(l.whatsIncluded)
          : ServiceListing.defaultWhatsIncluded(l.durationMinutes);
    } else {
      // Pre-fill phone from user profile
      _prefillProviderInfo();
      _whatsIncluded = ServiceListing.defaultWhatsIncluded(_durationMinutes);
    }
  }

  void _prefillProviderInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userData = await AuthService().getUserData(uid);
    if (mounted && userData != null) {
      setState(() {
        if (_phoneCtrl.text.isEmpty) _phoneCtrl.text = userData.phone;
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
    _newItemCtrl.dispose();
    super.dispose();
  }

  void _addIncludedItem() {
    final text = _newItemCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _whatsIncluded.add(text);
      _newItemCtrl.clear();
    });
  }

  void _removeIncludedItem(int index) {
    setState(() => _whatsIncluded.removeAt(index));
  }

  void _pickLocation() async {
    String filter = '';
    final TextEditingController searchCtrl = TextEditingController();

    LocationService.warmCache();

    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) {
        final filtered = LocationService.cached
            .where((l) => l.toLowerCase().contains(filter.toLowerCase()))
            .toList();
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, sc) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      const Text('Service Location निवडा',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: (v) => setModal(() => filter = v),
                    decoration: InputDecoration(
                      hintText: 'शोधा... / Search area...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: sc,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final loc = filtered[i];
                      final isSel = loc == _locationCtrl.text;
                      return ListTile(
                        leading: Icon(Icons.location_on_rounded,
                            color: isSel ? AppTheme.primary : AppTheme.textLight,
                            size: 20),
                        title: Text(loc,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                              color: isSel ? AppTheme.primary : AppTheme.textPrimary,
                            )),
                        trailing: isSel
                            ? const Icon(Icons.check_circle_rounded,
                                color: AppTheme.primary, size: 18)
                            : null,
                        onTap: () => Navigator.pop(ctx, loc),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );

    if (picked != null) {
      setState(() => _locationCtrl.text = picked);
    }
  }

  void _save() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    if (_locationCtrl.text.trim().isEmpty) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a category'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not signed in');

      final userData   = await AuthService().getUserData(uid);
      final providerName = userData?.name ?? '';

      if (_isEditing) {
        final updated = widget.listing!.copyWith(
          title:            _titleCtrl.text.trim(),
          description:      _descCtrl.text.trim(),
          category:         _selectedCategory!,
          price:            double.parse(_priceCtrl.text.trim()),
          priceUnit:        _selectedPriceUnit,
          durationMinutes:  _durationMinutes,
          isActive:         _isActive,
          providerPhone:    _phoneCtrl.text.trim(),
          providerLocation: _locationCtrl.text.trim(),
          whatsIncluded:    _whatsIncluded,
        );
        await _firestore.updateServiceListing(updated);
      } else {
        final listing = ServiceListing(
          id:               '',
          providerId:       uid,
          providerName:     providerName,
          providerPhone:    _phoneCtrl.text.trim(),
          providerLocation: _locationCtrl.text.trim(),
          title:            _titleCtrl.text.trim(),
          description:      _descCtrl.text.trim(),
          category:         _selectedCategory!,
          price:            double.parse(_priceCtrl.text.trim()),
          priceUnit:        _selectedPriceUnit,
          durationMinutes:  _durationMinutes,
          isActive:         _isActive,
          whatsIncluded:    _whatsIncluded,
          createdAt:        DateTime.now(),
        );
        await _firestore.addServiceListing(listing);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEditing ? 'Service updated!' : 'Service listed successfully!'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text(_isEditing ? 'Edit Service' : 'Add New Service'),
        titleTextStyle: AppTheme.appBarTitleStyle(color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header banner
              Container(
                width: double.infinity,
                color: AppTheme.primary,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Text(
                    _isEditing
                        ? 'Update your service details below'
                        : 'Fill in the details so customers can find and book you',
                    style: const TextStyle(
                        fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Service Title ─────────────────────────────────────
                    _FormSection(
                      title: 'Service Title',
                      required: true,
                      child: AppTextField(
                        label: '',
                        hint: 'e.g. Deep Home Cleaning, AC Repair & Refill',
                        controller: _titleCtrl,
                        prefixIcon: Icons.title_rounded,
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? 'Please enter a title'
                            : v!.trim().length < 5
                                ? 'Title too short'
                                : null,
                      ),
                    ),

                    // ── Category ──────────────────────────────────────────
                    _FormSection(
                      title: 'Category',
                      required: true,
                      child: StreamBuilder<List<ServiceCategory>>(
                        stream: _firestore.getCategories(),
                        builder: (context, snapshot) {
                          final liveCats = snapshot.data ?? [];
                          // When editing, ensure the current category is always
                          // included even if admin deactivated it
                          final allCats = _isEditing && _selectedCategory != null &&
                              !liveCats.any((c) => c.name == _selectedCategory)
                              ? [
                                  ServiceCategory(
                                    id: '',
                                    name: _selectedCategory!,
                                    icon: '',
                                    color: '',
                                    description: '',
                                    serviceCount: 0,
                                  ),
                                  ...liveCats,
                                ]
                              : liveCats;
                          // Auto-select first category when adding new listing
                          if (_selectedCategory == null && allCats.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && _selectedCategory == null) {
                                setState(() => _selectedCategory = allCats.first.name);
                              }
                            });
                          }
                          return DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppTheme.divider)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppTheme.divider)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                      color: AppTheme.primary, width: 2)),
                              prefixIcon: const Icon(Icons.category_outlined,
                                  color: AppTheme.textLight, size: 20),
                            ),
                            hint: const Text('Select a category'),
                            items: allCats
                                .map((c) => DropdownMenuItem(
                                      value: c.name,
                                      child: Row(children: [
                                        Icon(categoryIconFor(c.name),
                                            size: 20,
                                            color: AppTheme.primary),
                                        const SizedBox(width: 10),
                                        Text(c.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w500)),
                                      ]),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCategory = v),
                          );
                        },
                      ),
                    ),

                    // ── Description ───────────────────────────────────────
                    _FormSection(
                      title: 'Description',
                      required: true,
                      hint: 'Customers read this before booking',
                      child: AppTextField(
                        label: '',
                        hint:
                            'What does your service include? What problems do you solve?',
                        controller: _descCtrl,
                        maxLines: 4,
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? 'Please add a description'
                            : v!.trim().length < 20
                                ? 'Too short — add more detail'
                                : null,
                      ),
                    ),

                    // ── Location ──────────────────────────────────────────
                    _FormSection(
                      title: 'Your Service Location',
                      required: true,
                      hint: 'सेवा क्षेत्र निवडा / Select your service area',
                      child: GestureDetector(
                        onTap: _pickLocation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _locationCtrl.text.isEmpty && _submitted
                                  ? AppTheme.error
                                  : AppTheme.divider,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  color: AppTheme.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _locationCtrl.text.isEmpty
                                      ? 'Location निवडा...'
                                      : _locationCtrl.text,
                                  style: TextStyle(
                                    color: _locationCtrl.text.isEmpty
                                        ? AppTheme.textLight
                                        : AppTheme.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const Icon(Icons.expand_more_rounded,
                                  color: AppTheme.textLight),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Contact Phone ──────────────────────────────────────
                    _FormSection(
                      title: 'Contact Number',
                      required: true,
                      hint: 'Customers will call you on this number',
                      child: AppTextField(
                        label: '',
                        hint: '+91 98765 43210',
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? 'Please enter your contact number'
                            : null,
                      ),
                    ),

                    // ── Pricing ───────────────────────────────────────────
                    _FormSection(
                      title: 'Pricing',
                      required: true,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: AppTextField(
                              label: '',
                              hint: '0',
                              controller: _priceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: false),
                              prefixIcon: Icons.currency_rupee_rounded,
                              validator: (v) {
                                if (v?.trim().isEmpty ?? true) {
                                  return 'Enter price';
                                }
                                final n = double.tryParse(v!.trim());
                                if (n == null || n <= 0) return 'Invalid price';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 4,
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedPriceUnit,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                        color: AppTheme.divider)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                        color: AppTheme.divider)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                        color: AppTheme.primary, width: 2)),
                              ),
                              items: _priceUnits
                                  .map((u) => DropdownMenuItem(
                                      value: u, child: Text(u)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedPriceUnit = v!),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Duration ──────────────────────────────────────────
                    _FormSection(
                      title: 'Estimated Duration',
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _durationMinutes < 60
                                    ? '$_durationMinutes min'
                                    : _durationMinutes % 60 == 0
                                        ? '${_durationMinutes ~/ 60} hr'
                                        : '${_durationMinutes ~/ 60} hr ${_durationMinutes % 60} min',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary),
                              ),
                              Row(children: [
                                _DurationBtn(
                                  icon: Icons.remove_rounded,
                                  onTap: () {
                                    if (_durationMinutes > 30) {
                                      setState(() => _durationMinutes -= 30);
                                    }
                                  },
                                ),
                                const SizedBox(width: 12),
                                _DurationBtn(
                                  icon: Icons.add_rounded,
                                  onTap: () =>
                                      setState(() => _durationMinutes += 30),
                                ),
                              ]),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppTheme.primary,
                              thumbColor: AppTheme.primary,
                              overlayColor: AppTheme.primary.withValues(alpha: 0.1),
                              inactiveTrackColor: AppTheme.divider,
                            ),
                            child: Slider(
                              value: _durationMinutes.toDouble(),
                              min: 30,
                              max: 480,
                              divisions: 15,
                              onChanged: (v) =>
                                  setState(() => _durationMinutes = v.toInt()),
                            ),
                          ),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('30 min',
                                  style: TextStyle(
                                      fontSize: 11, color: AppTheme.textLight)),
                              Text('8 hrs',
                                  style: TextStyle(
                                      fontSize: 11, color: AppTheme.textLight)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── What's Included ───────────────────────────────────
                    _FormSection(
                      title: "What's Included",
                      hint:
                          "Shown to customers on this listing's detail page. Optional — a default checklist is used if you leave this empty.",
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12)
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < _whatsIncluded.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded,
                                        size: 18, color: AppTheme.accent),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _whatsIncluded[i],
                                        style: const TextStyle(
                                            fontSize: 13.5,
                                            color: AppTheme.textPrimary),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _removeIncludedItem(i),
                                      child: const Icon(
                                          Icons.close_rounded,
                                          size: 18,
                                          color: AppTheme.textLight),
                                    ),
                                  ],
                                ),
                              ),
                            if (_whatsIncluded.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 10),
                                child: Text(
                                  'No items yet — add what your service includes, or leave blank to use the default checklist.',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      color: AppTheme.textLight,
                                      fontStyle: FontStyle.italic),
                                ),
                              ),
                            const Divider(color: AppTheme.divider, height: 1),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _newItemCtrl,
                                    onSubmitted: (_) => _addIncludedItem(),
                                    decoration: InputDecoration(
                                      hintText: 'e.g. Free re-visit if not satisfied',
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 12),
                                      filled: true,
                                      fillColor: AppTheme.surface,
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _addIncludedItem,
                                  child: Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.accentGradient,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.add_rounded,
                                        color: Colors.white, size: 22),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Visibility toggle ─────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12)
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: AppTheme.accentGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.visibility_outlined,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Visible to customers',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15)),
                                Text(
                                  'Turn off to temporarily hide this service',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isActive,
                            onChanged: (v) => setState(() => _isActive = v),
                            activeThumbColor: AppTheme.primary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Preview card ──────────────────────────────────────
                    const Text('Preview',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary)),
                    const SizedBox(height: 12),
                    _buildPreviewCard(),

                    const SizedBox(height: 28),

                    GradientButton(
                      label: _isEditing ? 'Update Service' : 'Publish Service',
                      onTap: _save,
                      isLoading: _saving,
                      icon: _isEditing
                          ? Icons.check_rounded
                          : Icons.rocket_launch_rounded,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final catIcon  = categoryIconFor(_selectedCategory ?? '');
    final catColor = AppTheme.primary;
    final catLabel = _selectedCategory ?? 'Select category';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.08), blurRadius: 16)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58, height: 58,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                    child: Icon(catIcon, size: 32, color: catColor)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleCtrl.text.isNotEmpty
                          ? _titleCtrl.text
                          : 'Your service title',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(catLabel,
                        style: TextStyle(
                            fontSize: 11,
                            color: catColor,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _priceCtrl.text.isNotEmpty ? '₹${_priceCtrl.text}' : '₹0',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary),
                  ),
                  Text(_selectedPriceUnit,
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textLight)),
                ],
              ),
            ],
          ),
          if (_locationCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.location_on_outlined,
                  size: 13, color: AppTheme.primary),
              const SizedBox(width: 5),
              Text(_locationCtrl.text,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ]),
          ],
          if (_phoneCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.phone_outlined,
                  size: 13, color: AppTheme.primary),
              const SizedBox(width: 5),
              Text(_phoneCtrl.text,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ]),
          ],
        ],
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────
class _FormSection extends StatelessWidget {
  final String title;
  final Widget child;
  final bool required;
  final String? hint;

  const _FormSection({
    required this.title,
    required this.child,
    this.required = false,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary)),
            if (required)
              const Text(' *',
                  style: TextStyle(color: AppTheme.error, fontSize: 14)),
          ]),
          if (hint != null) ...[
            const SizedBox(height: 3),
            Text(hint!,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textLight)),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DurationBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _DurationBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          gradient: AppTheme.accentGradient,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}