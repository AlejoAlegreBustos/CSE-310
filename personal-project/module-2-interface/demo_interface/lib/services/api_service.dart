import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:demo_interface/models/prediction_result.dart';

class ApiService {
  // === URL de tu servicio en Render ===
  final String baseUrl = "https://invest-app-72ob.onrender.com";

  // -----------------------------------------------------------------
  // 1. Endpoint POST: /predict (Ya corregido)
  // -----------------------------------------------------------------
  Future<PredictionResult> getPrediction(List<dynamic> features) async {
    final url = Uri.parse('$baseUrl/predict');
    final headers = {'Content-Type': 'application/json'};

    final body = jsonEncode({'features': features});

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PredictionResult.fromJson(data);
    } else {
      throw Exception(
        'Failed to get prediction. Status: ${response.statusCode}. Body: ${response.body}',
      );
    }
  }

  // -----------------------------------------------------------------
  // 2. Endpoint GET: /download/{filename} (Ya implementado)
  // -----------------------------------------------------------------
  Future<http.Response> downloadReport(String filename) async {
    final url = Uri.parse('$baseUrl/download/$filename');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return response;
    } else {
      throw Exception('Failed to download report: ${response.statusCode}');
    }
  }

  // -----------------------------------------------------------------
  // 3. NUEVO ENDPOINT: fetchUserReports (Para listar reportes)
  // -----------------------------------------------------------------
  /// Llama al API para obtener la lista de reportes asociados a un userId.
  /// Asume un endpoint en el backend como /reports?user_id=...
  Future<List<Map<String, dynamic>>> fetchUserReports(String userId) async {
    // Construye la URL con el parámetro de consulta (query parameter)
    final url = Uri.parse('$baseUrl/reports').replace(
      queryParameters: {'user_id': userId},
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      // Decodifica la respuesta esperada (una lista de objetos JSON)
      final List<dynamic> jsonList = jsonDecode(response.body);

      // Mapea la lista dinámica a List<Map<String, dynamic>>
      // Esto es lo que el ReportsProvider espera para crear los ReportModel.
      return jsonList.map((item) => item as Map<String, dynamic>).toList();
    } else {
      throw Exception(
        'Failed to load user reports. Status: ${response.statusCode}. Body: ${response.body}',
      );
    }
  }
}