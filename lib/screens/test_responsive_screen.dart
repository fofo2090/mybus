import 'package:flutter/material.dart';
import '../widgets/responsive_widgets.dart';
import '../utils/responsive_validator.dart';

/// شاشة اختبار النظام المتجاوب
class TestResponsiveScreen extends StatelessWidget {
  const TestResponsiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const ResponsiveHeading('اختبار النظام المتجاوب'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _runResponsiveAnalysis(context),
            tooltip: 'تحليل التجاوب',
          ),
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () => _showResponsiveInfo(context),
            tooltip: 'معلومات التجاوب',
          ),
        ],
      ),
      body: ResponsiveContainer(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // معلومات الجهاز
              _buildDeviceInfo(context),
              
              const ResponsiveVerticalSpace(),
              
              // اختبار النصوص
              _buildTextTests(),
              
              const ResponsiveVerticalSpace(),
              
              // اختبار البطاقات
              _buildCardTests(),
              
              const ResponsiveVerticalSpace(),
              
              // اختبار الشبكة
              _buildGridTests(),
              
              const ResponsiveVerticalSpace(),
              
              // اختبار الأزرار
              _buildButtonTests(),
              
              const ResponsiveVerticalSpace(),
              
              // اختبار القوائم
              _buildListTests(),

              const ResponsiveVerticalSpace(),

              // اختبار النماذج الجديدة
              _buildFormTests(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceInfo(BuildContext context) {
    final deviceType = ResponsiveHelper.getDeviceType(context);
    final screenWidth = ResponsiveHelper.getScreenWidth(context);
    final screenHeight = ResponsiveHelper.getScreenHeight(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);

    return ResponsiveCard(
      color: Colors.blue.withOpacity(0.1),
      border: Border.all(color: Colors.blue.withOpacity(0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ResponsiveSubheading('معلومات الجهاز'),
          const ResponsiveVerticalSpace(),
          ResponsiveBodyText('نوع الجهاز: ${_getDeviceTypeName(deviceType)}'),
          ResponsiveBodyText('عرض الشاشة: ${screenWidth.toInt()}px'),
          ResponsiveBodyText('ارتفاع الشاشة: ${screenHeight.toInt()}px'),
          ResponsiveBodyText('الاتجاه: ${isLandscape ? 'أفقي' : 'عمودي'}'),
        ],
      ),
    );
  }

  Widget _buildTextTests() {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ResponsiveSubheading('اختبار النصوص'),
          const ResponsiveVerticalSpace(),
          const ResponsiveHeading('عنوان رئيسي'),
          const ResponsiveSubheading('عنوان فرعي'),
          const ResponsiveBodyText('نص عادي - هذا نص تجريبي لاختبار النظام المتجاوب'),
          const ResponsiveCaption('نص صغير - معلومات إضافية'),
          const ResponsiveVerticalSpace(),
          Row(
            children: [
              ResponsiveIcon(Icons.star, color: Colors.orange),
              const ResponsiveHorizontalSpace(),
              const ResponsiveBodyText('أيقونة متجاوبة'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardTests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ResponsiveSubheading('اختبار البطاقات'),
        const ResponsiveVerticalSpace(),
        ResponsiveGridView(
          mobileColumns: 1,
          tabletColumns: 2,
          desktopColumns: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            ResponsiveStatCard(
              title: 'إجمالي الطلاب',
              value: '150',
              icon: Icons.people,
              color: Colors.blue,
              subtitle: 'طالب نشط',
            ),
            ResponsiveStatCard(
              title: 'الرحلات اليوم',
              value: '25',
              icon: Icons.directions_bus,
              color: Colors.green,
              subtitle: 'رحلة مكتملة',
            ),
            ResponsiveStatCard(
              title: 'المشرفين',
              value: '12',
              icon: Icons.supervisor_account,
              color: Colors.orange,
              subtitle: 'مشرف متاح',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGridTests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ResponsiveSubheading('اختبار الشبكة'),
        const ResponsiveVerticalSpace(),
        ResponsiveGridView(
          mobileColumns: 2,
          tabletColumns: 3,
          desktopColumns: 4,
          largeDesktopColumns: 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(10, (index) => ResponsiveActionCard(
            title: 'إجراء ${index + 1}',
            description: 'وصف الإجراء رقم ${index + 1}',
            icon: Icons.settings,
            color: Colors.purple,
            onTap: () {},
          )),
        ),
      ],
    );
  }

  Widget _buildButtonTests() {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ResponsiveSubheading('اختبار الأزرار'),
          const ResponsiveVerticalSpace(),
          ResponsiveButtonGroup(
            buttons: [
              ResponsiveElevatedButton(
                onPressed: () {},
                child: const Text('زر رئيسي'),
              ),
              ResponsiveOutlinedButton(
                onPressed: () {},
                child: const Text('زر ثانوي'),
              ),
              ResponsiveTextButton(
                onPressed: () {},
                child: const Text('زر نص'),
              ),
            ],
          ),
          const ResponsiveVerticalSpace(),
          Row(
            children: [
              ResponsiveIconButton(
                onPressed: () {},
                icon: const Icon(Icons.favorite),
                backgroundColor: Colors.red.withOpacity(0.1),
                color: Colors.red,
              ),
              const ResponsiveHorizontalSpace(),
              ResponsiveIconButton(
                onPressed: () {},
                icon: const Icon(Icons.share),
                backgroundColor: Colors.blue.withOpacity(0.1),
                color: Colors.blue,
              ),
              const ResponsiveHorizontalSpace(),
              ResponsiveIconButton(
                onPressed: () {},
                icon: const Icon(Icons.bookmark),
                backgroundColor: Colors.green.withOpacity(0.1),
                color: Colors.green,
              ),
            ],
          ),
          const ResponsiveVerticalSpace(),
          ResponsiveWrap(
            children: [
              ResponsiveChip(
                label: const Text('تصنيف 1'),
                backgroundColor: Colors.blue.withOpacity(0.1),
              ),
              ResponsiveChip(
                label: const Text('تصنيف 2'),
                backgroundColor: Colors.green.withOpacity(0.1),
              ),
              ResponsiveChip(
                label: const Text('تصنيف 3'),
                backgroundColor: Colors.orange.withOpacity(0.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListTests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ResponsiveSubheading('اختبار القوائم'),
        const ResponsiveVerticalSpace(),
        ResponsiveListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(5, (index) => ResponsiveListCard(
            child: ResponsiveListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(0.2),
                child: ResponsiveIcon(Icons.person, color: Colors.blue),
              ),
              title: ResponsiveBodyText('عنصر القائمة ${index + 1}'),
              subtitle: ResponsiveCaption('وصف العنصر رقم ${index + 1}'),
              trailing: ResponsiveIconButton(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward_ios),
                color: Colors.grey,
              ),
              onTap: () {},
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildFormTests() {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ResponsiveSubheading('اختبار النماذج المتجاوبة'),
          const ResponsiveVerticalSpace(),
          ResponsiveTextField(
            labelText: 'اسم المستخدم',
            hintText: 'أدخل اسم المستخدم',
            prefixIcon: const Icon(Icons.person),
          ),
          const ResponsiveVerticalSpace(),
          ResponsiveDropdownField<String>(
            labelText: 'اختر المدينة',
            items: const [
              DropdownMenuItem(value: 'riyadh', child: Text('الرياض')),
              DropdownMenuItem(value: 'jeddah', child: Text('جدة')),
              DropdownMenuItem(value: 'dammam', child: Text('الدمام')),
            ],
            onChanged: (value) {},
          ),
          const ResponsiveVerticalSpace(),
          Row(
            children: [
              Expanded(
                child: ResponsiveElevatedButton(
                  onPressed: () {},
                  child: const Text('حفظ'),
                ),
              ),
              const ResponsiveHorizontalSpace(),
              Expanded(
                child: ResponsiveOutlinedButton(
                  onPressed: () {},
                  child: const Text('إلغاء'),
                ),
              ),
            ],
          ),
          const ResponsiveVerticalSpace(),
          Builder(
            builder: (context) => ResponsiveTextButton(
              onPressed: () => _showResponsiveDialog(context),
              child: const Text('اختبار الحوار'),
            ),
          ),
        ],
      ),
    );
  }

  String _getDeviceTypeName(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 'موبايل';
      case DeviceType.tablet:
        return 'تابلت';
      case DeviceType.desktop:
        return 'سطح المكتب';
      case DeviceType.largeDesktop:
        return 'سطح مكتب كبير';
    }
  }

  /// تشغيل تحليل التجاوب
  Future<void> _runResponsiveAnalysis(BuildContext context) async {
    try {
      final result = await ResponsiveValidator.analyzeResponsiveness(context);

      if (context.mounted) {
        ResponsiveValidator.printDetailedReport(result);

        ResponsiveDialog.show(
          context: context,
          title: 'نتائج تحليل التجاوب',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveCard(
                color: _getScoreColor(result.overallScore).withOpacity(0.1),
                border: Border.all(color: _getScoreColor(result.overallScore)),
                child: Row(
                  children: [
                    Icon(
                      _getScoreIcon(result.overallScore),
                      color: _getScoreColor(result.overallScore),
                      size: ResponsiveHelper.getIconSize(context),
                    ),
                    const ResponsiveHorizontalSpace(),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ResponsiveSubheading('النتيجة الإجمالية'),
                          ResponsiveHeading('${result.overallScore}/100'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const ResponsiveVerticalSpace(),
              const ResponsiveSubheading('التوصيات:'),
              const ResponsiveVerticalSpace(),
              ...result.recommendations.map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ResponsiveBodyText(rec),
              )),
            ],
          ),
          actions: [
            ResponsiveElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التحليل: $e')),
        );
      }
    }
  }

  /// عرض معلومات التجاوب
  void _showResponsiveInfo(BuildContext context) {
    ResponsiveBottomSheet.show(
      context: context,
      title: 'معلومات النظام المتجاوب',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ResponsiveSubheading('نقاط التوقف:'),
          const ResponsiveVerticalSpace(),
          _buildBreakpointInfo('موبايل', '< 600px', Icons.phone_android),
          _buildBreakpointInfo('تابلت', '600px - 900px', Icons.tablet),
          _buildBreakpointInfo('سطح المكتب', '900px - 1200px', Icons.desktop_windows),
          _buildBreakpointInfo('سطح مكتب كبير', '> 1200px', Icons.tv),
          const ResponsiveVerticalSpace(),
          const ResponsiveSubheading('المميزات:'),
          const ResponsiveVerticalSpace(),
          _buildFeatureInfo('تخطيط متكيف', 'يتغير عدد الأعمدة حسب حجم الشاشة'),
          _buildFeatureInfo('خطوط متجاوبة', 'أحجام خطوط مختلفة لكل جهاز'),
          _buildFeatureInfo('مسافات ذكية', 'مسافات متناسبة مع حجم الشاشة'),
          _buildFeatureInfo('أيقونات متكيفة', 'أحجام أيقونات مناسبة للمس'),
        ],
      ),
    );
  }

  Widget _buildBreakpointInfo(String name, String range, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1E88E5)),
          const SizedBox(width: 12),
          Expanded(
            child: ResponsiveBodyText('$name: $range'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureInfo(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveBodyText(title, fontWeight: FontWeight.bold),
          ResponsiveCaption(description),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getScoreIcon(int score) {
    if (score >= 80) return Icons.check_circle;
    if (score >= 60) return Icons.warning;
    return Icons.error;
  }

  /// اختبار الحوار المتجاوب
  void _showResponsiveDialog(BuildContext context) {
    ResponsiveDialog.show(
      context: context,
      title: 'حوار متجاوب',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ResponsiveBodyText('هذا مثال على حوار متجاوب يتكيف مع حجم الشاشة'),
          const ResponsiveVerticalSpace(),
          ResponsiveTextField(
            labelText: 'اختبار حقل النص',
            hintText: 'أدخل نص تجريبي',
          ),
        ],
      ),
      actions: [
        ResponsiveTextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
        ResponsiveElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم اختبار الحوار بنجاح!')),
            );
          },
          child: const Text('تأكيد'),
        ),
      ],
    );
  }
}
