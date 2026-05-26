allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Force every Kotlin and Java compile task in plugin subprojects to JVM 17,
    // since some plugins (e.g. flutter_timezone) still default Kotlin to 1.8
    // which mismatches their own Java target (11) and fails the build.
    //
    // Must be registered BEFORE `evaluationDependsOn(":app")` below, otherwise
    // by the time we get here the subproject has already been evaluated and
    // afterEvaluate registration is too late.
    afterEvaluate {
        // Force every plugin subproject to use JVM 17 for both Java AND Kotlin.
        // Plugins ship with inconsistent defaults (flutter_timezone uses Java 11,
        // flutter_compass_v2 uses Java 17, etc.) and Kotlin defaults vary too.
        // Pinning both to 17 makes each module self-consistent.
        //
        // Skip :app — it has its own JVM 17 config in app/build.gradle.kts.
        if (project.name != "app") {
            plugins.withId("com.android.library") {
                extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.apply {
                    // Match :app's compileSdk so transitive dependencies that
                    // require API 34+ (e.g. androidx.fragment 1.7.x) don't fail
                    // AAR metadata checks against plugins still on android-33.
                    compileSdk = 36
                    compileOptions {
                        sourceCompatibility = JavaVersion.VERSION_17
                        targetCompatibility = JavaVersion.VERSION_17
                    }
                }
            }
            plugins.withId("org.jetbrains.kotlin.android") {
                tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                    compilerOptions {
                        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
                    }
                }
            }
        }
    }

    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
