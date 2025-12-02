import 'package:flutter/material.dart';
import '../models/prediction_result.dart';
import '../services/api_service.dart';

// Este es el gestor de estado que usarás en tus widgets (con Consumer o Provider.of)
class PredictionProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  PredictionResult? _result;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters para acceder al estado desde los widgets
  PredictionResult? get result => _result;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Función principal para obtener la predicción
  Future<void> fetchPrediction(List<dynamic> features) async {
    _isLoading = true;
    _errorMessage = null;
    _result = null;
    notifyListeners(); // Notifica que la carga ha comenzado

    try {
      // Llama al servicio de red
      // Asegúrate de que el ApiService también acepte List<dynamic>
      final data = await _apiService.getPrediction(features);
      _result = data;
    } catch (e) {
      // Captura y almacena cualquier error de conexión o API
      _errorMessage = e.toString();
      print("Error during prediction: $_errorMessage");
    } finally {
      _isLoading = false;
      notifyListeners(); // Notifica que la carga ha terminado
    }
  }

  // Función para descargar el PDF (opcionalmente)
  Future<void> downloadReport(String filename) async {
    try {
      final response = await _apiService.downloadReport(filename);
      // Aquí manejarías guardar el 'response.bodyBytes' como un archivo .pdf en el dispositivo del usuario.

      // NOTA: La lógica para guardar el archivo difiere entre web, móvil y escritorio.
      // Si quieres ayuda para implementar la descarga en una plataforma específica, házmelo saber.

      print("Reporte descargado exitosamente (Cuerpo de bytes recibido).");
      // Añadir lógica de notificación al usuario (ej: un Snackbar)
    } catch (e) {
      print("Error al descargar el reporte: $e");
    }
  }
}
