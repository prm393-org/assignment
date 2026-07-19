import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/utils/nominatim_geocode.dart';
import 'package:chuoi_xanh_viet/core/utils/vietnam_address_api.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/entities/farm.dart';
import 'package:chuoi_xanh_viet/features/farm/presentation/providers/farm_providers.dart';
import 'package:chuoi_xanh_viet/features/upload/presentation/providers/upload_providers.dart';

class FarmFormScreen extends ConsumerStatefulWidget {
  const FarmFormScreen({super.key, this.farm});
  final Farm? farm;

  @override
  ConsumerState<FarmFormScreen> createState() => _FarmFormScreenState();
}

class _FarmFormScreenState extends ConsumerState<FarmFormScreen> {
  final _name = TextEditingController();
  final _area = TextEditingController();
  final _crop = TextEditingController();
  final _address = TextEditingController();
  final _lat = TextEditingController(text: '10.76');
  final _lng = TextEditingController(text: '106.66');
  final _imageUrl = TextEditingController();
  final _addressApi = VietnamAddressApi();
  final _geocode = NominatimGeocode();

  List<VnProvince> _provinces = [];
  List<VnDistrict> _districts = [];
  List<VnWard> _wards = [];
  int? _provinceCode;
  int? _districtCode;
  int? _wardCode;
  bool _loading = false;
  bool _uploading = false;
  bool _loadingAddress = false;
  bool _loadingGps = false;
  bool _loadingGeocode = false;

