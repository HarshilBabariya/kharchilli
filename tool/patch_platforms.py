"""Applies Gharcha's native settings to the android/ and ios/ folders that `flutter create` generates.

Run from the project root after `flutter create`; see tool/bootstrap.sh. Safe to run twice.
"""
import pathlib, plistlib, re, shutil, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
MARK = 'gharcha-patched'


def patch(path, edits):
    text = path.read_text()
    if MARK in text:
        return
    for anchor, replacement in edits:
        if anchor not in text:
            sys.exit(f'{path}: expected to find "{anchor}". The Flutter template changed; update tool/patch_platforms.py.')
        text = text.replace(anchor, replacement, 1)
    path.write_text(text)


SIGNING = '''    // gharcha-patched
    signingConfigs {
        create("gharcha") {
            val props = Properties()
            val keyFile = rootProject.file("key.properties")
            if (keyFile.exists()) keyFile.inputStream().use { props.load(it) }
            storeFile = file(props.getProperty("storeFile") ?: "sideload.keystore")
            storePassword = props.getProperty("storePassword") ?: "android"
            keyAlias = props.getProperty("keyAlias") ?: "androiddebugkey"
            keyPassword = props.getProperty("keyPassword") ?: "android"
        }
    }

    buildTypes {'''

PERMISSIONS = '''    <!-- gharcha-patched -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.USE_BIOMETRIC" />
    <queries>
        <intent>
            <action android:name="android.speech.RecognitionService" />
        </intent>
    </queries>
    <application'''

# Only added with --capture (the Play Store build): Play Protect blocks a sideloaded APK that declares a notification listener.
CAPTURE = '''        <service
            android:name=".PaymentListener"
            android:exported="false"
            android:label="Gharcha payment capture"
            android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE">
            <intent-filter>
                <action android:name="android.service.notification.NotificationListenerService" />
            </intent-filter>
        </service>
'''

WIDGETS = {'Spend': ('spend', 'Gharcha · This month'), 'Quick': ('quick', 'Gharcha · Quick add'), 'Today': ('today', 'Gharcha · Today'), 'Bills': ('bills', 'Gharcha · Upcoming bills'), 'Shopping': ('shopping', 'Gharcha · Shopping list')}

RECEIVERS = ''.join(f'''        <receiver android:name=".{name}Widget" android:exported="true" android:label="{label}">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data android:name="android.appwidget.provider" android:resource="@xml/widget_{layout}_info" />
        </receiver>
''' for name, (layout, label) in WIDGETS.items()) + '''        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON" />
            </intent-filter>
        </receiver>
    </application>'''

android = ROOT / 'android' / 'app'
if android.exists():
    patch(android / 'build.gradle.kts', [
        ('plugins {', 'import java.util.Properties\n\nplugins {'),
        ('compileOptions {', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true'),
        ('    buildTypes {', SIGNING),
        ('signingConfigs.getByName("debug")', 'signingConfigs.getByName("gharcha")\n            isMinifyEnabled = false\n            isShrinkResources = false'),
    ])
    gradle = android / 'build.gradle.kts'
    if 'desugar_jdk_libs' not in gradle.read_text():
        gradle.write_text(gradle.read_text() + '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n')
    manifest = android / 'src' / 'main' / 'AndroidManifest.xml'
    patch(manifest, [('    <application', PERMISSIONS), ('    </application>', RECEIVERS)])
    manifest.write_text(re.sub(r'android:label="[^"]*"', 'android:label="Gharcha"', manifest.read_text(), count=1))
    if '--capture' in sys.argv and CAPTURE not in manifest.read_text():
        manifest.write_text(manifest.read_text().replace('    </application>', CAPTURE + '    </application>', 1))
    shutil.copytree(ROOT / 'platform' / 'android' / 'res', android / 'src' / 'main' / 'res', dirs_exist_ok=True)
    # The fingerprint prompt needs a FragmentActivity and, on Android 8 and below, an AppCompat theme.
    for folder, parent in (('values', 'Theme.AppCompat.Light.NoActionBar'), ('values-night', 'Theme.AppCompat.NoActionBar')):
        styles = android / 'src' / 'main' / 'res' / folder / 'styles.xml'
        if styles.exists():
            styles.write_text(re.sub(r'parent="@android:style/Theme\.[A-Za-z.]+"', f'parent="{parent}"', styles.read_text()))
    for activity in (android / 'src' / 'main').rglob('MainActivity.kt'):
        activity.write_text(activity.read_text().replace('FlutterActivity', 'FlutterFragmentActivity'))
        shutil.copytree(ROOT / 'platform' / 'android' / 'kotlin', activity.parent, dirs_exist_ok=True)
    shutil.copy(ROOT / 'platform' / 'android' / 'sideload.keystore', android / 'sideload.keystore')

plist_path = ROOT / 'ios' / 'Runner' / 'Info.plist'
if plist_path.exists():
    assets = ROOT / 'ios' / 'Runner' / 'Assets.xcassets'
    shutil.rmtree(assets / 'AppIcon.appiconset')
    shutil.copytree(ROOT / 'platform' / 'ios' / 'AppIcon.appiconset', assets / 'AppIcon.appiconset')
    shutil.copytree(ROOT / 'platform' / 'ios' / 'LaunchImage.imageset', assets / 'LaunchImage.imageset', dirs_exist_ok=True)
    storyboard = ROOT / 'ios' / 'Runner' / 'Base.lproj' / 'LaunchScreen.storyboard'
    painted, found = re.subn(r'<color key="backgroundColor"[^>]*/>', '<color key="backgroundColor" red="0.910" green="0.125" blue="0.247" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>', storyboard.read_text())
    if not found:
        sys.exit(f'{storyboard}: no backgroundColor to repaint. The Flutter template changed; update tool/patch_platforms.py.')
    storyboard.write_text(painted)
    with plist_path.open('rb') as f:
        plist = plistlib.load(f)
    plist.update({
        'CFBundleDisplayName': 'Gharcha',
        'NSMicrophoneUsageDescription': 'Gharcha listens when you tap the mic so you can add an expense by saying it.',
        'NSSpeechRecognitionUsageDescription': 'Gharcha turns what you say into an expense: amount, category and payment mode.',
        'NSCameraUsageDescription': 'Gharcha uses the camera when you attach a photo of a receipt to an expense.',
        'NSPhotoLibraryUsageDescription': 'Gharcha opens your photos when you attach a receipt picture to an expense.',
        'NSFaceIDUsageDescription': 'Gharcha can use Face ID instead of your PIN to open your profile.',
        'ITSAppUsesNonExemptEncryption': False,
    })
    with plist_path.open('wb') as f:
        plistlib.dump(plist, f)
