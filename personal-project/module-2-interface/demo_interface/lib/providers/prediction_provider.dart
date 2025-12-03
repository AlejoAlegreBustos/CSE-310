import 'package:flutter/foundation.dart';
import 'package:demo_interface/models/prediction_result.dart';
import 'package:demo_interface/services/api_service.dart';

class PredictionProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  PredictionResult? _predictionResult; // Resultado temporal de la predicción
  bool _isLoading = false;
  String? _errorMessage;
  String? _saveMessage; // Mensaje para notificar el éxito/fallo al guardar

  // Getters
  PredictionResult? get predictionResult => _predictionResult;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get saveMessage => _saveMessage;

  // Reinicia los estados de la predicción
  void resetPredictionState() {
    _predictionResult = null;
    _errorMessage = null;
    _saveMessage = null;
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // 1. Obtiene la predicción de FastAPI (NO GUARDA en DB todavía)
  // ------------------------------------------------------------------
  Future<void> fetchPrediction(List<double> features, String userId) async {
    // Validación opcional de userId (ya no se envía al modelo, pero se usa para guardar luego)
    if (userId == 'default-anonymous-id' || userId.isEmpty) {
      _errorMessage = 'Error: No se pudo obtener el ID del usuario. Por favor, inicie sesión correctamente.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _saveMessage = null;
    notifyListeners();

    try {
      // Llama a la API y el resultado se mapea a PredictionResult
      final result = await _apiService.getPrediction(features, userId);
      _predictionResult = result;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Fallo al obtener la predicción: ${e.toString()}';
      if (kDebugMode) {
        debugPrint('Prediction Error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------
  // 2. Guarda explícitamente el reporte en la DB (Llamado por el usuario)
  // ------------------------------------------------------------------
  Future<bool> saveReport(String userId) async {
    if (_predictionResult == null) {
      _saveMessage = 'No hay resultado de predicción para guardar.';
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _saveMessage = null;
    notifyListeners();

    try {
      // Llama al nuevo método del ApiService para guardar solo los metadatos.
      // Aquí se utiliza reportFile, confidence y result del modelo temporal.
      await _apiService.saveReportMetadata(
        userId: userId,
        filename: _predictionResult!.reportFile,
        confidence: _predictionResult!.confidence,
        result: _predictionResult!.result,
      );
      
      _saveMessage = '¡Reporte guardado exitosamente en tu historial!';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _saveMessage = 'Fallo al guardar el reporte: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ------------------------------------------------------------------
  // 3. Descarga de Reporte
  // ------------------------------------------------------------------
  Future<void> downloadReport(String filename) async {
    // La implementación de la descarga debe manejar el guardado del archivo
    // en la plataforma específica (Web, Móvil, Escritorio).
    try {
      await _apiService.downloadReport(filename);
      // Aquí manejarías guardar el bodyBytes como archivo PDF en la plataforma específica.

      debugPrint("Reporte descargado exitosamente (cuerpo de bytes recibido).");
      // Añadir lógica de notificación al usuario (ej: un Snackbar)
    } catch (e) {
      debugPrint("Error al descargar el reporte: $e");
    }
  }
}