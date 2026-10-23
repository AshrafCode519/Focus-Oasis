# 🪟 دليل نشر واحة التركيز على متجر مايكروسوفت (Microsoft Store Publishing Guide)

تم إعداد تطبيق **واحة التركيز (Focus Oasis)** بالكامل ليدعم أنظمة ويندوز (Windows 10 & Windows 11) عبر الصيغة الحديثة المعتمدة لدى مايكروسوفت: **حزم MSIX**.

---

## 📦 حزم ويندوز المجهزة تلقائياً في المشروع:

1. **حزمة متجر مايكروسوفت (`FocusOasis-Microsoft-Store.msix`):**
   - حزمة مجهزة بوضع `--store` المتوافق 100% مع معايير ومتطلبات متجر Windows والمتوافقة مع فحص الاعتماد الآلي (WACK).
2. **حزمة التثبيت المباشر بنقرة واحدة (`FocusOasis-Windows-Installer.msix`):**
   - تثبيت سلس عبر مثبت تطبيقات ويندوز الافتراضي (Windows App Installer) بدون الحاجة إلى الدخول للمتجر.
3. **النسخة المحمولة (`FocusOasis-Windows-Portable-x64.zip`):**
   - تعمل بنقرة واحدة فور فك الضغط دون الحاجة لأي تثبيت.

---

## 🏪 خطوات النشر على متجر مايكروسوفت (Microsoft Partner Center)

### الخطوة 1: التسجيل في مركز شركاء مايكروسوفت (مرة واحدة فقط)
1. توجه إلى **[Microsoft Partner Center Dashboard](https://partner.microsoft.com/dashboard/apps-and-games/overview)**.
2. سجّل الدخول بحساب مايكروسوفت الخاص بك.
3. قم بإنشاء حساب مطور (Individual Developer Account - رسوم لمرة واحدة مدى الحياة ~19$، أو مجاني تماماً للطلاب عبر GitHub Student Pack).

---

### الخطوة 2: حجز اسم التطبيق والحصول على بيانات الهوية
1. من لوحة التحكم، اضغط على **Create a new app**.
2. احجز اسم التطبيق، مثلاً:
   ```
   Focus Oasis
   ```
   (أو `Focus Oasis - واحة التركيز`).
3. بعد حجز الاسم، اذهب إلى القائمة الجانبية: **Product management** -> **Product Identity**.
4. ستجد 3 بيانات أساسية:
   - **Package/Identity name** (مثلاً: `12345AshrafCode.FocusOasis`)
   - **Publisher ID** (مثلاً: `CN=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX`)
   - **Publisher display name** (اسم المطور المسجل لديك)

---

### الخطوة 3: مطابقة الهوية في ملف `pubspec.yaml`
افتح ملف [`pubspec.yaml`](pubspec.yaml) وتأكد من مطابقة هذه الحقول تحت `msix_config`:
```yaml
msix_config:
  display_name: "Focus Oasis • واحة التركيز"
  publisher_display_name: "اسم المطور كما هو في مايكروسوفت"
  identity_name: "اسم الـ Identity المخصص لك"
  publisher: "CN=معرف الناشر الخاص بك"
  msix_version: 1.0.0.0
  logo_path: assets/images/app_icon.png
  capabilities: internetClient
  output_path: dist
```

---

### الخطوة 4: الحصول على الحزمة الجاهزة ورفعها للمتجر
يقوم سير العمل الآلي [`.github/workflows/windows-release.yml`](.github/workflows/windows-release.yml) ببناء الحزمة تلقائياً على خوادم `windows-latest`:

1. اذهب إلى صفحة المستودع: **Actions** -> **Windows & Microsoft Store Release** -> اضغط **Run workflow**.
2. فور انتهاء البناء، حمّل ملف:
   ```
   FocusOasis-Microsoft-Store.msix
   ```
3. في لوحة تحكم مايكروسوفت Partner Center:
   - اذهب إلى **Packages** واسحب وأفلت ملف الـ `.msix`.
   - املأ صفحة وصف المتجر (Store listing) باللغة العربية والإنجليزية، وأرفق لقطات الشاشة وأيقونة التطبيق.
   - اختر الفئة: **Productivity** (الإنتاجية) أو **Utilities**.
   - اختر التسعير: **Free** (مجاني).
4. اضغط **Submit to the Store**.

---

### ⏱️ المراجعة والنشر:
تستغرق عملية الفحص الآلي والاعتماد لدى مايكروسوفت عادة ما بين **12 إلى 24 ساعة فقط**، ويصبح تطبيقك بعدها متاحاً لمئات الملايين من أجهزة الكمبيوتر المحمولة والمكتبية في جميع أنحاء العالم عبر متجر **Microsoft Store** المدمج في Windows 10 و Windows 11!
