
import '../services/api_client.dart';
import '../models/address.dart';

class AddressService {
  static const String _base = '/api/customer/addresses';

  Future<List<Address>> getAddresses() async {
    final body = await ApiClient.getJson(
      _base,
      authenticated: true,
    );

    final data = body['data'];

    if (data is! List) {
      throw ApiException('Invalid addresses response');
    }

    return data
        .whereType<Map>()
        .map(
          (item) => Address.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<Address> addAddress(Address address) async {
    final response = await ApiClient.postJson(
      _base,
      address.toJson(),
      authenticated: true,
    );

    return _addressFromResponse(response, 'add');
  }

  Future<Address> updateAddress(Address address) async {
    final id = address.id;

    if (id == null || id.isEmpty) {
      throw ApiException('Address ID is missing');
    }

    final response = await ApiClient.putJson(
      '$_base/$id',
      address.toJson(),
      authenticated: true,
    );

    return _addressFromResponse(response, 'update');
  }

  Future<void> deleteAddress(String id) async {
    final response = await ApiClient.deleteJson(
      '$_base/$id',
      authenticated: true,
    );

    if (!response.ok) {
      throw ApiException(
        response.body['message']?.toString() ??
            'Failed to delete address',
        response.status,
      );
    }
  }

  Address _addressFromResponse(
    ApiResponse response,
    String action,
  ) {
    if (!response.ok) {
      throw ApiException(
        response.body['message']?.toString() ??
            'Failed to $action address',
        response.status,
      );
    }

    final data = response.body['data'];

    if (data is! Map) {
      throw ApiException('Invalid address response');
    }

    return Address.fromJson(
      Map<String, dynamic>.from(data),
    );
  }
}
