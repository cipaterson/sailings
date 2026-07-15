package org.sailings.app.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.List
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import org.sailings.app.AuthViewModel

private enum class Tab(val label: String, val icon: ImageVector) {
    Voyages("Voyages", Icons.AutoMirrored.Filled.List),
    Registrations("My Registrations", Icons.Filled.CheckCircle),
    Profile("Profile", Icons.Filled.Person),
}

@Composable
fun RootScreen(auth: AuthViewModel) {
    var selected by remember { mutableStateOf(Tab.Voyages) }
    // Bumped whenever a registration changes, so the other tabs refetch instead
    // of showing a stale list when the user switches to them. Mirrors the iOS
    // `registrationsChanged` binding.
    var registrationsChanged by remember { mutableIntStateOf(0) }
    val onRegistrationsChanged = { registrationsChanged++ }

    Scaffold(
        bottomBar = {
            NavigationBar {
                Tab.entries.forEach { tab ->
                    NavigationBarItem(
                        selected = selected == tab,
                        onClick = { selected = tab },
                        icon = { Icon(tab.icon, contentDescription = tab.label) },
                        label = { Text(tab.label) },
                    )
                }
            }
        },
    ) { padding ->
        val content = Modifier.padding(padding)
        when (selected) {
            Tab.Voyages -> VoyageListScreen(auth, registrationsChanged, onRegistrationsChanged, content)
            Tab.Registrations -> MyRegistrationsScreen(auth, registrationsChanged, onRegistrationsChanged, content)
            Tab.Profile -> ProfileScreen(auth, content)
        }
    }
}
