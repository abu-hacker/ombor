// Android manifestga kamera ruxsatini qo'shadi va ilova nomini o'rnatadi.
// Ishlatish: dart tool/patch_android.dart
import 'dart:io';

void main() {
  final f = File('android/app/src/main/AndroidManifest.xml');
  if (!f.existsSync()) {
    stderr.writeln('AndroidManifest.xml topilmadi. Avval "flutter create" ishlating.');
    exit(1);
  }
  var s = f.readAsStringSync();
  if (!s.contains('android.permission.CAMERA')) {
    s = s.replaceFirst(
      '<application',
      '<uses-permission android:name="android.permission.CAMERA"/>\n'
          '    <uses-feature android:name="android.hardware.camera" android:required="false"/>\n'
          '    <application',
    );
  }
  s = s.replaceFirst('android:label="tovar_boshqaruv"', 'android:label="Tovar boshqaruv"');
  f.writeAsStringSync(s);
  stdout.writeln('Android manifest yangilandi.');
}
