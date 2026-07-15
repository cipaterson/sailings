package org.sailings.app.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
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
fun VoyageDetailScreen(
    auth: AuthViewModel,
    voyageId: Int,
    onBack: () -> Unit,
    onRegistrationsChanged: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val scope = rememberCoroutineScope()
    var voyage by remember { mutableStateOf<Voyage?>(null) }
    var error by remember { mutableStateOf<String?>(null) }
    var working by remember { mutableStateOf(false) }
    var actionError by remember { mutableStateOf<String?>(null) }
    var showRegister by remember { mutableStateOf(false) }

    suspend fun load() {
        try {
            voyage = auth.api.voyage(voyageId)
            error = null
        } catch (e: Exception) {
            auth.handle(e)
            error = e.message
        }
    }

    LaunchedEffect(voyageId) { load() }

    ScreenScaffold(
        title = voyage?.purpose ?: "Voyage",
        modifier = modifier,
        navigationIcon = {
            IconButton(onClick = onBack) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
            }
        },
    ) { content ->
        val v = voyage
        when {
            v != null -> Column(
                content
                    .then(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Field("Voyage", v.purpose)
                Field("Dates", v.voyageDates)
                v.sailingType?.let { Field("Type", it) }
                v.training?.let { Field("Training", it) }
                Field("Crew", "${v.participantsCount}")
                v.master?.takeIf { it.isNotEmpty() }?.let { Field("Master", it) }
                v.engineer?.takeIf { it.isNotEmpty() }?.let { Field("Engineer", it) }
                v.lnContact?.takeIf { it.isNotEmpty() }?.let { Field("LN Contact", it) }
                v.comments?.takeIf { it.isNotEmpty() }?.let { Paragraph("Comments", it) }
                v.additionalDetails?.takeIf { it.isNotEmpty() }?.let { Paragraph("Additional Details", it) }

                Spacer(Modifier.height(8.dp))

                val registration = v.myRegistration
                if (registration != null) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("Your registration", modifier = Modifier.weight(1f))
                        StatusBadge(registration.status)
                    }
                    OutlinedButton(
                        onClick = {
                            scope.launch {
                                working = true; actionError = null
                                try {
                                    auth.api.cancel(registration.id)
                                    onRegistrationsChanged()
                                    load()
                                } catch (e: Exception) {
                                    auth.handle(e); actionError = e.message
                                } finally { working = false }
                            }
                        },
                        enabled = !working,
                        modifier = Modifier.fillMaxWidth(),
                    ) { Text("Cancel Registration") }
                } else {
                    Button(
                        onClick = { showRegister = true },
                        enabled = !working,
                        modifier = Modifier.fillMaxWidth(),
                    ) { Text("Register for this Voyage") }
                }

                actionError?.let {
                    Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
                }
            }
            error != null ->
                Box(content) { MessageView("Couldn't load voyage", error) { scope.launch { load() } } }
            else ->
                Box(content.then(Modifier.fillMaxSize()), Alignment.Center) { CircularProgressIndicator() }
        }
    }

    if (showRegister) {
        RegisterDialog(
            onDismiss = { showRegister = false },
            onConfirm = { comment, climbing ->
                scope.launch {
                    working = true; actionError = null
                    try {
                        auth.api.register(voyageId, comment, climbing)
                        showRegister = false
                        onRegistrationsChanged()
                        load()
                    } catch (e: Exception) {
                        auth.handle(e); actionError = e.message; showRegister = false
                    } finally { working = false }
                }
            },
        )
    }
}

@Composable
private fun Field(label: String, value: String) {
    Row {
        Text(label, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.weight(1f))
        Text(value, style = MaterialTheme.typography.bodyMedium)
    }
}

@Composable
private fun Paragraph(label: String, value: String) {
    Column {
        Text(label, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(value, style = MaterialTheme.typography.bodyMedium)
    }
}

/** Asks the two questions the web form asks: a comment, and willingness to climb. */
@Composable
private fun RegisterDialog(
    onDismiss: () -> Unit,
    onConfirm: (comment: String?, climbing: Int?) -> Unit,
) {
    var comment by remember { mutableStateOf("") }
    // Rails encoding: 1 = Yes, 2 = No, null = not specified.
    var climbing by remember { mutableStateOf<Int?>(null) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Register") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("Willing to climb?", style = MaterialTheme.typography.labelLarge)
                Row {
                    ClimbingOption("Not specified", climbing == null) { climbing = null }
                    ClimbingOption("Yes", climbing == 1) { climbing = 1 }
                    ClimbingOption("No", climbing == 2) { climbing = 2 }
                }
                OutlinedTextField(
                    value = comment,
                    onValueChange = { comment = it },
                    label = { Text("Comment (optional)") },
                    modifier = Modifier.fillMaxWidth(),
                )
                Text(
                    "You'll be registered as an expression of interest. The crewing operator confirms the final crew.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        },
        confirmButton = { TextButton(onClick = { onConfirm(comment.ifBlank { null }, climbing) }) { Text("Register") } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } },
    )
}

@Composable
private fun ClimbingOption(label: String, selected: Boolean, onSelect: () -> Unit) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.selectable(selected = selected, onClick = onSelect).padding(end = 8.dp),
    ) {
        RadioButton(selected = selected, onClick = onSelect)
        Text(label, style = MaterialTheme.typography.bodySmall)
    }
}
