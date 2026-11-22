package com.onharu.app

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import javax.crypto.AEADBadTagException
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val sessions = AuthSessionStorage(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.onharu.app/auth_session")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "read" -> result.success(sessions.read())
                        "write" -> {
                            sessions.write(requireNotNull(call.arguments as? String))
                            result.success(null)
                        }
                        "delete" -> {
                            sessions.delete()
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (_: Exception) {
                    result.error("AUTH_STORAGE", "로그인 저장소를 사용할 수 없습니다.", null)
                }
            }
    }
}

private class AuthSessionStorage(activity: FlutterActivity) {
    private val preferences = activity.getSharedPreferences("onharu_auth_session", Context.MODE_PRIVATE)
    private val alias = "com.onharu.app.auth_session"

    private fun keyStore() = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }

    fun read(): String? {
        val stored = preferences.getString("encrypted_session", null) ?: return null
        val key = keyStore().getKey(alias, null) as? SecretKey
        if (key == null) {
            delete() // 다른 기기에서 복원된 데이터는 이 기기의 키로 열 수 없다.
            return null
        }
        return try {
            val (iv, encrypted) = stored.split(':', limit = 2)
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, Base64.decode(iv, Base64.NO_WRAP)))
            cipher.doFinal(Base64.decode(encrypted, Base64.NO_WRAP)).toString(Charsets.UTF_8)
        } catch (_: AEADBadTagException) {
            delete()
            null
        } catch (_: IllegalArgumentException) {
            delete()
            null
        } catch (_: IndexOutOfBoundsException) {
            delete()
            null
        }
    }

    fun write(session: String) {
        val key = keyStore().getKey(alias, null) as? SecretKey ?: createKey()
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key)
        val iv = Base64.encodeToString(cipher.iv, Base64.NO_WRAP)
        val encrypted = Base64.encodeToString(cipher.doFinal(session.toByteArray(Charsets.UTF_8)), Base64.NO_WRAP)
        check(preferences.edit().putString("encrypted_session", "$iv:$encrypted").commit())
    }

    fun delete() {
        check(preferences.edit().remove("encrypted_session").commit())
    }

    private fun createKey(): SecretKey {
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build()
        )
        return generator.generateKey()
    }
}
