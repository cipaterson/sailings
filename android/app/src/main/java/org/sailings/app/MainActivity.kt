package org.sailings.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import org.sailings.app.ui.LoginScreen
import org.sailings.app.ui.RootScreen
import org.sailings.app.ui.theme.SailingsTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            SailingsTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    AppRoot()
                }
            }
        }
    }
}

@Composable
private fun AppRoot(auth: AuthViewModel = viewModel()) {
    val state by auth.state.collectAsStateWithLifecycle()
    when (state.phase) {
        AuthViewModel.Phase.RESTORING ->
            Box(Modifier.fillMaxSize(), Alignment.Center) { CircularProgressIndicator() }
        AuthViewModel.Phase.SIGNED_OUT -> LoginScreen(auth)
        AuthViewModel.Phase.SIGNED_IN -> RootScreen(auth)
    }
}
