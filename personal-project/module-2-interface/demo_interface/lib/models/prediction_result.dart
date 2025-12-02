class PredictionResult {
  final int prediction;
  final double confidence;
  final String reportFile;

  PredictionResult({
    required this.prediction,
    required this.confidence,
    required this.reportFile,
  });

  // Factory constructor para crear una instancia desde un mapa JSON.
  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      prediction: json['prediction'] as int,
      // Usamos .toDouble() porque el valor 'confidence' puede venir como entero
      // si es 1.0, pero lo necesitamos como double.
      confidence: (json['confidence'] as num).toDouble(), 
      reportFile: json['report_file'] as String,
    );
  }
}