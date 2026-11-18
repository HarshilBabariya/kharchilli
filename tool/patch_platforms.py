"""Applies Kharchili's native settings to the android/ and ios/ folders that `flutter create` generates.

Run from the project root after `flutter create`; see tool/bootstrap.sh. Safe to run twice.
"""
import pathlib, plistlib, re, shutil, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
MARK = 'kharchili-patched'


def patch(path, edits):
    text = path.read_text()
    if MARK in text:
        return
    for anchor, replacement in edits:
        if anchor not in text:
            sys.exit(f'{path}: expected to find "{anchor}". The Flutter template changed; update tool/patch_platforms.py.')
        text = text.replace(anchor, replacement, 1)
    path.write_text(text)


SIGNING = '''    // kharchili-patched
    signingConfigs {
        create("kharchili") {
            val props = java.util.Properties()
            val keyFile = rootProject.file("key.properties")
            if (keyFile.exists()) keyFile.inputStream().use { props.load(it) }
            storeFile = file(props.getProperty("storeFile") ?: "sideload.keystore")
            storePassword = props.getProperty("storePassword") ?: "android"
            keyAlias = props.getProperty("keyAlias") ?: "androiddebugkey"
            keyPassword = props.getProperty("keyPassword") ?: "android"
        }
    }

    buildTypes {'''

PERMISSIONS = '''    <!-- kharchili-patched -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <queries>
        <intent>
            <action android:name="android.speech.RecognitionService" />
        </intent>
    </queries>
    <application'''

RECEIVERS = '''        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
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
        ('compileOptions {', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true'),
        ('    buildTypes {', SIGNING),
        ('signingConfigs.getByName("debug")', 'signingConfigs.getByName("kharchili")'),
    ])
    gradle = android / 'build.gradle.kts'
    if 'desugar_jdk_libs' not in gradle.read_text():
        gradle.write_text(gradle.read_text() + '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n')
    manifest = android / 'src' / 'main' / 'AndroidManifest.xml'
    patch(manifest, [('    <application', PERMISSIONS), ('    </application>', RECEIVERS)])
    manifest.write_text(re.sub(r'android:label="[^"]*"', 'android:label="Kharchili"', manifest.read_text(), count=1))
    shutil.copytree(ROOT / 'platform' / 'android' / 'res', android / 'src' / 'main' / 'res', dirs_exist_ok=True)
    shutil.copy(ROOT / 'platform' / 'android' / 'sideload.keystore', android / 'sideload.keystore')

plist_path = ROOT / 'ios' / 'Runner' / 'Info.plist'
if plist_path.exists():
    with plist_path.open('rb') as f:
        plist = plistlib.load(f)
    plist.update({
        'CFBundleDisplayName': 'Kharchili',
        'NSMicrophoneUsageDescription': 'Kharchili listens when you tap the mic so you can add an expense by saying it.',
        'NSSpeechRecognitionUsageDescription': 'Kharchili turns what you say into an expense: amount, category and payment mode.',
        'ITSAppUsesNonExemptEncryption': False,
    })
    with plist_path.open('wb') as f:
        plistlib.dump(plist, f)
