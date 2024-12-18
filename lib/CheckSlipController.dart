import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CheckSlipController {
  Future<bool> validateSlip(File imageFile) async {
    try {
      final url = Uri.parse('https://developer.easyslip.com/api/v1/verify');

      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] =
          'Bearer b5571cb1-df8b-4f28-bbf5-c61ed6ce0be5';

      request.files
          .add(await http.MultipartFile.fromPath('slip_image', imageFile.path));

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseBody);

      if (jsonResponse['status'] == 200 &&
          jsonResponse['data']['amount']['amount'] == 1500) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error validating slip: $e');
      return false;
    }
  }
}
