package org.sailings.app

import io.ktor.client.HttpClient
import io.ktor.client.engine.okhttp.OkHttp
import io.ktor.client.request.header
import io.ktor.client.request.request
import io.ktor.client.request.setBody
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpMethod
import io.ktor.http.contentType
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonNamingStrategy
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/** Mirrors the iOS APIError: a typed failure the UI can render directly. */
sealed class ApiException(message: String) : Exception(message) {
    /** The token is gone (expired, logged out elsewhere, account disabled). */
    data object Unauthorized :
        ApiException("Your session has expired. Please sign in again.")

    /** A single server-supplied message, from `{"error": "..."}`. */
    class Message(val text: String) : ApiException(text)

    /** Validation failures, from `{"errors": [...]}`. */
    class Validation(val errors: List<String>) : ApiException(errors.joinToString("\n"))

    /** Couldn't reach the server at all. */
    class Transport(cause: Throwable) :
        ApiException("Couldn't reach the server. Check your connection and that the server is running.") {
        init { initCause(cause) }
    }

    /** The server replied, but the body didn't decode. */
    class Decoding(cause: Throwable) :
        ApiException("The server sent something unexpected.") {
        init { initCause(cause) }
    }
}

@OptIn(ExperimentalSerializationApi::class)
class ApiClient(private val baseUrl: String = Config.API_ROOT) {

    /** snake_case keys, tolerant of unknown fields, nulls omitted when encoding. */
    private val json = Json {
        namingStrategy = JsonNamingStrategy.SnakeCase
        ignoreUnknownKeys = true
        explicitNulls = false
    }

    private val http = HttpClient(OkHttp) {
        expectSuccess = false
    }

    /** Set after login, cleared on logout or any 401. */
    @Volatile
    var token: String? = null

    // region Endpoints

    suspend fun login(emailAddress: String, password: String): LoginResponse {
        val body = buildJsonObject {
            put("email_address", emailAddress)
            put("password", password)
        }
        return decode(request(HttpMethod.Post, "/session", body))
    }

    suspend fun logout() {
        request(HttpMethod.Delete, "/session")
    }

    suspend fun profile(): Profile =
        decode(request(HttpMethod.Get, "/profile"))

    suspend fun voyages(): List<Voyage> =
        decode(request(HttpMethod.Get, "/sailings"))

    suspend fun voyage(id: Int): Voyage =
        decode(request(HttpMethod.Get, "/sailings/$id"))

    suspend fun registrations(): List<Registration> =
        decode(request(HttpMethod.Get, "/registrations"))

    /** `climbing` follows the Rails encoding: 1 = Yes, 2 = No. */
    suspend fun register(voyageId: Int, comment: String?, climbing: Int?): Registration {
        val body = buildJsonObject {
            if (!comment.isNullOrEmpty()) put("comment", comment)
            if (climbing != null) put("climbing", climbing)
        }
        return decode(request(HttpMethod.Post, "/sailings/$voyageId/registrations", body))
    }

    suspend fun cancel(registrationId: Int) {
        request(HttpMethod.Delete, "/registrations/$registrationId")
    }

    // endregion

    // region Plumbing

    private inline fun <reified T> decode(text: String): T =
        try {
            json.decodeFromString<T>(text)
        } catch (e: Exception) {
            throw ApiException.Decoding(e)
        }

    /** Performs the request and maps the HTTP status to a typed result or exception. */
    private suspend fun request(
        method: HttpMethod,
        path: String,
        body: JsonObject? = null,
    ): String {
        val response = try {
            http.request(baseUrl + path) {
                this.method = method
                header(HttpHeaders.Accept, ContentType.Application.Json.toString())
                token?.let { header(HttpHeaders.Authorization, "Bearer $it") }
                if (body != null) {
                    contentType(ContentType.Application.Json)
                    setBody(json.encodeToString(JsonObject.serializer(), body))
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("ApiClient", "transport failure: $method ${baseUrl + path}", e)
            throw ApiException.Transport(e)
        }

        val text = response.bodyAsText()
        return when (response.status.value) {
            in 200..299 -> text
            401 -> throw ApiException.Unauthorized
            422 -> throw ApiException.Validation(validationErrors(text) ?: listOf("That didn't work."))
            else -> throw ApiException.Message(errorMessage(text) ?: "Request failed (HTTP ${response.status.value}).")
        }
    }

    /** Rails sends `{"error": "..."}` for single failures. */
    private fun errorMessage(text: String): String? =
        runCatching { (json.parseToJsonElement(text) as? JsonObject)?.get("error") }
            .getOrNull()
            .let { (it as? JsonPrimitive)?.content }

    /** ...and `{"errors": [...]}` for validation. */
    private fun validationErrors(text: String): List<String>? =
        runCatching {
            (json.parseToJsonElement(text) as? JsonObject)?.get("errors")
        }.getOrNull()
            ?.let { it as? kotlinx.serialization.json.JsonArray }
            ?.mapNotNull { (it as? JsonPrimitive)?.content }

    // endregion
}
