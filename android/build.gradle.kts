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
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Force a consistent JVM target (17) across all plugin modules. Some older
// plugins (e.g. flutter_timezone) default Java to 11 and Kotlin to 1.8, which
// fails the "Inconsistent JVM-target" check under the current Gradle toolchain.
subprojects {
    // Kotlin tasks: configureEach is lazy and safe to register at any time.
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>()
        .configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    // Java compileOptions on the android extension can only be changed before
    // the project is evaluated. :app is force-evaluated early (and already
    // targets 17), so only touch not-yet-evaluated plugin modules.
    if (!state.executed) {
        afterEvaluate {
            (extensions.findByName("android")
                    as? com.android.build.gradle.BaseExtension)
                ?.compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
