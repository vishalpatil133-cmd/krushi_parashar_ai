# Start.io (StartApp) SDK Proguard Rules
-keep class com.startapp.** {*;}
-keepattributes Exceptions, InnerClasses, Signature, Deprecated, SourceFile, LineNumberTable, *Annotation*, EnclosingMethod
-dontwarn android.webkit.JavascriptInterface
