package org.sailings.app

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

/**
 * The bearer token lives in EncryptedSharedPreferences rather than plain
 * SharedPreferences: it is a credential, and this is the Android analog of the
 * iOS Keychain.
 */
class TokenStore(context: Context) {

    private val prefs: SharedPreferences = run {
        val key = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
        EncryptedSharedPreferences.create(
            context,
            "sailings.secure",
            key,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
        )
    }

    var token: String?
        get() = prefs.getString(KEY, null)
        set(value) = prefs.edit().apply {
            if (value == null) remove(KEY) else putString(KEY, value)
        }.apply()

    private companion object {
        const val KEY = "api-token"
    }
}
