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
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.todayIn
import org.sailings.app.AuthViewModel
import org.sailings.app.Profile
import org.sailings.app.Qualification

@Composable
fun ProfileScreen(auth: AuthViewModel, modifier: Modifier = Modifier) {
    val scope = rememberCoroutineScope()
    var profile by remember { mutableStateOf<Profile?>(null) }
    var error by remember { mutableStateOf<String?>(null) }

    suspend fun load() {
        try {
            profile = auth.api.profile()
            error = null
        } catch (e: Exception) {
            auth.handle(e)
            error = e.message
        }
    }

    LaunchedEffect(Unit) { load() }

    ScreenScaffold(title = "Profile", modifier = modifier) { content ->
        val p = profile
        when {
            p != null -> Column(
                content.then(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)),
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                SectionHeader("Member")
                Field("Name", p.fullName)
                Field("Email", p.emailAddress)
                p.membershipType?.let { Field("Membership", it) }
                p.dateJoined?.let { Field("Joined", it.asDay()) }

                Spacer(Modifier.height(8.dp))
                SectionHeader("Sailing Record")
                Field("Days sailed", "${p.sailingRecord.daysSailed}")
                Field("Last sailed", p.sailingRecord.lastSailed?.asDay() ?: "—")
                p.sailingRecord.sailingClass?.takeIf { it.isNotEmpty() }?.let { Field("Class", it) }

                Spacer(Modifier.height(8.dp))
                SectionHeader("Qualifications")
                val today = Clock.System.todayIn(TimeZone.currentSystemDefault())
                p.qualifications.forEach { QualificationRow(it, today) }

                Spacer(Modifier.height(8.dp))
                SectionHeader("Training")
                p.training.forEach { Field(it.label, it.completedOn?.asDay() ?: "—") }

                Spacer(Modifier.height(16.dp))
                OutlinedButton(onClick = { auth.signOut() }, modifier = Modifier.fillMaxWidth()) {
                    Text("Sign Out")
                }
            }
            error != null ->
                Box(content) { MessageView("Couldn't load profile", error) { scope.launch { load() } } }
            else ->
                Box(content.then(Modifier.fillMaxSize()), Alignment.Center) { CircularProgressIndicator() }
        }
    }
}

@Composable
private fun SectionHeader(text: String) {
    Text(text, style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.primary)
    HorizontalDivider()
}

@Composable
private fun Field(label: String, value: String) {
    Row {
        Text(label, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.weight(1f))
        Text(value, style = MaterialTheme.typography.bodyMedium)
    }
}

@Composable
private fun QualificationRow(qualification: Qualification, today: kotlinx.datetime.LocalDate) {
    val standing = qualification.standing(today)
    val color = when (standing) {
        Qualification.Standing.EXPIRED -> MaterialTheme.colorScheme.error
        Qualification.Standing.EXPIRING_SOON -> Color(0xFFE65100)
        Qualification.Standing.CURRENT -> Color(0xFF2E7D32)
        Qualification.Standing.NONE -> MaterialTheme.colorScheme.onSurfaceVariant
    }
    val note = when (standing) {
        Qualification.Standing.EXPIRED -> "Expired"
        Qualification.Standing.EXPIRING_SOON -> "Expiring soon"
        Qualification.Standing.CURRENT -> "Current"
        Qualification.Standing.NONE -> ""
    }
    Row {
        Column(Modifier.weight(1f)) {
            Text(qualification.label, style = MaterialTheme.typography.bodyMedium)
            qualification.value?.takeIf { it.isNotEmpty() }?.let {
                Text(it, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        Column(horizontalAlignment = Alignment.End) {
            Text(qualification.expiresOn?.asDay() ?: "—", style = MaterialTheme.typography.bodySmall, color = color, textAlign = TextAlign.End)
            if (note.isNotEmpty()) {
                Text(note, style = MaterialTheme.typography.labelSmall, color = color)
            }
        }
    }
}
