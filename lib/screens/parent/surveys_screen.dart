import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/survey_model.dart';
import '../../models/user_model.dart';

class SurveysScreen extends StatefulWidget {
  const SurveysScreen({super.key});

  @override
  State<SurveysScreen> createState() => _SurveysScreenState();
}

class _SurveysScreenState extends State<SurveysScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _databaseService.getUserData(user.uid);
        if (userData != null) {
          setState(() {
            _currentUser = UserModel.fromMap(userData);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'الاستبيانات',
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
            icon: const Icon(Icons.supervisor_account),
            onPressed: () {
              context.push('/parent/surveys/supervisor-evaluation');
            },
            tooltip: 'تقييم المشرفين',
          ),
        ],
      ),
      body: Column(
        children: [
          // Supervisor evaluation card
          Container(
            margin: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () {
                _showSupervisorEvaluationOptions();
              },
              child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.supervisor_account,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'تقييم المشرفين',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'قيم أداء المشرفين المسؤولين عن أطفالك',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withAlpha(230),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ),
          ),

          // Regular surveys
          Expanded(
            child: StreamBuilder<List<SurveyModel>>(
        stream: _databaseService.getActiveSurveysForUser('parent'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('خطأ في تحميل الاستبيانات: ${snapshot.error}'),
                ],
              ),
            );
          }

          final surveys = snapshot.data ?? [];

          if (surveys.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: surveys.length,
            itemBuilder: (context, index) {
              final survey = surveys[index];
              return _buildSurveyCard(survey);
            },
          );
        },
      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.poll_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد استبيانات متاحة حالياً',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم إشعارك عند توفر استبيانات جديدة',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyCard(SurveyModel survey) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.poll,
                  color: Color(0xFF1E88E5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      survey.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      survey.typeDisplayName,
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
                  color: Colors.green.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  survey.statusDisplayName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            survey.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Info Row
          Row(
            children: [
              Icon(Icons.quiz, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${survey.questions.length} سؤال',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              if (survey.expiresAt != null) ...[
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'ينتهي في ${_formatDate(survey.expiresAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Action Button
          FutureBuilder<bool>(
            future: _currentUser != null 
                ? _databaseService.hasUserRespondedToSurvey(survey.id, _currentUser!.id)
                : Future.value(false),
            builder: (context, hasRespondedSnapshot) {
              final hasResponded = hasRespondedSnapshot.data ?? false;
              
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: hasResponded ? null : () => _takeSurvey(survey),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasResponded ? Colors.grey : const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    hasResponded ? 'تم الإجابة على الاستبيان' : 'بدء الاستبيان',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'اليوم';
    } else if (difference == 1) {
      return 'غداً';
    } else if (difference > 1) {
      return 'خلال $difference أيام';
    } else {
      return 'منتهي الصلاحية';
    }
  }

  void _takeSurvey(SurveyModel survey) {
    context.push('/parent/surveys/take/${survey.id}');
  }

  void _showSupervisorEvaluationOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'تقييم المشرفين',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اختر طريقة تقييم المشرفين',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Survey Option
            _buildEvaluationOption(
              icon: Icons.poll,
              title: 'استبيان سريع',
              subtitle: 'استبيان مبسط لتقييم المشرف',
              color: const Color(0xFF1E88E5),
              onTap: () {
                Navigator.pop(context);
                _createQuickSupervisorSurvey();
              },
            ),

            const SizedBox(height: 12),

            // Detailed Evaluation Option
            _buildEvaluationOption(
              icon: Icons.supervisor_account,
              title: 'تقييم مفصل',
              subtitle: 'تقييم شامل مع تفاصيل أكثر',
              color: const Color(0xFF7C3AED),
              onTap: () {
                Navigator.pop(context);
                context.push('/parent/surveys/supervisor-evaluation');
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(76)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createQuickSupervisorSurvey() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get current user
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      // Get supervisors for this parent
      final supervisors = await _databaseService.getSupervisorsForParent(currentUser.uid);

      Navigator.pop(context); // Close loading

      if (supervisors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لم يتم العثور على مشرفين مُعينين لأطفالك'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show supervisor selection if multiple supervisors
      if (supervisors.length > 1) {
        _showSupervisorSelection(supervisors);
      } else {
        _createSurveyForSupervisor(supervisors.first);
      }
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إنشاء الاستبيان: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSupervisorSelection(List<UserModel> supervisors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر المشرف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: supervisors.map((supervisor) => ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text(supervisor.name),
            subtitle: Text(supervisor.phone),
            onTap: () {
              Navigator.pop(context);
              _createSurveyForSupervisor(supervisor);
            },
          )).toList(),
        ),
      ),
    );
  }

  Future<void> _createSurveyForSupervisor(UserModel supervisor) async {
    try {
      final currentUser = _authService.currentUser!;

      final surveyId = await _databaseService.createSupervisorEvaluationSurvey(
        supervisorId: supervisor.id,
        supervisorName: supervisor.name,
        parentId: currentUser.uid,
        parentName: currentUser.displayName ?? 'ولي الأمر',
      );

      // Navigate to take survey
      context.push('/parent/surveys/take/$surveyId');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إنشاء الاستبيان: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
