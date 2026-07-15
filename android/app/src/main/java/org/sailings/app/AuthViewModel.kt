package org.sailings.app

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * Owns the token lifecycle and the signed-in/out state, mirroring the iOS
 * AuthStore. A single shared ApiClient is exposed so the screens issue requests
 * through the same authenticated instance.
 */
class AuthViewModel(app: Application) : AndroidViewModel(app) {

    enum class Phase { RESTORING, SIGNED_OUT, SIGNED_IN }

    data class State(
        val phase: Phase = Phase.RESTORING,
        val profile: Profile? = null,
        val isSubmitting: Boolean = false,
        val errorMessage: String? = null,
    )

    val api = ApiClient()
    private val tokens = TokenStore(app)

    private val _state = MutableStateFlow(State())
    val state: StateFlow<State> = _state.asStateFlow()

    init { restore() }

    /**
     * At launch, a token in the store is only good if the server still honours
     * it, so prove it with a real request rather than assuming.
     */
    private fun restore() {
        val saved = tokens.token
        if (saved == null) {
            _state.value = State(phase = Phase.SIGNED_OUT)
            return
        }
        api.token = saved
        viewModelScope.launch {
            try {
                val profile = api.profile()
                _state.value = State(phase = Phase.SIGNED_IN, profile = profile)
            } catch (e: Exception) {
                discardCredentials()
            }
        }
    }

    fun signIn(emailAddress: String, password: String) {
        _state.value = _state.value.copy(isSubmitting = true, errorMessage = null)
        viewModelScope.launch {
            try {
                val response = api.login(emailAddress.trim(), password)
                tokens.token = response.token
                api.token = response.token
                _state.value = State(phase = Phase.SIGNED_IN, profile = response.user)
            } catch (e: Exception) {
                _state.value = _state.value.copy(isSubmitting = false, errorMessage = e.message)
            }
        }
    }

    fun signOut() {
        viewModelScope.launch {
            // Revoke server-side too, so the token dies with the session.
            runCatching { api.logout() }
            discardCredentials()
        }
    }

    /**
     * Any 401 mid-session means the token is gone (logged out elsewhere, account
     * disabled). Screens call this on failure; only Unauthorized acts.
     */
    fun handle(error: Throwable) {
        if (error is ApiException.Unauthorized) {
            viewModelScope.launch { discardCredentials() }
        }
    }

    private fun discardCredentials() {
        tokens.token = null
        api.token = null
        _state.value = State(phase = Phase.SIGNED_OUT)
    }
}
