import java.util.Base64

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// `--dart-define`/`--dart-define-from-file` 값은 Flutter 가 base64 로 묶어 dart-defines 프로퍼티로 넘겨준다.
// Dart 코드와 manifest 가 같은 카카오 앱 키를 쓰도록 여기서 풀어 읽는다.
val dartDefines: Map<String, String> =
    (project.findProperty("dart-defines") as String?)
        ?.split(",")
        ?.map { String(Base64.getDecoder().decode(it)) }
        ?.mapNotNull { entry ->
            val parts = entry.split("=", limit = 2)
            if (parts.size == 2) parts[0] to parts[1] else null
        }
        ?.toMap()
        ?: emptyMap()

android {
    namespace = "com.onharu.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications 의 예약 알림이 java.time 을 쓰므로 desugaring 이 필요합니다.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Play 업로드 후에는 바꿀 수 없고, Kakao Developers 의 Android 플랫폼 등록값과 같아야 합니다.
        applicationId = "com.onharu.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // 카카오계정 로그인 후 앱으로 돌아오는 스킴(kakao{네이티브 앱 키}://oauth)에 쓴다.
        manifestPlaceholders["kakaoNativeAppKey"] = dartDefines["KAKAO_NATIVE_APP_KEY"] ?: ""
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
