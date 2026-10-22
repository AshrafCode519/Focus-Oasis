# 🐧 دليل نشر واحة التركيز على متاجر لينكس (Linux Stores Publishing Guide)

تم إعداد تطبيق **واحة التركيز (Focus Oasis)** بالكامل ليدعم أنظمة وتوزيعات لينكس عبر كافة قنوات التوزيع الرسمية والمتاجر المفتوحة:
1. **متجر Snap Store (Ubuntu & Snapcraft)** - المتجر الافتراضي لنظام أوبونتو وأكثر من 30 مليون مستخدم.
2. **متجر Flathub (Flatpak)** - المتجر الموحد الأكبر لجميع توزيعات لينكس (Fedora, Steam Deck, Linux Mint, Arch, Pop!_OS, Debian).
3. **حزم التثبيت المباشر (.deb)** - لجميع أنظمة ديبيان وأوبونتو ومشتقاتهما.
4. **حزم AppImage المحمولة** - ملف تنفيذي مستقل يعمل بنقرة واحدة على أي توزيعة بدون تثبيت.

---

## 🛍️ 1. متجر كانونيكال (Canonical Snap Store)

يدعم فلاتر حزم Snap بشكل أصيل ومدعوم مباشرة من شركة Canonical المطورة لنظام Ubuntu.

### الملفات المجهزة في المشروع:
- [`snap/snapcraft.yaml`](snap/snapcraft.yaml): ملف التكوين وحزم التبعيات والصلاحيات (`audio-playback`, `desktop`, `network`, إلخ).
- [`snap/gui/focus-oasis.desktop`](snap/gui/focus-oasis.desktop): بطاقة إطلاق التطبيق وقوائم التشغيل.
- [`snap/gui/focus-oasis.png`](snap/gui/focus-oasis.png): أيقونة التطبيق عالية الدقة (1024x1024).

