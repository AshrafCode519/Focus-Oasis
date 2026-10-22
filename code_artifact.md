# وثيقة خطة العمل وخارطة الطريق (Project Roadmap & Technical Specification)
## مشروع تطبيق إدارة الوقت والإنتاجية متعدد المنصات (Focus Oasis / Pomodoro App)

---

## 1. نظرة عامة على المشروع (Executive Summary)

* **الهدف:** بناء تطبيق إنتاجية يعتمد على تقنية "بومودورو" مع ميكانيكا التلعيب (Gamification) البصرية الشبيهة ببرنامج *Forest*، مع ميزة دوائر التقدم التفاعلية.
* **المنصات المستهدفة:** الجوال (Android, iOS) وسطح المكتب (Windows, Linux).
* **الميزة التنافسية:** مزامنة لحظية فورية (Real-time Sync) بدون تأخير، واجهة مستخدم خفيفة على الموارد، ونظام تلعيب يربط إنجاز المهام بزراعة واحة افتراضية وتطورها.

---

## 2. المكدس التقني المعتمد (Tech Stack)

| المكوّن | التقنية المستخدمة | سبب الاختيار |
| :--- | :--- | :--- |
| **واجهة المستخدم والتطوير** | **Flutter (Dart)** | كود برمجي موحد يدعم الجوال والكمبيوتر بنظام رسم عالي الأداء (Canvas & Skia/Impeller) بدون الحاجة لمتصفح مدمج مثل Electron. |
| **محرك الرسوم والأنيميشن** | **Rive / CustomPainter** | رسومات متجهة خفيفة جداً تدعم تفاعل نمو النبتة واكتمال الدوائر باستهلاك يكاد يكون معدوماً لموارد الذاكرة والبطارية. |
| **الخلفية والمزامنة** | **Supabase (PostgreSQL + Realtime)** | يتيح مزامنة لحظية عبر الـ WebSockets لحالة المؤقت والبيانات بين المنصات، ويدعم تسجيل الدخول ونظام الـ Offline-First. |
| **قاعدة البيانات المحلية** | **Drift (SQLite) أو Hive** | استمرارية تخزين الجلسات والمهام محلياً عند انقطاع الإنترنت والمزامنة التلقائية فور عودة الاتصال. |
| **دمج النظام (Desktop)** | **tray_manager + window_manager** | تشغيل التطبيق في صينية النظام (System Tray)، وتثبيت نافذة عائمة مصغرة أعلى الشاشة (Always on Top). |

---

## 3. هندسة الميزات الرئيسية (Core Features & Mechanics)

### أ. محرك بومودورو ودوائر الإنجاز (Progress Rings)
1. **دائرة المؤقت المركزية:** حلقة دائرية تفرغ أو تمتلئ بنعومة متناهية مع مرور الثواني، مع تغيير لون الإطار حسب حالة الجلسة (تركيز / راحة قصيرة / راحة طويلة).
2. **دوائر الهدف اليومي (Daily Target Rings):** صف من الدوائر المقسمة التي تمثل دورات اليوم؛ كل جلسة مكتملة تغلق دائرة مصحوبة باهتزاز تفاعلي (Haptic) وصوت إنجاز ناعم.

### ب. نظام الغابة والتلعيب (Virtual Forest System)
1. **مراحل نمو الشجرة:**
   * $0\%$: بذرة مغروسة في التربة.
   * $35\%$: ظهور برعم أخضر يافع.
   * $70\%$: نمو فروع الشجرة.
   * $100\%$: اكتمال الشجرة وإزهارها وإضافتها لشبكة الأرض (Isoland).
2. **شرط الفشل (Penalty):** إغلاق التطبيق أو مقاطعة المؤقت يؤدي إلى جفاف النبتة وتحولها إلى شجرة ذابلة تبقى كعلامة في الحديقة الأسبوعية.
3. **متجر النباتات (Plant Nursery):** عملات افتراضية تُمنح مع كل دقيقة تركيز، لشراء أشجار وسلالات بيئية جديدة.

---

## 4. تصميم قاعدة البيانات (Database Schema)

```sql
-- 1. جدول المستخدمين
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    display_name TEXT,
    coins_balance INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. جدول جلسات التركيز
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    duration_minutes INT NOT NULL,
    session_type TEXT CHECK (session_type IN ('focus', 'short_break', 'long_break')),
    status TEXT CHECK (status IN ('completed', 'failed', 'running')),
    tree_type_id TEXT NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ended_at TIMESTAMP WITH TIME ZONE
);

-- 3. جدول الغابة الافتراضية
CREATE TABLE forest_grid (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    session_id UUID REFERENCES sessions(id),
    tree_type TEXT NOT NULL,
    is_alive BOOLEAN NOT NULL DEFAULT TRUE,
    grid_position_x INT,
    grid_position_y INT,
    planted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. جدول المهام المرتبطة
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    estimated_pomodoros INT DEFAULT 1,
    completed_pomodoros INT DEFAULT 0,
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## 5. خارطة الطريق التنفيذية (Milestones & Roadmap)

```
[ المرحلة 1: التصميم والنماذج الأولية ]
 │
 ├── إعداد تصاميم Figma للوضع المظلم/الفاتح وشاشات الجوال والديسكتوب.
 └── رسم أصول النباتات ومراحل النمو وتصديرها بصيغة Rive/Lottie.

