import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'drug_information_page.dart';

class FavoritePage extends StatelessWidget {
  final List<int> favoriteDrugNames;

  const FavoritePage({
    super.key,
    required this.favoriteDrugNames,
  });

  Future<List<Map<String, dynamic>>> fetchFavoriteDrugs() async {
    // Assuming you have an endpoint to fetch drugs by their IDs
    final response =
    await http.post(
      Uri.parse('http://10.0.2.2:3009/get_favorite_drugs'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(<String, dynamic>{
        'drugIds': favoriteDrugNames,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw Exception('Failed to load favorite drugs');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorite Drugs"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchFavoriteDrugs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No favorite drugs yet'));
          } else {
            final filteredDrugs = snapshot.data!;
            return ListView.builder(
              itemCount: filteredDrugs.length,
              itemBuilder: (BuildContext context, int index) {
                final drug = filteredDrugs[index];
                String imgSrc = drug['image_link'] ?? '';

                if (imgSrc.isEmpty) {
                  imgSrc =
                  "https://cyberdefender.hk/wp-content/uploads/2021/07/404-01-scaled.jpg";
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DrugInformationPage(
                          data: drug,
                          imgSrc: imgSrc,
                          favoriteDrugNames:favoriteDrugNames
                        ),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.network(
                            imgSrc,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: Text(
                              drug["chinese_name"].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(drug["indication"].toString()),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DrugInformationPage(
                                  data: drug,
                                  imgSrc: imgSrc,
                                  favoriteDrugNames:favoriteDrugNames
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
