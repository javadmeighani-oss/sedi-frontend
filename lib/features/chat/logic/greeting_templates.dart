/// Approved Sedi intro greeting (FA/EN/AR). Product-owner approved text.
/// FA/AR use "صدی" (never "سدی"); EN uses "Sedi".

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
const String _greetingFa = 'من صدی هستم؛ دستیار هوشمند مراقبت سلامت شما. با استفاده از گجت‌های تخصصی صدی و تعاملات روزانه، مراقبت پیوسته از سلامت شما را بر عهده می‌گیرم و می‌توانم برای تصمیم‌گیری‌های مربوط به سلامت، تندرستی و سبک زندگی اطلاعات مفیدی ارائه دهم.\n'
    'می‌توانم با شما درباره عادات روزمره‌تان، خواب، تغذیه و فعالیت‌های کاری و ورزشی صحبت کنم و توصیه‌های شخصی‌سازی‌شده به شما ارائه بدهم. همچنین می‌توانم با شما گفتگو کنم و مثل یک دوست، از شما حمایت عاطفی کنم.\n'
    'هر سؤال یا موضوعی دارید بپرسید.';

// EN – Sedi
const String _greetingEn = "I'm Sedi, your intelligent health-care companion. Using Sedi's specialized gadgets and our daily interactions, I take care of your continuous health monitoring and can provide helpful information to support your decisions about health, wellness, and lifestyle.\n"
    "We can talk about your daily habits—sleep, nutrition, work routines, and physical activity—and I can offer personalized recommendations. I can also chat with you and support you emotionally like a trusted friend.\n"
    "Ask me anything that's on your mind.";

// AR – صدی
const String _greetingAr = 'أنا صدی، مساعدك الذكي لرعاية صحتك. باستخدام أجهزة صدی المتخصصة وتفاعلاتنا اليومية، أتولى الرعاية المستمرة لصحتك ويمكنني تزويدك بمعلومات مفيدة تساعدك في قراراتك المتعلقة بالصحة والعافية ونمط الحياة.\n'
    'يمكننا التحدث عن عاداتك اليومية مثل النوم والتغذية وروتين العمل والنشاط البدني، ويمكنني تقديم توصيات مخصصة لك. كما يمكنني أن أتحدث معك وأقدم لك دعماً عاطفياً كصديق موثوق.\n'
    'اسألني أي سؤال أو اطرح أي موضوع.';
