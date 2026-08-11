# SQLCipher is loaded through its Flutter plugin and JNI entry points.
-keep class net.zetetic.database.sqlcipher.** { *; }
-keep class net.zetetic.database.** { *; }
-dontwarn net.zetetic.database.sqlcipher.**
