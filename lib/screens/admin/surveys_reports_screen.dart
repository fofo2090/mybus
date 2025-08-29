import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database_service.dart';
import '../../models/supervisor_evaluation_model.dart';
import '../../models/student_behavior_model.dart';

class SurveysReportsScreen extends StatefulWidget {
  const SurveysReportsScreen({super.key});

  @override
  State<SurveysReportsScreen> createState() => _SurveysReportsScreenState();
}

class _SurveysReportsScreenState extends State<SurveysReportsScreen> with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;
  
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;

  List<SupervisorEvaluationModel> _supervisorEvaluations = [];
  List<StudentBehaviorEvaluation> _behaviorEvaluations = [];
  List<Map<String, dynamic>> _supervisorSurveyReports = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('🔄 Loading reports for $_selectedMonth/$_selectedYear');

      // Load supervisor evaluations
      final supervisorEvals = await _databaseService.getSupervisorEvaluationsByMonth(_selectedMonth, _selectedYear);
      debugPrint('📊 Loaded ${supervisorEvals.length} supervisor evaluations');

      // Load behavior evaluations
      final behaviorEvals = await _databaseService.getBehaviorEvaluationsByMonth(_selectedMonth, _selectedYear);
      debugPrint('📊 Loaded ${behaviorEvals.length} behavior evaluations');

      // Load supervisor survey reports
      final supervisorSurveys = await _databaseService.getSupervisorEvaluationReports().first;
      debugPrint('📊 Loaded ${supervisorSurveys.length} supervisor survey reports');

      if (mounted) {
        setState(() {
          _supervisorEvaluations = supervisorEvals;
          _behaviorEvaluations = behaviorEvals;
          _supervisorSurveyReports = supervisorSurveys;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading reports: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل التقارير: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'تقارير الاستبيانات',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'تصفية حسب الشهر',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.analytics),
              text: 'ملخص عام',
            ),
            Tab(
              icon: Icon(Icons.supervisor_account),
              text: 'تقييم المشرفين',
            ),
            Tab(
              icon: Icon(Icons.school),
              text: 'سلوك الطلاب',
            ),
            Tab(
              icon: Icon(Icons.poll),
              text: 'استبيانات المشرفين',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Month/Year selector
          _buildMonthYearSelector(),
          
          // Tab content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('جاري تحميل التقارير...'),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildSupervisorEvaluationsTab(),
                      _buildBehaviorEvaluationsTab(),
                      _buildSupervisorSurveysTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthYearSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: Color(0xFF1E88E5)),
          const SizedBox(width: 8),
          Text(
            'التقرير لشهر:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5).withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E88E5).withAlpha(76)),
              ),
              child: Text(
                '${_getMonthName(_selectedMonth)} $_selectedYear',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E88E5),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.tune, size: 18),
            label: const Text('تغيير'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final supervisorAverage = _calculateSupervisorAverage();
    final behaviorAverage = _calculateBehaviorAverage();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'تقييمات المشرفين',
                  value: '${_supervisorEvaluations.length}',
                  subtitle: 'تقييم',
                  color: Colors.blue,
                  icon: Icons.supervisor_account,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'تقييمات السلوك',
                  value: '${_behaviorEvaluations.length}',
                  subtitle: 'تقييم',
                  color: Colors.green,
                  icon: Icons.school,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'متوسط تقييم المشرفين',
                  value: supervisorAverage.toStringAsFixed(1),
                  subtitle: 'من 5',
                  color: Colors.orange,
                  icon: Icons.star,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'متوسط سلوك الطلاب',
                  value: behaviorAverage.toStringAsFixed(1),
                  subtitle: 'من 5',
                  color: Colors.purple,
                  icon: Icons.trending_up,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Top performers
          _buildTopPerformersSection(),

          const SizedBox(height: 24),

          // Areas for improvement
          _buildImprovementAreasSection(),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withAlpha(25), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.trending_up, color: color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformersSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                SizedBox(width: 8),
                Text(
                  'أفضل الأداءات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Top supervisors
            if (_supervisorEvaluations.isNotEmpty) ...[
              Text(
                'أفضل المشرفين:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              ..._getTopSupervisors().map((eval) => _buildTopPerformerItem(
                name: eval.supervisorName,
                score: eval.averageRating,
                type: 'مشرف',
              )),
            ],

            const SizedBox(height: 16),

            // Top students
            if (_behaviorEvaluations.isNotEmpty) ...[
              Text(
                'أفضل الطلاب سلوكاً:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              ..._getTopStudents().map((eval) => _buildTopPerformerItem(
                name: eval.studentName,
                score: eval.averageRating,
                type: 'طالب',
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformerItem({
    required String name,
    required double score,
    required String type,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(
            type == 'مشرف' ? Icons.supervisor_account : Icons.school,
            color: Colors.green[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[600],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${score.toStringAsFixed(1)}/5',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementAreasSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_down, color: Colors.orange, size: 24),
                SizedBox(width: 8),
                Text(
                  'مجالات التحسين',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Low performing supervisors
            if (_supervisorEvaluations.isNotEmpty) ...[
              Text(
                'المشرفين الذين يحتاجون تحسين:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              ..._getLowPerformingSupervisors().map((eval) => _buildImprovementItem(
                name: eval.supervisorName,
                score: eval.averageRating,
                type: 'مشرف',
              )),
            ],

            const SizedBox(height: 16),

            // Students needing attention
            if (_behaviorEvaluations.isNotEmpty) ...[
              Text(
                'الطلاب الذين يحتاجون اهتمام:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              ..._getStudentsNeedingAttention().map((eval) => _buildImprovementItem(
                name: eval.studentName,
                score: eval.averageRating,
                type: 'طالب',
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImprovementItem({
    required String name,
    required double score,
    required String type,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(
            type == 'مشرف' ? Icons.supervisor_account : Icons.school,
            color: Colors.orange[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange[600],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${score.toStringAsFixed(1)}/5',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupervisorEvaluationsTab() {
    if (_supervisorEvaluations.isEmpty) {
      return _buildEmptyState('لا توجد تقييمات للمشرفين في هذا الشهر');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _supervisorEvaluations.length,
      itemBuilder: (context, index) {
        final evaluation = _supervisorEvaluations[index];
        return _buildSupervisorEvaluationCard(evaluation);
      },
    );
  }

  Widget _buildBehaviorEvaluationsTab() {
    if (_behaviorEvaluations.isEmpty) {
      return _buildEmptyState('لا توجد تقييمات سلوك في هذا الشهر');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _behaviorEvaluations.length,
      itemBuilder: (context, index) {
        final evaluation = _behaviorEvaluations[index];
        return _buildBehaviorEvaluationCard(evaluation);
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'جرب تغيير الشهر أو السنة',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupervisorEvaluationCard(SupervisorEvaluationModel evaluation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    evaluation.supervisorName.isNotEmpty ? evaluation.supervisorName[0] : 'م',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        evaluation.supervisorName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      Text(
                        'تقييم من: ${evaluation.parentName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getScoreColor(evaluation.averageRating),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${evaluation.averageRating.toStringAsFixed(1)}/5',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Ratings breakdown
            Text(
              'تفاصيل التقييم:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),

            ...evaluation.ratings.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key.displayName,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Text(
                    entry.value.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getScoreColor(entry.value.value.toDouble()),
                    ),
                  ),
                ],
              ),
            )),

            if (evaluation.comments != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'تعليق: ${evaluation.comments}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBehaviorEvaluationCard(StudentBehaviorEvaluation evaluation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.green[100],
                  child: Text(
                    evaluation.studentName.isNotEmpty ? evaluation.studentName[0] : 'ط',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        evaluation.studentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      Text(
                        'تقييم من: ${evaluation.supervisorName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getScoreColor(evaluation.averageRating),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${evaluation.averageRating.toStringAsFixed(1)}/5',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Behavior categories
            Text(
              'تقييم السلوك:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(child: _buildBehaviorItem('الانضباط', _getBehaviorRating(evaluation, BehaviorCategory.discipline))),
                const SizedBox(width: 8),
                Expanded(child: _buildBehaviorItem('الاحترام', _getBehaviorRating(evaluation, BehaviorCategory.respect))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildBehaviorItem('التعاون', _getBehaviorRating(evaluation, BehaviorCategory.cooperation))),
                const SizedBox(width: 8),
                Expanded(child: _buildBehaviorItem('النظافة', _getBehaviorRating(evaluation, BehaviorCategory.cleanliness))),
              ],
            ),

            if (evaluation.positivePoints.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'نقاط إيجابية: ${evaluation.positivePoints}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBehaviorItem(String label, int rating) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getScoreColor(rating.toDouble()).withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            '$rating/5',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getScoreColor(rating.toDouble()),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  double _calculateSupervisorAverage() {
    if (_supervisorEvaluations.isEmpty) return 0.0;
    final total = _supervisorEvaluations.map((e) => e.averageRating).reduce((a, b) => a + b);
    return total / _supervisorEvaluations.length;
  }

  double _calculateBehaviorAverage() {
    if (_behaviorEvaluations.isEmpty) return 0.0;
    final total = _behaviorEvaluations.map((e) => e.averageRating).reduce((a, b) => a + b);
    return total / _behaviorEvaluations.length;
  }

  List<SupervisorEvaluationModel> _getTopSupervisors() {
    final sorted = List<SupervisorEvaluationModel>.from(_supervisorEvaluations);
    sorted.sort((a, b) => b.averageRating.compareTo(a.averageRating));
    return sorted.take(3).toList();
  }

  List<StudentBehaviorEvaluation> _getTopStudents() {
    final sorted = List<StudentBehaviorEvaluation>.from(_behaviorEvaluations);
    sorted.sort((a, b) => b.averageRating.compareTo(a.averageRating));
    return sorted.take(3).toList();
  }

  List<SupervisorEvaluationModel> _getLowPerformingSupervisors() {
    final filtered = _supervisorEvaluations.where((e) => e.averageRating < 3.0).toList();
    filtered.sort((a, b) => a.averageRating.compareTo(b.averageRating));
    return filtered.take(3).toList();
  }

  List<StudentBehaviorEvaluation> _getStudentsNeedingAttention() {
    final filtered = _behaviorEvaluations.where((e) => e.averageRating < 3.0).toList();
    filtered.sort((a, b) => a.averageRating.compareTo(b.averageRating));
    return filtered.take(3).toList();
  }

  Color _getScoreColor(double score) {
    if (score >= 4.5) return Colors.green;
    if (score >= 3.5) return Colors.lightGreen;
    if (score >= 2.5) return Colors.orange;
    return Colors.red;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر الشهر والسنة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: _selectedMonth,
              decoration: const InputDecoration(
                labelText: 'الشهر',
                border: OutlineInputBorder(),
              ),
              items: List.generate(12, (index) {
                final month = index + 1;
                return DropdownMenuItem(
                  value: month,
                  child: Text(_getMonthName(month)),
                );
              }),
              onChanged: (value) {
                setState(() => _selectedMonth = value!);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedYear,
              decoration: const InputDecoration(
                labelText: 'السنة',
                border: OutlineInputBorder(),
              ),
              items: List.generate(5, (index) {
                final year = DateTime.now().year - 2 + index;
                return DropdownMenuItem(
                  value: year,
                  child: Text(year.toString()),
                );
              }),
              onChanged: (value) {
                setState(() => _selectedYear = value!);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadReports();
            },
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[month];
  }

  int _getBehaviorRating(StudentBehaviorEvaluation evaluation, BehaviorCategory category) {
    final rating = evaluation.ratings[category];
    if (rating == null) return 3; // Default to good

    switch (rating) {
      case BehaviorRating.excellent: return 5;
      case BehaviorRating.veryGood: return 4;
      case BehaviorRating.good: return 3;
      case BehaviorRating.fair: return 2;
      case BehaviorRating.poor: return 1;
    }
  }

  Widget _buildSupervisorSurveysTab() {
    if (_supervisorSurveyReports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.poll, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'لا توجد استبيانات تقييم مشرفين',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'سيتم عرض التقييمات هنا عندما يقوم أولياء الأمور بتقييم المشرفين',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Group surveys by supervisor
    final supervisorGroups = <String, List<Map<String, dynamic>>>{};
    for (final survey in _supervisorSurveyReports) {
      final supervisorId = survey['supervisorId'] as String? ?? '';
      if (supervisorId.isNotEmpty) {
        supervisorGroups[supervisorId] ??= [];
        supervisorGroups[supervisorId]!.add(survey);
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'إجمالي الاستبيانات',
                _supervisorSurveyReports.length.toString(),
                Icons.poll,
                const Color(0xFF1E88E5),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'المشرفين المُقيمين',
                supervisorGroups.length.toString(),
                Icons.supervisor_account,
                const Color(0xFF7C3AED),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Supervisor Evaluations List
        ...supervisorGroups.entries.map((entry) {
          final supervisorId = entry.key;
          final surveys = entry.value;
          final supervisorName = surveys.first['supervisorName'] as String? ?? 'مشرف غير معروف';

          return _buildSupervisorSurveyCard(supervisorId, supervisorName, surveys);
        }).toList(),
      ],
    );
  }

  Widget _buildSupervisorSurveyCard(String supervisorId, String supervisorName, List<Map<String, dynamic>> surveys) {
    // Calculate average ratings
    final totalSurveys = surveys.length;
    double totalRating = 0.0;
    int recommendCount = 0;

    for (final survey in surveys) {
      final answers = survey['answers'] as Map<String, dynamic>? ?? {};

      // Calculate average rating for this survey
      double surveyTotal = 0.0;
      int ratingCount = 0;

      for (final entry in answers.entries) {
        if (entry.key.contains('communication') ||
            entry.key.contains('punctuality') ||
            entry.key.contains('safety') ||
            entry.key.contains('professionalism') ||
            entry.key.contains('student_care') ||
            entry.key.contains('overall_satisfaction')) {

          final rating = double.tryParse(entry.value.toString()) ?? 0.0;
          surveyTotal += rating;
          ratingCount++;
        }
      }

      if (ratingCount > 0) {
        totalRating += surveyTotal / ratingCount;
      }

      if (answers['recommend_supervisor'] == 'نعم') {
        recommendCount++;
      }
    }

    final averageRating = totalSurveys > 0 ? totalRating / totalSurveys : 0.0;
    final recommendationRate = totalSurveys > 0 ? (recommendCount / totalSurveys) * 100 : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF7C3AED),
                  child: Text(
                    supervisorName.isNotEmpty ? supervisorName[0] : 'م',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supervisorName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      Text(
                        '$totalSurveys تقييم',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRatingColor(averageRating).withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${averageRating.toStringAsFixed(1)}/5',
                    style: TextStyle(
                      color: _getRatingColor(averageRating),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Statistics
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'التقييم العام',
                    '${averageRating.toStringAsFixed(1)}/5',
                    _getRatingColor(averageRating),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'نسبة التوصية',
                    '${recommendationRate.toStringAsFixed(0)}%',
                    recommendationRate >= 70 ? Colors.green :
                    recommendationRate >= 50 ? Colors.orange : Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showSupervisorSurveyDetails(supervisorId, supervisorName, surveys),
                    icon: const Icon(Icons.visibility),
                    label: const Text('عرض التفاصيل'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7C3AED),
                      side: const BorderSide(color: Color(0xFF7C3AED)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: averageRating < 3.0 ? () => _takeActionOnSupervisor(supervisorId, supervisorName) : null,
                    icon: const Icon(Icons.warning),
                    label: const Text('اتخاذ إجراء'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return Colors.green;
    if (rating >= 3.0) return Colors.orange;
    return Colors.red;
  }

  void _showSupervisorSurveyDetails(String supervisorId, String supervisorName, List<Map<String, dynamic>> surveys) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تفاصيل تقييم: $supervisorName'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: surveys.length,
            itemBuilder: (context, index) {
              final survey = surveys[index];
              final parentName = survey['respondentName'] as String? ?? 'ولي أمر';
              final submittedAt = survey['submittedAt'] as Timestamp?;
              final answers = survey['answers'] as Map<String, dynamic>? ?? {};

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            parentName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          if (submittedAt != null)
                            Text(
                              DateFormat('dd/MM/yyyy').format(submittedAt.toDate()),
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (answers['positive_feedback']?.toString().isNotEmpty == true)
                        Text(
                          'الجوانب الإيجابية: ${answers['positive_feedback']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      if (answers['improvement_suggestions']?.toString().isNotEmpty == true)
                        Text(
                          'اقتراحات التحسين: ${answers['improvement_suggestions']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _takeActionOnSupervisor(String supervisorId, String supervisorName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('اتخاذ إجراء ضد: $supervisorName'),
        content: const Text('هذا المشرف حصل على تقييمات منخفضة. ما الإجراء المطلوب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement warning action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إرسال تحذير للمشرف')),
              );
            },
            child: const Text('إرسال تحذير'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement suspension action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إيقاف المشرف مؤقتاً')),
              );
            },
            child: const Text('إيقاف مؤقت'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
