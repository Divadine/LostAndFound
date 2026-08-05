
import 'package:lost_and_found/repository/Auth_repository.dart';
import 'package:lost_and_found/models/authmodels/pincode_details_model.dart';


class AddressControllers {
  final AuthRepository authRepository;
  AddressControllers({required this.authRepository});

  Future<PinCodeDetailsModel?> getAddressByPincode(String pincode) async {
    final response = await authRepository.getAddressByPinCode( pinCode: pincode);
    print('!!!!!!!!!!@@@@@@@@@@#################  $response');
    if (response.status == 1) {
      print('@@@@@@@@@@@@@@@@@@@@@@------------>.   response data ${response.data}');
      return response.data;
    }
    return null;
  }


}