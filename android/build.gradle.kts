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
        // Match Kotlin's jvmTarget to whatever the plugin's Java compile is using
        // (most plugins like flutter_timezone hardcode Java 11). We can't easily
        // change their Java target from here, but lowering Kotlin to 11 makes
        // each plugin module self-consistent.
        //
        // EXCEPT for our own :app, which stays on Java 17 + Kotlin 17. Skipping
        // it here lets app/build.gradle.kts's own JVM_17 setting take effect.
        if (project.name != "app") {
            plugins.withId("org.jetbrains.kotlin.android") {
                tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                    compilerOptions {
                        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
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
