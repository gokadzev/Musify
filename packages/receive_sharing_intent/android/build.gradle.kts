group = "com.kasem.receive_sharing_intent"
version = "1.4.5"

plugins {
    id("com.android.library")
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

android {
    namespace = "com.kasem.receive_sharing_intent"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        minSdk = 23
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}