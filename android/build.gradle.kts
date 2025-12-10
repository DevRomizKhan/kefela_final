allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val localProperties = java.util.Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

val flutterCompileSdkVersion = 36
extra["flutter.compileSdkVersion"] = flutterCompileSdkVersion
val flutterTargetSdkVersion = 36
extra["flutter.targetSdkVersion"] = flutterTargetSdkVersion
val flutterMinSdkVersion = 21 // Default or from local.properties if needed, but hardcoding for safety
extra["flutter.minSdkVersion"] = flutterMinSdkVersion

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Force compile option for all plugins
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android")
            if (android is com.android.build.gradle.BaseExtension) {
                android.compileSdkVersion(36)
                android.defaultConfig {
                     targetSdk = 36
                }
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
