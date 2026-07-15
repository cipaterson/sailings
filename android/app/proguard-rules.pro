# kotlinx.serialization keeps generated serializers; keep them for the model classes.
-keepclassmembers class org.sailings.app.** {
    *** Companion;
}
-keepclasseswithmembers class org.sailings.app.** {
    kotlinx.serialization.KSerializer serializer(...);
}
