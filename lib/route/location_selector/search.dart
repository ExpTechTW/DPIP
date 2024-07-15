import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class LocationSelectorSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget>? buildActions(BuildContext context) {
    if (query.isNotEmpty) {
      return [
        IconButton(
          icon: const Icon(Symbols.clear),
          onPressed: () {
            query = "";
          },
        )
      ];
    }

    return null;
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return const BackButton();
  }

  @override
  Widget buildResults(BuildContext context) {
    return ListView();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return ListView();
  }
}
