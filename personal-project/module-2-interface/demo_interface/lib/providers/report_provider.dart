import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report_model.dart';

class ReportsProvider extends ChangeNotifier {
  final List<ReportModel> _reports = [];
  bool isLoading = false;

  List<ReportModel> get reports => _reports;

  Future<void> loadReports(String userId) async {
    try {
      isLoading = true;
      notifyListeners();

      final res = await Supabase.instance.client
          .from('reports')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _reports.clear();
      for (var item in res) {
        _reports.add(ReportModel.fromJson(item));
      }

    } catch (e) {
      debugPrint("Error fetching reports: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
