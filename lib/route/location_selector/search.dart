import "package:dpip/global.dart";
import "package:dpip/model/location/location.dart";
import "package:flutter/material.dart";
import "package:material_symbols_icons/symbols.dart";

class LocationSelectorSearchDelegate extends SearchDelegate<Location> {
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
    final data = Global.location.entries.where((e) => "${e.value.city} ${e.value.town}".contains(query)).toList();

    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text("${data[index].value.city} ${data[index].value.town}"),
          onTap: () {
            close(context, data[index].value);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final data = Global.location.entries.where((e) => "${e.value.city} ${e.value.town}".contains(query)).toList();

    if (data.isEmpty || query.isEmpty) {
      return const Center(
        child: Text("無搜尋結果"),
      );
    }

    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text("${data[index].value.city} ${data[index].value.town}"),
          onTap: () {
            close(context, data[index].value);
          },
        );
      },
    );
  }
}
