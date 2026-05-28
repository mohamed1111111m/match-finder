import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('شروط الاستخدام')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _Section(
            title: 'القبول بالشروط',
            body:
                'باستخدامك لتطبيق كورة فأنت توافق على الالتزام بهذه الشروط. '
                'إذا كنت لا توافق، يرجى عدم استخدام التطبيق.',
          ),
          _Section(
            title: 'وصف الخدمة',
            body:
                'كورة منصة رياضية تتيح:\n'
                '• حجز ملاعب رياضية.\n'
                '• تنظيم والمشاركة في البطولات.\n'
                '• تكوين الفرق والتواصل مع اللاعبين الآخرين.',
          ),
          _Section(
            title: 'حساب المستخدم',
            body:
                '• يجب أن تكون فوق 13 سنة لإنشاء حساب.\n'
                '• أنت مسؤول عن الحفاظ على سرية بيانات دخولك.\n'
                '• يُمنع إنشاء أكثر من حساب واحد.\n'
                '• يحق لنا إيقاف حسابك في حال مخالفة هذه الشروط.',
          ),
          _Section(
            title: 'قواعد السلوك',
            body:
                'يُحظر على المستخدمين:\n'
                '• نشر محتوى مسيء أو عنصري أو مخالف للآداب.\n'
                '• انتحال شخصية مستخدمين آخرين.\n'
                '• محاولة اختراق النظام أو التلاعب به.\n'
                '• استخدام التطبيق لأغراض غير قانونية.',
          ),
          _Section(
            title: 'الحجوزات والمدفوعات',
            body:
                '• الأسعار المعروضة تشمل الضرائب المطبقة.\n'
                '• الدفع يتم يدويًا عبر المحافظ الإلكترونية (InstaPay، Orange Cash، Vodafone Cash).\n'
                '• بعد إرسال تأكيد الدفع، يُراجعه فريق eKora ويُفعَّل الحجز خلال مدة معقولة.\n'
                '• الحجز لا يُعتبر مؤكدًا إلا بعد موافقة الفريق وظهور حالة "مؤكد" في التطبيق.\n'
                '• إذا لم يتم الدفع خلال 15 دقيقة من إنشاء الحجز، يُلغى تلقائيًا.\n'
                '• سياسة الإلغاء تختلف حسب الملعب — تحقق قبل الحجز.\n'
                '• في حالة النزاعات، تواصل مع الدعم خلال 48 ساعة.',
          ),
          _Section(
            title: 'البطولات',
            body:
                '• رسوم التسجيل غير قابلة للاسترداد ما لم تُلغَ البطولة من قِبل المنظمين.\n'
                '• نتائج المباريات نهائية ما لم يُثبت خطأ تقني.\n'
                '• يحق للإدارة استبعاد أي فريق يخالف روح اللعب النظيف.',
          ),
          _Section(
            title: 'إخلاء المسؤولية',
            body:
                'التطبيق يعمل كوسيط بين المستخدمين وأصحاب الملاعب. '
                'لسنا مسؤولين عن الإصابات أو الأضرار التي تحدث أثناء استخدام المرافق الرياضية.',
          ),
          _Section(
            title: 'الملكية الفكرية',
            body:
                'جميع حقوق الملكية الفكرية لتطبيق كورة — بما يشمل الشعار والتصميم والكود — '
                'محفوظة لفريق كورة. لا يجوز نسخ أي جزء منه دون إذن مسبق.',
          ),
          _Section(
            title: 'تعديل الشروط',
            body:
                'نحتفظ بحق تعديل هذه الشروط في أي وقت. '
                'سيُعلَم المستخدمون بالتعديلات الجوهرية قبل 7 أيام من تفعيلها.',
          ),
          _Section(
            title: 'القانون المطبق',
            body:
                'تخضع هذه الشروط للقانون المصري، وتختص المحاكم المصرية بالنظر في أي نزاع.',
          ),
          SizedBox(height: 12),
          Text(
            'آخر تحديث: أبريل 2026',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
