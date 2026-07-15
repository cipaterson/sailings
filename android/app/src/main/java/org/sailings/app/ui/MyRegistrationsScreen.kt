package org.sailings.app.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch
import org.sailings.app.AuthViewModel
import org.sailings.app.Registration

@Composable
fun MyRegistrationsScreen(
    auth: AuthViewModel,
    registrationsChanged: Int,
    onRegistrationsChanged: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val scope = rememberCoroutineScope()
    var registrations by remember { mutableStateOf<List<Registration>>(emptyList()) }
    var error by remember { mutableStateOf<String?>(null) }
    var loading by remember { mutableStateOf(true) }

    suspend fun load() {
        loading = true
        try {
            registrations = auth.api.registrations()
            error = null
        } catch (e: Exception) {
            auth.handle(e)
            error = e.message
        } finally {
            loading = false
        }
    }

    LaunchedEffect(registrationsChanged) { load() }

    fun cancel(registration: Registration) {
        scope.launch {
            try {
                auth.api.cancel(registration.id)
                onRegistrationsChanged()
                load()
            } catch (e: Exception) {
                auth.handle(e); error = e.message
            }
        }
    }

    ScreenScaffold(title = "My Registrations", modifier = modifier) { content ->
        when {
            loading && registrations.isEmpty() ->
                Box(content.then(Modifier.fillMaxSize()), Alignment.Center) { CircularProgressIndicator() }
            error != null ->
                Box(content) { MessageView("Couldn't load registrations", error) { scope.launch { load() } } }
            registrations.isEmpty() ->
                Box(content) { MessageView("No registrations yet", "Register for a voyage and it will show up here.") }
            else ->
                LazyColumn(content.then(Modifier.fillMaxSize())) {
                    items(registrations, key = { it.id }) { registration ->
                        RegistrationRow(registration) { cancel(registration) }
                        HorizontalDivider()
                    }
                }
        }
    }
}

@Composable
private fun RegistrationRow(registration: Registration, onCancel: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().padding(start = 16.dp, top = 8.dp, bottom = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(registration.sailing.purpose, style = MaterialTheme.typography.titleMedium, modifier = Modifier.weight(1f))
                Spacer(Modifier.width(8.dp))
                StatusBadge(registration.status)
            }
            Text(
                registration.sailing.voyageDates,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            registration.comment?.takeIf { it.isNotEmpty() }?.let {
                Text(it, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            registration.climbing?.let {
                Text("Climbing: $it", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        IconButton(onClick = onCancel) {
            Icon(Icons.Filled.Delete, contentDescription = "Cancel registration")
        }
    }
}
