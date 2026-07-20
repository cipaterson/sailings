package org.sailings.app.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import kotlinx.datetime.LocalDate
import kotlinx.datetime.Month
import org.sailings.app.RegistrationStatus

/** A titled screen with a top app bar; content receives the inset padding. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ScreenScaffold(
    title: String,
    modifier: Modifier = Modifier,
    navigationIcon: @Composable () -> Unit = {},
    content: @Composable (Modifier) -> Unit,
) {
    Scaffold(
        modifier = modifier,
        topBar = { TopAppBar(title = { Text(title) }, navigationIcon = navigationIcon) },
    ) { padding ->
        content(Modifier.padding(padding))
    }
}

/** Colour-codes a registration status the way the crew list reads it. */
@Composable
fun StatusBadge(status: String) {
    val color = when (status) {
        RegistrationStatus.ACCEPTED -> Color(0xFF2E7D32)
        RegistrationStatus.EOI -> Color(0xFFE65100)
        else -> MaterialTheme.colorScheme.onSurfaceVariant
    }
    Surface(color = color.copy(alpha = 0.15f), shape = RoundedCornerShape(50), contentColor = color) {
        Text(
            status,
            style = MaterialTheme.typography.labelMedium,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp),
        )
    }
}

/** Shown instead of a list when a screen has nothing to show or the request failed. */
@Composable
fun MessageView(title: String, detail: String? = null, onRetry: (() -> Unit)? = null) {
    Column(
        modifier = Modifier.fillMaxSize().padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(title, style = MaterialTheme.typography.titleMedium, textAlign = TextAlign.Center)
        if (detail != null) {
            Text(
                detail,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 8.dp),
            )
        }
        if (onRetry != null) {
            Button(onClick = onRetry, modifier = Modifier.padding(top = 16.dp)) { Text("Try Again") }
        }
    }
}

/** Formats a calendar date as "15 Jul 2026", matching the iOS `.asDay`. */
fun LocalDate.asDay(): String {
    val month = when (month) {
        Month.JANUARY -> "Jan"; Month.FEBRUARY -> "Feb"; Month.MARCH -> "Mar"
        Month.APRIL -> "Apr"; Month.MAY -> "May"; Month.JUNE -> "Jun"
        Month.JULY -> "Jul"; Month.AUGUST -> "Aug"; Month.SEPTEMBER -> "Sep"
        Month.OCTOBER -> "Oct"; Month.NOVEMBER -> "Nov"; Month.DECEMBER -> "Dec"
        else -> ""
    }
    return "$dayOfMonth $month $year"
}
