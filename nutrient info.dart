import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> fetchNutrientInfo(String recipeName) async {
  final String apiKey = '935a5604e2d0761de388fab38458154f';
  final String apiUrl = 'https://api.edamam.com/api/nutrition-details';

  final response = await http.post(
    Uri.parse(apiUrl),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'title': recipeName, 'ingr': []}), // Add ingredients if needed
  );

  if (response.statusCode == 200) {
    Map<String, dynamic> data = json.decode(response.body);
    return data;
  } else {
    throw Exception('Failed to load nutrient info');
  }
}

// Example usage:
void addNutrientInfoToFirebase() async {
  try {
    Map<String, dynamic> nutrientInfo = await fetchNutrientInfo('Your Recipe Name');
    // Now you have the nutrient info, you can store it in Firebase
    // Use Firebase APIs to add this data to your Firestore database
  } catch (e) {
    print('Error fetching nutrient info: $e');
  }
}
