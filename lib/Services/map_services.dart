import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

import 'package:map_tutorial/models/autocomplete.dart';

class MapServices {
  final String key = 'AIzaSyDbk1PJ_BkhMXYG-1lNEgfYL_5NNpwdzVE';
  final String types = 'geocode';

  Future<List<AutoCompleteResult>> searchplaces(String searchinput) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$searchinput&types=$types&key=$key';

    var response = await http.get(Uri.parse(url));

    var json = convert.jsonDecode(response.body);

    var results = json['predictions'] as List;
    
    return results.map((e) => AutoCompleteResult.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getPlace(String? input) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$input&key=$key';

    var response = await http.get(Uri.parse(url));

    var json = convert.jsonDecode(response.body);

    var results = json['result'] as Map<String, dynamic>;

    return results;
  }
}
