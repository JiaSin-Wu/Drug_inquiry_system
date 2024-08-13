import 'package:flutter/material.dart';

class DrugCardWidget extends StatefulWidget {
  const DrugCardWidget({
    super.key,
    required this.favoriteDrugNames,
    required this.item,
    required this.imgSrc,
  });

  final List<String> favoriteDrugNames;
  final Map<String, dynamic> item;
  final String imgSrc;

  @override
  State<DrugCardWidget> createState() => _DrugCardWidgetState();
}

class _DrugCardWidgetState extends State<DrugCardWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Row(
        children: [
          IconButton(
              onPressed: () {
                setState(() {
                  if (widget.favoriteDrugNames
                      .contains(widget.item['chinese_name'])) {
                    widget.favoriteDrugNames
                        .remove(widget.item['chinese_name']);
                  } else {
                    widget.favoriteDrugNames.add(widget.item['chinese_name']);
                  }
                  debugPrint(widget.favoriteDrugNames.toString());
                });
              },
              icon: (widget.favoriteDrugNames
                  .contains(widget.item['chinese_name']) ==
                  true)
                  ? const Icon(Icons.favorite)
                  : const Icon(Icons.favorite_border)),
          Expanded(
            child: ListTile(
              title: Text(widget.item["chinese_name"]),
              subtitle: Text(widget.item["indication"]),
            ),
          ),
          Image.network(
            widget.imgSrc,
            width: 100,
            height: 100,
          )
        ],
      ),
    );
  }
}