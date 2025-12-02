// lib/models/report_model.dart

class ReportModel {
  final String id;
  final String title;
  final DateTime createdAt; // Cambiado a DateTime
  
  // Campos de Predicción y Archivo
  final String reportFile; // Nombre del archivo PDF
  final String predictionResult; // Ejemplo: 'Éxito' o 'Fallo'
  final double confidence; // Nivel de confianza del modelo
  
  final Map<String, dynamic> data; // El JSON de entrada completo (features)

  ReportModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.reportFile,
    required this.predictionResult,
    required this.confidence,
    required this.data,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    // Función auxiliar para parsear la fecha (maneja strings de fecha)
    DateTime parseDate(dynamic date) {
      if (date is String) {
        try {
          return DateTime.parse(date);
        } catch (_) {
          // Si el parseo falla, retorna la fecha actual como fallback
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return ReportModel(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: parseDate(json['created_at']), 
      
      // Mapeo de los nuevos campos de predicción
      reportFile: json['report_file'] as String,
      predictionResult: json['prediction_result'] as String,
      // Usamos 'num' para manejar de forma segura tanto int como double que vienen del JSON
      confidence: (json['confidence'] as num).toDouble(), 
      
      data: json['data'] as Map<String, dynamic>,
    );
  }
}