package org.sailings.app.ui

import androidx.compose.foundation.clickable
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
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
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
import org.sailings.app.Voyage

@Composable
fun VoyageListScreen(
    auth: AuthViewModel,
    registrationsChanged: Int,
    onRegistrationsChanged: () -> Unit,
    modifier: Modifier = Modifier,
) {
    var selectedVoyageId by remember { mutableStateOf<Int?>(null) }

    val current = selectedVoyageId
    if (current != null) {
        VoyageDetailScreen(
            auth = auth,
            voyageId = current,
            onBack = { selectedVoyageId = null },
            onRegistrationsChanged = onRegistrationsChanged,
            modifier = modifier,
        )
        return
    }

    val scope = rememberCoroutineScope()
    var voyages by remember { mutableStateOf<List<Voyage>>(emptyList()) }
    var error by remember { mutableStateOf<String?>(null) }
    var loading by remember { mutableStateOf(true) }

    suspend fun load() {
        loading = true
        try {
            voyages = auth.api.voyages()
            error = null
        } catch (e: Exception) {
            auth.handle(e)
            error = e.message
        } finally {
            loading = false
        }
    }

    LaunchedEffect(registrationsChanged) { load() }

    ScreenScaffold(title = "Voyages", modifier = modifier) { content ->
        when {
            loading && voyages.isEmpty() ->
                Box(content.then(Modifier.fillMaxSize()), Alignment.Center) { CircularProgressIndicator() }
            error != null ->
                Box(content) { MessageView("Couldn't load voyages", error) { scope.launch { load() } } }
            voyages.isEmpty() ->
                Box(content) { MessageView("No upcoming voyages", "Scheduled voyages will appear here.") }
            else ->
                LazyColumn(content.then(Modifier.fillMaxSize())) {
                    items(voyages, key = { it.id }) { voyage ->
                        VoyageRow(voyage) { selectedVoyageId = voyage.id }
                        HorizontalDivider()
                    }
                }
        }
    }
}

@Composable
private fun VoyageRow(voyage: Voyage, onClick: () -> Unit) {
    Column(
        Modifier.fillMaxWidth().clickable(onClick = onClick).padding(16.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(voyage.purpose, style = MaterialTheme.typography.titleMedium, modifier = Modifier.weight(1f))
            voyage.myRegistration?.let {
                Spacer(Modifier.width(8.dp))
                StatusBadge(it.status)
            }
        }
        Text(
            voyage.voyageDates,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Text(
            buildString {
                voyage.sailingType?.let { append(it).append(" · ") }
                append("${voyage.participantsCount} crew")
            },
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(top = 2.dp),
        )
    }
}
