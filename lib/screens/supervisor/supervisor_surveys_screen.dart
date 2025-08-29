import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/survey_model.dart';
import '../../models/user_model.dart';

class SupervisorSurveysScreen extends StatefulWidget {
  const SupervisorSurveysScreen({super.key});

  @override
  State<SupervisorSurveysScreen> createState() => _SupervisorSurveysScreenState();
}

class _SupervisorSurveysScreenState extends State<SupervisorSurveysScreen> {
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
          'الاستبيانات الشهرية',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF7C3AED),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Header with create survey option
          _buildHeader(),

          // Surveys list
          Expanded(
            child: StreamBuilder<List<SurveyModel>>(
              stream: _databaseService.getActiveSurveysForUser('supervisor'),
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
                  return _buildEmptyStateWithAction();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: surveys.length + 1, // +1 for create new survey card
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildCreateSurveyCard();
                    }
                    final survey = surveys[index - 1];
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7C3AED).withAlpha(25),
            const Color(0xFF6D28D9).withAlpha(51),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الاستبيانات الشهرية',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                      Text(
                        'تقييم أداء وسلوك الطلاب',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWithAction() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد استبيانات شهرية متاحة حالياً',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يمكنك إنشاء استبيان جديد لتقييم الطلاب',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createMonthlySurvey,
            icon: const Icon(Icons.add),
            label: const Text('إنشاء استبيان شهري'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateSurveyCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: _createMonthlySurvey,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF7C3AED).withAlpha(76),
              width: 2,
              style: BorderStyle.solid,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withAlpha(25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_circle_outline,
                  color: Color(0xFF7C3AED),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إنشاء استبيان شهري جديد',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'إنشاء استبيان لتقييم أداء وسلوك الطلاب',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
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
                  color: const Color(0xFF7C3AED).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.assignment,
                  color: Color(0xFF7C3AED),
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
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'استبيان شهري',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
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
                    backgroundColor: hasResponded ? Colors.grey : const Color(0xFF7C3AED),
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
    context.push('/supervisor/take-survey/${survey.id}');
  }

  Future<void> _createMonthlySurvey() async {
    try {
      // Get current user info
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      // Create monthly survey with student evaluation questions
      final now = DateTime.now();
      final monthName = _getMonthName(now.month);
      final year = now.year;

      final survey = SurveyModel(
        id: '',
        title: 'استبيان شهري - $monthName $year',
        description: 'تقييم شهري لأداء وسلوك الطلاب في الباص المدرسي',
        type: SurveyType.supervisorMonthly,
        status: SurveyStatus.active,
        createdBy: currentUser.uid,
        createdByName: currentUser.displayName ?? 'المشرف',
        questions: _getMonthlyQuestions(),
        createdAt: now,
        updatedAt: now,
        expiresAt: DateTime(now.year, now.month + 1, 0), // End of current month
        isActive: true,
      );

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Create survey in database
      await _databaseService.createSurvey(survey);

      // Close loading
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء الاستبيان الشهري بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إنشاء الاستبيان: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<SurveyQuestion> _getMonthlyQuestions() {
    return [
      const SurveyQuestion(
        id: 'student_behavior',
        question: 'كيف تقيم سلوك الطلاب بشكل عام هذا الشهر؟',
        type: QuestionType.rating,
        isRequired: true,
        order: 1,
      ),
      const SurveyQuestion(
        id: 'punctuality',
        question: 'مدى التزام الطلاب بمواعيد الباص',
        type: QuestionType.rating,
        isRequired: true,
        order: 2,
      ),
      const SurveyQuestion(
        id: 'safety_compliance',
        question: 'التزام الطلاب بقواعد السلامة في الباص',
        type: QuestionType.rating,
        isRequired: true,
        order: 3,
      ),
      const SurveyQuestion(
        id: 'cooperation',
        question: 'مستوى التعاون بين الطلاب',
        type: QuestionType.rating,
        isRequired: true,
        order: 4,
      ),
      const SurveyQuestion(
        id: 'cleanliness',
        question: 'مدى المحافظة على نظافة الباص',
        type: QuestionType.rating,
        isRequired: true,
        order: 5,
      ),
      const SurveyQuestion(
        id: 'best_students',
        question: 'من هم أفضل 3 طلاب هذا الشهر؟ (اذكر أسماءهم)',
        type: QuestionType.text,
        isRequired: false,
        order: 6,
      ),
      const SurveyQuestion(
        id: 'improvement_needed',
        question: 'أي طلاب يحتاجون لتحسين سلوكهم؟ (اذكر أسماءهم والسبب)',
        type: QuestionType.text,
        isRequired: false,
        order: 7,
      ),
      const SurveyQuestion(
        id: 'incidents',
        question: 'هل حدثت أي مشاكل أو حوادث هذا الشهر؟',
        type: QuestionType.yesNo,
        isRequired: true,
        order: 8,
      ),
      const SurveyQuestion(
        id: 'incident_details',
        question: 'إذا كانت الإجابة نعم، اذكر التفاصيل',
        type: QuestionType.text,
        isRequired: false,
        order: 9,
      ),
      const SurveyQuestion(
        id: 'suggestions',
        question: 'اقتراحات لتحسين الخدمة',
        type: QuestionType.text,
        isRequired: false,
        order: 10,
      ),
    ];
  }

  String _getMonthName(int month) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[month - 1];
  }
}
