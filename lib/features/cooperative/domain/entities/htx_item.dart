import 'package:equatable/equatable.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';

class HtxItem extends Equatable {
  const HtxItem({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.description,
  });

  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? description;

  factory HtxItem.fromJson(Map<String, dynamic> json) {
    final user = asMap(json['user'] ?? json['cooperative']);
    final id = readString(json, [
      'id',
      'cooperativeUserId',
      'cooperative_user_id',
      'userId',
      'user_id',
    ]);
    final name = readString(json, [
      'name',
      'fullName',
      'full_name',
      'htxName',
      'htx_name',
      'cooperativeName',
      'cooperative_name',
    ]);
    return HtxItem(
      id: id.isNotEmpty
          ? id
          : readString(user, ['id', 'userId', 'user_id']),
      name: name.isNotEmpty
          ? name
          : readString(user, ['fullName', 'full_name', 'name']),
      address: readStringOrNull(json, ['address', 'location', 'diaChi']),
      phone: readStringOrNull(json, ['phone', 'phoneNumber', 'phone_number']),
      description: readStringOrNull(json, ['description', 'bio', 'note']),
    );
  }

  @override
  List<Object?> get props => [id];
}
