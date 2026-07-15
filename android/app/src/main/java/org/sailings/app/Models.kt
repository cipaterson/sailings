package org.sailings.app

import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.Instant
import kotlinx.datetime.LocalDate
import kotlinx.datetime.plus
import kotlinx.serialization.Serializable

// The API mixes two date shapes, and modelling them as distinct types makes the
// compiler enforce which serializer applies: full ISO-8601 timestamps decode as
// Instant (departs_at, returns_at, created_at); bare yyyy-MM-dd calendar dates
// decode as LocalDate (expires_on, issued_on, last_sailed, date_joined,
// completed_on). kotlinx-datetime supplies an ISO serializer for each out of the
// box, so no custom handling is needed here.
//
// JSON keys are snake_case; the ApiClient's Json is configured with
// JsonNamingStrategy.SnakeCase, so camelCase property names map automatically.

/** A voyage. Named for the UI term; the Rails side calls it a Sailing. */
@Serializable
data class Voyage(
    val id: Int,
    val purpose: String,
    val displayName: String,
    val sailingType: String? = null,
    val status: String,
    val training: String? = null,
    val departsAt: Instant? = null,
    val returnsAt: Instant? = null,
    val voyageDates: String,
    val master: String? = null,
    val engineer: String? = null,
    val lnContact: String? = null,
    val comments: String? = null,
    val additionalDetails: String? = null,
    val participantsCount: Int,
    /**
     * Present on /sailings responses; absent when a voyage is nested inside a
     * registration, where it would be redundant.
     */
    val myRegistration: RegistrationRef? = null,
)

@Serializable
data class RegistrationRef(
    val id: Int,
    val status: String,
)

@Serializable
data class Registration(
    val id: Int,
    val status: String,
    val comment: String? = null,
    /** The API returns this as "Yes"/"No"; the register call sends 1/2. */
    val climbing: String? = null,
    val attended: Boolean = false,
    val createdAt: Instant? = null,
    val sailing: Voyage,
)

@Serializable
data class Profile(
    val id: Int,
    val emailAddress: String,
    val firstName: String? = null,
    val lastName: String? = null,
    val fullName: String,
    val membershipType: String? = null,
    val dateJoined: LocalDate? = null,
    val roles: List<String> = emptyList(),
    val skills: List<String> = emptyList(),
    val sailingRecord: SailingRecord,
    val qualifications: List<Qualification> = emptyList(),
    val training: List<TrainingRecord> = emptyList(),
)

@Serializable
data class SailingRecord(
    val daysSailed: Int = 0,
    val lastSailed: LocalDate? = null,
    val sailingClass: String? = null,
)

@Serializable
data class Qualification(
    val key: String,
    val label: String,
    val value: String? = null,
    val issuedOn: LocalDate? = null,
    val expiresOn: LocalDate? = null,
) {
    enum class Standing { NONE, EXPIRED, EXPIRING_SOON, CURRENT }

    /** Drives the "am I current?" colouring on the profile screen. */
    fun standing(today: LocalDate): Standing {
        val expires = expiresOn ?: return if (!value.isNullOrEmpty()) Standing.CURRENT else Standing.NONE
        return when {
            expires < today -> Standing.EXPIRED
            expires < today.plus(SOON_DAYS, DateTimeUnit.DAY) -> Standing.EXPIRING_SOON
            else -> Standing.CURRENT
        }
    }

    private companion object {
        const val SOON_DAYS = 60
    }
}

@Serializable
data class TrainingRecord(
    val key: String,
    val label: String,
    val completedOn: LocalDate? = null,
)

@Serializable
data class LoginResponse(
    val token: String,
    val user: Profile,
)

/** Registration status values as Rails defines them (SailingParticipant::STATUSES). */
object RegistrationStatus {
    const val EOI = "EOI"
    const val ACCEPTED = "Accepted"
    const val NOT_REQUIRED = "Not-required"
}