  @override
  void initState() {
    super.initState();
    final f = widget.farm;
    if (f != null) {
      _name.text = f.name;
      _area.text = '${f.areaHa}';
      _crop.text = f.cropMain;
      _address.text = f.address ?? '';
      _lat.text = '${f.latitude ?? 10.76}';
      _lng.text = '${f.longitude ?? 106.66}';
      _provinceCode = f.provinceCode;
      _districtCode = f.districtCode;
      _wardCode = f.wardCode;
    }
    _loadProvinces();
  }

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    _crop.dispose();
    _address.dispose();
    _lat.dispose();
    _lng.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _loadProvinces() async {
    setState(() => _loadingAddress = true);
    try {
      final list = await _addressApi.getProvinces();
      setState(() => _provinces = list);
      if (_provinceCode != null) {
        await _loadDistricts(_provinceCode!, keepSelection: true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được danh mục địa chỉ: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  Future<void> _loadDistricts(int provinceCode, {bool keepSelection = false}) async {
    setState(() {
      _provinceCode = provinceCode;
      if (!keepSelection) {
        _districtCode = null;
        _wardCode = null;
        _wards = [];
      }
      _loadingAddress = true;
    });
    try {
      final list = await _addressApi.getDistricts(provinceCode);
      setState(() => _districts = list);
      if (_districtCode != null) {
        await _loadWards(_districtCode!, keepSelection: keepSelection);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được quận/huyện: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  Future<void> _loadWards(int districtCode, {bool keepSelection = false}) async {
    setState(() {
      _districtCode = districtCode;
      if (!keepSelection) _wardCode = null;
      _loadingAddress = true;
    });
    try {
      final list = await _addressApi.getWards(districtCode);
      setState(() => _wards = list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được phường/xã: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final urls =
          await ref.read(uploadRepositoryProvider).uploadImages([file.path]);
      if (urls.isNotEmpty) {
        setState(() => _imageUrl.text = urls.first);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _getGps() async {
    setState(() => _loadingGps = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const ValidationFailure('Cần quyền truy cập vị trí');
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _lat.text = pos.latitude.toStringAsFixed(6);
        _lng.text = pos.longitude.toStringAsFixed(6);
      });
      final rev = await _geocode.reverse(pos.latitude, pos.longitude);
      if (rev?.displayName != null && _address.text.trim().isEmpty) {
        setState(() => _address.text = rev!.displayName!);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    } finally {
      if (mounted) setState(() => _loadingGps = false);
    }
  }

  Future<void> _geocodeAddress() async {
    final query = [
      _address.text.trim(),
      _wards.where((w) => w.code == _wardCode).map((w) => w.name).firstOrNull,
      _districts
          .where((d) => d.code == _districtCode)
          .map((d) => d.name)
          .firstOrNull,
      _provinces
          .where((p) => p.code == _provinceCode)
          .map((p) => p.name)
          .firstOrNull,
      'Việt Nam',
    ].whereType<String>().where((e) => e.isNotEmpty).join(', ');

    if (query.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập địa chỉ để geocode')),
      );
      return;
    }
    setState(() => _loadingGeocode = true);
    try {
      final result = await _geocode.search(query);
      if (result == null) {
        throw const ValidationFailure('Không tìm thấy tọa độ');
      }
      setState(() {
        _lat.text = result.latitude.toStringAsFixed(6);
        _lng.text = result.longitude.toStringAsFixed(6);
        if (result.displayName != null && _address.text.trim().isEmpty) {
          _address.text = result.displayName!;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    } finally {
      if (mounted) setState(() => _loadingGeocode = false);
    }
  }

  Future<void> _save() async {
    if (_provinceCode == null || _districtCode == null || _wardCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn đủ Tỉnh / Quận / Phường')),
      );
      return;
    }
    setState(() => _loading = true);
    final provinceName =
        _provinces.where((p) => p.code == _provinceCode).firstOrNull?.name ?? '';
    final districtName =
        _districts.where((d) => d.code == _districtCode).firstOrNull?.name ?? '';
    final wardName =
        _wards.where((w) => w.code == _wardCode).firstOrNull?.name ?? '';
    final body = {
      'name': _name.text.trim(),
      'area_ha': double.tryParse(_area.text) ?? 0,
      'crop_main': _crop.text.trim(),
      'in_cooperative': false,
      'province': provinceName,
      'district': districtName,
      'ward': wardName,
      'province_code': _provinceCode,
      'district_code': _districtCode,
      'ward_code': _wardCode,
      'address': _address.text.trim(),
      'latitude': double.tryParse(_lat.text) ?? 0,
      'longitude': double.tryParse(_lng.text) ?? 0,
      if (_imageUrl.text.trim().isNotEmpty)
        'image_url': _imageUrl.text.trim(),
    };
    try {
      final repo = ref.read(farmRepositoryProvider);
      if (widget.farm == null) {
        await repo.createFarm(body);
      } else {
        await repo.updateFarm(widget.farm!.id, body);
      }
      ref.invalidate(myFarmsProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.farm == null ? 'Tạo nông trại' : 'Sửa nông trại'),
      ),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Tên nông trại'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _area,
            decoration: const InputDecoration(labelText: 'Diện tích (ha)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _crop,
            decoration: const InputDecoration(labelText: 'Cây trồng chính'),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<int>(
            value: _provinceCode,
            decoration: const InputDecoration(labelText: 'Tỉnh/TP'),
            items: [
              for (final p in _provinces)
                DropdownMenuItem(value: p.code, child: Text(p.name)),
            ],
            onChanged: _loadingAddress
                ? null
                : (v) {
                    if (v != null) _loadDistricts(v);
                  },
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<int>(
            value: _districtCode,
            decoration: const InputDecoration(labelText: 'Quận/Huyện'),
            items: [
              for (final d in _districts)
                DropdownMenuItem(value: d.code, child: Text(d.name)),
            ],
            onChanged: _loadingAddress || _provinceCode == null
                ? null
                : (v) {
                    if (v != null) _loadWards(v);
                  },
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<int>(
            value: _wardCode,
            decoration: const InputDecoration(labelText: 'Phường/Xã'),
            items: [
              for (final w in _wards)
                DropdownMenuItem(value: w.code, child: Text(w.name)),
            ],
            onChanged: _loadingAddress || _districtCode == null
                ? null
                : (v) => setState(() => _wardCode = v),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _address,
            decoration: const InputDecoration(labelText: 'Địa chỉ chi tiết'),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loadingGps ? null : _getGps,
                  icon: _loadingGps
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: const Text('Lấy GPS'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loadingGeocode ? null : _geocodeAddress,
                  icon: _loadingGeocode
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: const Text('Geocode địa chỉ'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _lat,
            decoration: const InputDecoration(labelText: 'Vĩ độ'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _lng,
            decoration: const InputDecoration(labelText: 'Kinh độ'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _imageUrl,
            decoration: const InputDecoration(labelText: 'URL ảnh'),
            readOnly: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _uploading ? null : _pickAndUpload,
            icon: _uploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.photo_library_outlined),
            label: Text(_uploading ? 'Đang tải...' : 'Chọn & tải ảnh'),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _loading ? null : _save,
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
