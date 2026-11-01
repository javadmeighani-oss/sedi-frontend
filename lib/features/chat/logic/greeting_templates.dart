/// Approved Sedi intro greeting (FA/EN/AR). Product-owner approved text.
/// FA uses "صدی", AR uses "صدي" (Arabic spelling, R-048), EN uses "Sedi"; never "سدی".

String getIntroGreeting(String langCode) {
  final lang = langCode.toLowerCase();
  switch (lang) {
    case 'fa':
      return _greetingFa;
    case 'ar':
      return _greetingAr;
    case 'en':
    default:
      return _greetingEn;
  }
}

// FA – صدی
const String _greetingFa = 'من صدی هستم؛ همراه سلامت و حافظه‌ی شما. از گفتگوهای ما و پرسش‌های خودم، تصویر جسم و روان شما را در کوتاه‌مدت، میان‌مدت و بلندمدت نگه می‌دارم و وقتی گجت‌های هوشمند صدی وصل شوند، علائم حیاتی شما را هم پیوسته ثبت می‌کنم.\n'
    'با همین شناخت، مشاور و مراقب سلامت شما هستم: پیشگیری، همراهی و پیگیری درمان، تغذیه، ورزش و خواب؛ و مخصوصاً وقتی حال جسم یا دلتان خوب نیست، کنار شما می‌مانم.\n'
    'هر سؤال یا موضوعی دارید بپرسید.';

// EN – Sedi
const String _greetingEn = "I'm Sedi, your health companion and your memory. From our talks and my own questions I keep the picture of your body and mind over the short, medium and long term, and, as your Sedi smart gadgets connect, I record your vital signs continuously.\n"
    "With that knowledge I'm your adviser and health caretaker: prevention, support and follow-up through treatment, nutrition, exercise and sleep, and I stay beside you, above all when your body or mind is not at its best.\n"
    "Ask me anything that's on your mind.";

// AR – صدي
const String _greetingAr = 'أنا صدي، رفيقتك الصحية وذاكرتك. من أحاديثنا ومن أسئلتي أحفظ صورة جسدك ونفسك على المدى القصير والمتوسط والطويل، وحين تتصل أجهزة صدي الذكية أسجّل علاماتك الحيوية باستمرار.\n'
    'وبهذه المعرفة أكون مستشارتك ومرافقتك في رعاية صحتك: الوقاية ومرافقة العلاج ومتابعته والتغذية والرياضة والنوم؛ وأبقى بجانبك خاصة حين لا يكون جسدك أو نفسك في أفضل حال.\n'
    'اسألني أي سؤال أو اطرح أي موضوع.';
