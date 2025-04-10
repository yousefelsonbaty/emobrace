# Keep the main entry points
-keep public class * extends android.app.Application
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# Keep annotations
-keep @interface *

# Firebase-related rules
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Prevent R8 from removing resource IDs
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Keep Retrofit models
-keep class com.example.emobrace_app.models.** { *; }

# Keep all classes used in serialized objects
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object readResolve();
}