[ المرحلة 2: بناء النواة البرمجية (Flutter Core) ]
 │
 ├── إنشاء مشروع Flutter لجميع المنصات (Linux, Windows, Android, iOS).
 ├── برمجة مؤقت البومودورو وحلقة التقدم الدائرية عبر CustomPainter.
 ├── بناء قاعدة البيانات المحلية Drift لحفظ البيانات دون إنترنت.
 └── ربط أنيميشن نمو النبتة وتأثير فشل الجلسة.

[ المرحلة 3: الخادم والمزامنة اللحظية (مكتملة بنجاح ✅) ]
 │
 ├── ✅ إعداد وتوصيل مشروع Supabase وتفعيل نظام المصادقة ووضع الضيف (Guest Mode).
 ├── ✅ بناء جداول البيانات (profiles, sessions, forest_grid, tasks) وقواعد الحماية (RLS).
 └── ✅ تفعيل قناة WebSockets المباشرة لمزامنة المؤقت والبيانات لحظياً عبر كافة الأجهزة.

[ المرحلة 4: ميزات تكامل النظام والسطح المكتب (مكتملة بنجاح ✅) ]
 │
 ├── ✅ بناء نافذة الديسكتوب العائمة المصغرة (Always on Top Floating Widget).
 ├── ✅ وضع الصرامة والتركيز العميق (Strict Mode / Anti-distraction lifecycle observer).
 ├── ✅ الاهتزاز اللمسي التفاعلي (Haptic Feedback) عند إكمال وبدء الجلسات.
 └── ✅ دمج المشغل الصوتي لخلفيات الطبيعة والتركيز (Ambient Audio Engine).

[ المرحلة 5: التجميع والنشر والتوزيع (جاهزة للبناء ✅) ]
 │
 ├── ✅ تصميم وتوليد الأيقونة الرسمية للتطبيق (3D Glassmorphism Zen Oasis).
 ├── ✅ دمج الأصول في الواجهة والويب (assets/images و favicon و web icons).
 ├── ✅ فحص الجودة البرمجية الشامل بنسبة 100% (flutter analyze: 0 issues).
 └── ✅ اجتياز كافة اختبارات الوحدة والدخان التلقائية (flutter test: all passed).

[ المرحلة 6: التلعيب المتقدم وتجربة الاسترخاء والتحليلات العميقة (مكتملة بنجاح ✅) ]
 │
 ├── ✅ نظام الأوسمة والإنجازات (7 Achievements مع مكافآت عملات وشرائط تقدم).
 ├── ✅ بطاقة المشاركة الجمالية للإنتاجية (Social Share Productivity Card).
 ├── ✅ تمرين التنفس والاسترخاء الموجه (Mindful Breathing 4-7-8 & Box Breathing).
 ├── ✅ مخطط النشاط السنوي / الحراري للواحة (GitHub/Forest Style 10-Week Heatmap).
 ├── ✅ توزيع وسوم التركيز الديناميكي وحساب سلسلة الأيام المتواصلة (Streak Engine).
 └── ✅ محرك توليد الأصوات النقية أوفلاين (Pure Dart 16-bit PCM WAV Synthesizer).

[ المرحلة 7: التوسع النباتي والجاهزية للنشر والتوزيع (مكتملة بنجاح ✅) ]
 │
 ├── ✅ توسيع كتالوج الواحة إلى 12 سلالة نباتية فريدة مع محرك رسم مخصص (CustomPainter).
 ├── ✅ نظام النسخ الاحتياطي وتصدير/استيراد البيانات محلياً (JSON Backup & Restore Engine).
 ├── ✅ شريط التحكم في مستوى صوت المؤثرات الطبيعية (Ambient Volume Slider).
 ├── ✅ التحديث التلقائي لعنوان تبويب المتصفح بالعد التنازلي لحظة بلحظة (Dynamic Tab Title).
 ├── ✅ بطاقة التحفيز وحكمة التركيز اليومية (Daily Focus Wisdom & Motivation).
 └── ✅ ضبط وتأهيل بيانات النشر والويب (PWA Manifest, Dark Theme Colors, Meta Tags).

[ المرحلة 8: نظام دعم المطور والتبرع (مكتملة بنجاح ✅) ]
 │
 ├── ✅ نافذة الدعم والتبرع متعددة القنوات (DonationModal: فودافون كاش، إنستاباي، Buy Me a Coffee، PayPal).
 ├── ✅ نسخ مباشر للأرقام والروابط بنقرة واحدة (1-Click Clipboard Copy & Feedback).
 ├── ✅ إمكانية تخصيص وتعديل أرقام وحسابات التبرع مباشرة من داخل التطبيق وحفظها محلياً.
 └── ✅ وسام الراعي الفخري (Patron Badge) ومكافأة 500 عملة واحة للداعمين مع احتفال بصري.
```

---

## 6. توصيات للبدء السريع

1. ابدأ بإنشاء قالب المشروع محلياً عبر الأمر:
   `flutter create --platforms=android,ios,windows,linux focus_oasis`
2. اعتمد حزمة `riverpod` أو `flutter_bloc` لإدارة حالة المؤقت بدقة متناهية تفصل منطق الوقت عن واجهة المستخدم.
3. استخدم إشعارات النظام الأصلية عبر حزمة `flutter_local_notifications` لتنبيه المستخدم عند انتهاء الجلسة أثناء تصغير التطبيق.