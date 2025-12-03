class PredictionResult {
  // La predicción se mapea como int (0 o 1) según tu estructura
  final int prediction; 
  // Campo que contendrá la decisión final (IPO o NO IPO)
  final String result; 
  final double confidence;
  // Usamos reportFile para que coincida con tu modelo existente
  final String reportFile; 

  PredictionResult({
    required this.prediction,
    required this.result,
    required this.confidence,
    required this.reportFile,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      // Mapeamos a int
      prediction: json['prediction'] as int, 
      // Campo de resultado categórico (necesario para guardar metadatos)
      result: json['IPO_NO_IPO'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      // Mapeamos desde 'report_file'
      reportFile: json['report_file'] as String, 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prediction': prediction,
      'IPO_NO_IPO': result,
      'confidence': confidence,
      'report_file': reportFile,
    };
  }
}