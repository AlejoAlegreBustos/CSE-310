import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report_model.dart';
import '../services/api_service.dart'; // Asegúrate de tener esta importación

class ReportsProvider extends ChangeNotifier {
  // Instancia del ApiService para la descarga
  final ApiService _apiService = ApiService(); 

  final List<ReportModel> _reports = [];
  bool _isLoading = false;
  String? _errorMessage; // Nuevo campo para manejar errores

  List<ReportModel> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage; // Getter para el error

  // --- 1. Lógica para cargar reportes (desde Supabase) ---
  Future<void> loadReports(String userId) async {
    _isLoading = true;
    _errorMessage = null; // Limpiar error anterior
    notifyListeners();

    try {
      final res = await Supabase.instance.client
          .from('reports')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _reports.clear();
      for (var item in res) {
        // Asegúrate de que el ReportModel.fromJson maneje todos los campos de Supabase
        _reports.add(ReportModel.fromJson(item)); 
      }

    } on PostgrestException catch (e) {
      _errorMessage = 'Database Error: ${e.message}';
      debugPrint("Supabase Error: $e");
    } catch (e) {
      _errorMessage = 'Error fetching reports: $e';
      debugPrint("General Error fetching reports: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- 2. Lógica para descargar reportes (desde FastAPI) ---
  Future<void> downloadReport(String filename) async {
    try {
      // Llamada al ApiService para obtener la respuesta binaria del PDF
      final response = await _apiService.downloadReport(filename);

      if (response.statusCode == 200) {
        // La descarga es exitosa. Aquí debes añadir la lógica de guardar el archivo.
        
        // NOTA: La implementación de guardar archivos es compleja y depende de la plataforma (web, móvil).
        // Por ahora, solo confirmamos la recepción.
        debugPrint("PDF received successfully. Status: ${response.statusCode}.");

        // Idealmente, aquí notificarías al usuario (ej: un SnackBar)
        // Muestra un mensaje de éxito (esto requiere context, que no está disponible aquí)
        // Por ahora, solo log.

      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      // Manejar errores de conexión o del servidor FastAPI
      _errorMessage = 'Error downloading report: ${e.toString()}';
      debugPrint("Download Error: $e");
    }
    // No notificamos listeners después de la descarga a menos que queramos mostrar 
    // el estado de la descarga en la UI, lo cual es opcional.
  }
}