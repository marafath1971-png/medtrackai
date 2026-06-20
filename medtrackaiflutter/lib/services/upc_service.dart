import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/utils/logger.dart';

class UPCService {
  static Future<String?> lookupBarcode(String barcode) async {
    try {
      appLogger.d('[UPCService] Looking up barcode: $barcode');
      
      // Try UPCItemDB first
      final upcResponse = await http.get(Uri.parse('https://api.upcitemdb.com/prod/trial/lookup?upc=$barcode'));
      if (upcResponse.statusCode == 200) {
        final data = json.decode(upcResponse.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          final title = data['items'][0]['title'];
          if (title != null && title.isNotEmpty) {
            appLogger.i('[UPCService] Found via UPCItemDB: $title');
            return title;
          }
        }
      }

      // Fallback to OpenFoodFacts (for supplements/vitamins)
      final offResponse = await http.get(Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json'));
      if (offResponse.statusCode == 200) {
        final data = json.decode(offResponse.body);
        if (data['product'] != null && data['product']['product_name'] != null) {
          final name = data['product']['product_name'];
          appLogger.i('[UPCService] Found via OpenFoodFacts: $name');
          return name;
        }
      }

      appLogger.w('[UPCService] Barcode not found in any public database.');
      return null;
    } catch (e) {
      appLogger.e('[UPCService] Error looking up barcode: $e');
      return null;
    }
  }
}
