class ReportModel {
  final String id;
  final String title;
  final String createdAt;
  final Map<String, dynamic> data;

  ReportModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.data,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'],
      title: json['title'],
      createdAt: json['created_at'],
      data: json['data'], // tu JSON completo del reporte
    );
  }
}
