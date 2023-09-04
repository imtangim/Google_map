import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/autocomplete.dart';

final placeResultsProvider = ChangeNotifierProvider<PlaceResults>(
  (ref) {
    return PlaceResults();
  },
);

final searchToggleProvider = ChangeNotifierProvider<SearchToggle>(
  (ref) {
    return SearchToggle();
  },
);

class PlaceResults extends ChangeNotifier {
  List<AutoCompleteResult> allReturns = [];
  void setResults(allplace) {
    allReturns = allplace;
    notifyListeners();
  }
}

class SearchToggle extends ChangeNotifier {
  bool searchToggle = false;
  void toggleSearch() {
    searchToggle = !searchToggle;
    notifyListeners();
  }
}


