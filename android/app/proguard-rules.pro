# WorkManager's Room-backed WorkDatabase is built via reflection; without
# these keep rules R8 strips/renames generated _Impl classes it needs,
# causing a crash on startup: "Failed to create an instance of
# androidx.work.impl.WorkDatabase" (pulled in transitively by google_mobile_ads).
-keep class * extends androidx.room.RoomDatabase
-keep class androidx.work.impl.** { *; }
-keep class androidx.room.** { *; }
