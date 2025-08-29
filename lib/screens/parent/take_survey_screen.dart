import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/survey_model.dart';
import '../../models/user_model.dart';

class TakeSurveyScreen extends StatefulWidget {
  final String surveyId;

  const TakeSurveyScreen({super.key, required this.surveyId});

  @override
  State<TakeSurveyScreen> createState() => _TakeSurveyScreenState();
}

class _TakeSurveyScreenState extends State<TakeSurveyScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  final PageController _pageController = PageController();
  
  SurveyModel? _survey;
  UserModel? _currentUser;
  Map<String, dynamic> _answers = {};
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadSurveyAndUser();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSurveyAndUser() async {
    try {
      // Load current user
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _databaseService.getUserData(user.uid);
        if (userData != null) {
          _currentUser = UserModel.fromMap(userData);
        }
      }

      // Load survey
      final surveyDoc = await FirebaseFirestore.instance
          .collection('surveys')
          .doc(widget.surveyId)
          .get();

      if (surveyDoc.exists) {
        _survey = SurveyModel.fromMap(surveyDoc.data()!);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading survey: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_survey == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('خطأ')),
        body: const Center(
          child: Text('لم يتم العثور على الاستبيان'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _survey!.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          
          // Question content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentQuestionIndex = index;
                });
              },
              itemCount: _survey!.questions.length,
              itemBuilder: (context, index) {
                final question = _survey!.questions[index];
                return _buildQuestionPage(question);
              },
            ),
          ),
          
          // Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final progress = (_currentQuestionIndex + 1) / _survey!.questions.length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'السؤال ${_currentQuestionIndex + 1} من ${_survey!.questions.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1E88E5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E88E5)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(SurveyQuestion question) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
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
            // Question text
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
                height: 1.4,
              ),
            ),
            
            if (question.isRequired) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'مطلوب',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Answer input based on question type
            _buildAnswerInput(question),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerInput(SurveyQuestion question) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return _buildMultipleChoiceInput(question);
      case QuestionType.rating:
        return _buildRatingInput(question);
      case QuestionType.text:
        return _buildTextInput(question);
      case QuestionType.yesNo:
        return _buildYesNoInput(question);
    }
  }

  Widget _buildMultipleChoiceInput(SurveyQuestion question) {
    return Column(
      children: question.options.map((option) {
        final isSelected = _answers[question.id] == option;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              setState(() {
                _answers[question.id] = option;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? const Color(0xFF1E88E5) : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: isSelected ? const Color(0xFF1E88E5).withAlpha(25) : Colors.white,
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? const Color(0xFF1E88E5) : Colors.grey[400],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 16,
                        color: isSelected ? const Color(0xFF1E88E5) : const Color(0xFF2D3748),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRatingInput(SurveyQuestion question) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ضعيف جداً', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('ممتاز', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) {
            final rating = index + 1;
            final isSelected = _answers[question.id] == rating;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _answers[question.id] = rating;
                });
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFF1E88E5) : Colors.grey[200],
                  border: Border.all(
                    color: isSelected ? const Color(0xFF1E88E5) : Colors.grey[300]!,
                  ),
                ),
                child: Center(
                  child: Text(
                    rating.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTextInput(SurveyQuestion question) {
    return TextFormField(
      initialValue: _answers[question.id]?.toString() ?? '',
      onChanged: (value) {
        _answers[question.id] = value;
      },
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'اكتب إجابتك هنا...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E88E5)),
        ),
      ),
    );
  }

  Widget _buildYesNoInput(SurveyQuestion question) {
    return Row(
      children: [
        Expanded(
          child: _buildYesNoOption(question, 'نعم', true),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildYesNoOption(question, 'لا', false),
        ),
      ],
    );
  }

  Widget _buildYesNoOption(SurveyQuestion question, String text, bool value) {
    final isSelected = _answers[question.id] == value;
    return InkWell(
      onTap: () {
        setState(() {
          _answers[question.id] = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF1E88E5) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFF1E88E5).withAlpha(25) : Colors.white,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: isSelected ? const Color(0xFF1E88E5) : const Color(0xFF2D3748),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final isFirstQuestion = _currentQuestionIndex == 0;
    final isLastQuestion = _currentQuestionIndex == _survey!.questions.length - 1;
    final currentQuestion = _survey!.questions[_currentQuestionIndex];
    final hasAnswer = _answers.containsKey(currentQuestion.id) &&
                     _answers[currentQuestion.id] != null &&
                     _answers[currentQuestion.id].toString().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          // Previous button
          if (!isFirstQuestion)
            Expanded(
              child: OutlinedButton(
                onPressed: _goToPreviousQuestion,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Color(0xFF1E88E5)),
                ),
                child: const Text(
                  'السابق',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E88E5),
                  ),
                ),
              ),
            ),

          if (!isFirstQuestion) const SizedBox(width: 16),

          // Next/Submit button
          Expanded(
            flex: isFirstQuestion ? 1 : 1,
            child: ElevatedButton(
              onPressed: (currentQuestion.isRequired && !hasAnswer) ? null :
                        (isLastQuestion ? _submitSurvey : _goToNextQuestion),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isLastQuestion ? 'إرسال الاستبيان' : 'التالي',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < _survey!.questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitSurvey() async {
    // Validate required questions
    for (final question in _survey!.questions) {
      if (question.isRequired) {
        final hasAnswer = _answers.containsKey(question.id) &&
                         _answers[question.id] != null &&
                         _answers[question.id].toString().isNotEmpty;
        if (!hasAnswer) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('يرجى الإجابة على السؤال: ${question.question}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_currentUser == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      final response = SurveyResponse(
        id: '',
        surveyId: _survey!.id,
        respondentId: _currentUser!.id,
        respondentName: _currentUser!.name,
        respondentType: 'parent',
        answers: _answers,
        submittedAt: DateTime.now(),
        isComplete: true,
      );

      await _databaseService.submitSurveyResponse(response);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال الاستبيان بنجاح'),
            backgroundColor: Colors.green,
          ),
        );

        // Go back to surveys list
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إرسال الاستبيان: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
