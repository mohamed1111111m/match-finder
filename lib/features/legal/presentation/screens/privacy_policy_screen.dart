import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سياسة الخصوصية')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _Section(
            title: 'مقدمة',
            body:
                'تطبيق كورة ("التطبيق") يلتزم بحماية خصوصيتك. توضح هذه السياسة كيف نجمع بياناتك ونستخدمها ونحميها.',
          ),
          _Section(
            title: 'البيانات التي نجمعها',
            body:
                '• الاسم وعنوان البريد الإلكتروني عند التسجيل.\n'
                '• بيانات الملف الشخصي كاسم المستخدم والصورة الشخصية.\n'
                '• بيانات الاستخدام مثل الملاعب المحجوزة والبطولات التي شاركت فيها.\n'
                '• رسائل الدردشة داخل التطبيق.\n'
                '• رمز FCM لإرسال الإشعارات الفورية.\n'
                '• بيانات الدفع اليدوي: وسيلة الدفع المختارة (InstaPay أو Orange Cash أو Vodafone Cash) ووقت إرسال التأكيد. لا نجمع أرقام محافظك أو بياناتك البنكية.',
          ),
          _Section(
            title: 'كيف نستخدم بياناتك',
            body:
                '• تشغيل خدمات التطبيق وتحسينها.\n'
                '• إرسال إشعارات متعلقة بالحجوزات والبطولات والرسائل.\n'
                '• تحليل الاستخدام لتحسين تجربة المستخدم.\n'
                '• مراجعة تأكيدات الدفع اليدوي وتفعيل الحجوزات.\n'
                '• لا نبيع بياناتك لأي طرف ثالث.',
          ),
          _Section(
            title: 'بيانات الدفع',
            body:
                'تعتمد eKora على نظام دفع يدوي عبر المحافظ الإلكترونية المصرية (InstaPay، Orange Cash، Vodafone Cash).\n\n'
                '• نحن نسجّل وسيلة الدفع التي اخترتها ووقت إرسال تأكيد التحويل فقط.\n'
                '• لا نطّلع على تفاصيل محفظتك ولا نخزّن أي بيانات بنكية.\n'
                '• يتم التحقق من الدفع يدويًا بواسطة فريق eKora ثم تُفعَّل الحجوزات.\n'
                '• في حال رفض الدفع أو انتهاء مدة الحجز، يتم إلغاؤه تلقائيًا.',
          ),
          _Section(
            title: 'مشاركة البيانات',
            body:
                'لا نشارك بياناتك الشخصية مع أطراف ثالثة إلا في الحالات التالية:\n'
                '• عند الضرورة لتقديم الخدمة (مثل Firebase من Google).\n'
                '• إذا طُلب ذلك قانونيًا.\n'
                '• بموافقتك الصريحة.',
          ),
          _Section(
            title: 'أمان البيانات',
            body:
                'نستخدم Firebase Authentication وFirestore بأعلى معايير الحماية. '
                'يتم تشفير بياناتك أثناء النقل وأثناء التخزين.',
          ),
          _Section(
            title: 'حقوقك',
            body:
                '• يحق لك الاطلاع على بياناتك الشخصية.\n'
                '• يحق لك تعديل بياناتك من صفحة الملف الشخصي.\n'
                '• يحق لك حذف حسابك وجميع بياناتك بشكل دائم من إعدادات الحساب.',
          ),
          _Section(
            title: 'الأطفال',
            body:
                'التطبيق مخصص للمستخدمين الذين تجاوزوا 13 عامًا. '
                'لا نجمع بيانات الأطفال دون موافقة ولي الأمر.',
          ),
          _Section(
            title: 'تحديث السياسة',
            body:
                'قد نُحدِّث هذه السياسة من وقت لآخر. سنُعلمك بأي تغييرات جوهرية '
                'عبر الإشعارات داخل التطبيق.',
          ),
          _Section(
            title: 'تواصل معنا',
            body: 'لأي استفسار بشأن الخصوصية: support@ekora.app',
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