### خطوات النشر التلقائي عبر GitHub Actions (مرة واحدة فقط):
1. سجّل دخولك مجاناً إلى موقع **[snapcraft.io](https://snapcraft.io)** باستخدام حساب Ubuntu One.
2. توجه إلى **Register a name** واحجز الاسم:
   ```
   focus-oasis
   ```
3. في جهازك (أو في بيئة لينكس أو WSL)، قم بتسجيل الدخول وتصدير مفتاح الاعتماد:
   ```bash
   sudo snap install snapcraft --classic
   snapcraft login
   snapcraft export-login --snaps=focus-oasis --acls=package_access,package_manage,package_push,package_register credentials.txt
   ```
4. انسخ محتوى الملف `credentials.txt`.
5. في مستودع GitHub الخاص بمشروعك (`Focus-Oasis`):
   - ادخل إلى **Settings** -> **Secrets and variables** -> **Actions**.
   - أنشئ سراً جديداً باسم:
     ```
     SNAPCRAFT_STORE_CREDENTIALS
     ```
   - والصق محتوى الـ `credentials.txt` داخله.
6. **انتهى!** بمجرد أن تقوم بإنشاء Tag جديد (مثلاً `v1.0.0`) أو تشغيل ورك فلو `Linux Build & Store Release` يدوياً، ستقوم خوادم GitHub Actions ببناء حزمة الـ Snap ورفعها مباشرة إلى المتجر ليصبح متاحاً للتحميل للجميع عبر:
   ```bash
   sudo snap install focus-oasis
   ```

---

## 🌐 2. متجر فلات هاب العالمي (Flathub / Flatpak)

Flathub هو المتجر القياسي لمجتمع لينكس الحر، وهو المتجر المعتمد لأجهزة Steam Deck وتوزيعات Fedora و Linux Mint.

### الملفات المجهزة في المشروع:
- [`flatpak/io.github.ashrafcode519.focus_oasis.yml`](flatpak/io.github.ashrafcode519.focus_oasis.yml): ملف مانفيست فلاتباك الكامل المتوافق مع معايير Flathub.
- [`linux/packaging/io.github.ashrafcode519.focus_oasis.metainfo.xml`](linux/packaging/io.github.ashrafcode519.focus_oasis.metainfo.xml): مواصفة AppStream المعتمدة التي تعرض وصف التطبيق وصوره وتصنيفاته باللغتين العربية والإنجليزية داخل متاجر البرامج (GNOME Software & KDE Discover).
- [`linux/packaging/io.github.ashrafcode519.focus_oasis.desktop`](linux/packaging/io.github.ashrafcode519.focus_oasis.desktop): بطاقة التطبيق القياسية.

### خطوات الإدراج في Flathub:
1. قم بعمل Fork لمستودع طلبات الإدراج في Flathub:
   [https://github.com/flathub/flathub](https://github.com/flathub/flathub)
2. أنشئ فرعاً جديداً (`new-app-focus-oasis`).
3. أضف ملف المانفيست `io.github.ashrafcode519.focus_oasis.yml` ومجلد البيانات.
4. افتح **Pull Request** إلى مستودع Flathub الرئيسي.
5. ستقوم روبوتات Flathub بفحص التطبيق تلقائياً وبنائه. بعد الموافقة والدمج، يُنشئ فريق Flathub مستودعاً خاصاً بالتطبيق تحت منظمة Flathub، ويصبح التطبيق متاحاً للملايين على:
   [https://flathub.org/apps/io.github.ashrafcode519.focus_oasis](https://flathub.org)
   وتثبيته عبر الأمر:
   ```bash
   flatpak install flathub io.github.ashrafcode519.focus_oasis
   ```

---

## 📦 3. حزم التوزيع المباشر (.deb و AppImage)

تم تزويد المستودع بسكريبت أتمتة متكامل:
[`linux/packaging/build_packages.sh`](linux/packaging/build_packages.sh)

يقوم هذا السكريبت ببناء وتوليد 3 صيغ جاهزة فوراً:
1. **ملف Debian (`.deb`):**
   - يُثبت مباشرة بنقرة مزدوجة في Ubuntu Software Center أو عبر الطرفية:
     ```bash
     sudo apt install ./focus-oasis_1.0.0_amd64.deb
     ```
2. **ملف AppImage المحمول:**
   - ملف تنفيذي مستقل لا يحتاج لأي صلاحيات روت أو تثبيت، يعمل على Fedora، Arch، Ubuntu، openSUSE، وغيرها:
     ```bash
     chmod +x FocusOasis-1.0.0-x86_64.AppImage
     ./FocusOasis-1.0.0-x86_64.AppImage
     ```
3. **أرشيف الحزمة الخام (`.tar.gz`):**
   - يحتوي على التطبيق والمكتبات الديناميكية المجمعة.

### أتمتة الرفع لـ GitHub Releases:
تم إعداد سير العمل في ملف:
[`.github/workflows/linux-release.yml`](.github/workflows/linux-release.yml)

عند إنشاء أي إصدار برقم الإصدار (مثل `v1.0.0`):
- يتم بناء حزم `.deb`, `.AppImage`, `.snap`, و `.tar.gz`.
- يتم رفعها تلقائياً وإرفاقها في صفحة **Releases** للمستودع لتمكين المستخدمين من تنزيلها مباشرة.

---

## 🛠️ البناء اليدوي محلياً على جهاز يعمل بنظام لينكس

إذا كنت تعمل على نظام لينكس أو عبر بيئة WSL وتريد تجربة البناء محلياً:

```bash
# 1. تثبيت أدوات التطوير ومكتبات تشغيل الصوت وGTK:
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev

# 2. بناء نسخة لينكس:
flutter build linux --release

# 3. تشغيل سكريبت تحزيم deb و AppImage:
chmod +x linux/packaging/build_packages.sh
./linux/packaging/build_packages.sh 1.0.0
```
ستجد الملفات الناتجة داخل مجلد `dist/`.
