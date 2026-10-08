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
// receive_sharing_intent 1.8.1 non dichiara il target JVM: Java resta a 1.8
// mentre Kotlin eredita 21 dalla JDK di Android Studio. Allineiamo entrambi a 17.
// (La 1.9.0 risolve, ma richiede Android Gradle Plugin 9, non ancora nel template Flutter.)
subprojects {
    if (name == "receive_sharing_intent") {
        plugins.withId("com.android.library") {
            extensions.configure<com.android.build.gradle.LibraryExtension> {
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}
// whisper_ggml (packages/whisper_ggml) compila da sé, solo per arm64-v8a, tre varianti di
// libwhisper (base, dotprod, i8mm) e l'app sceglie all'avvio quella adatta alla CPU (D-65):
// qui non serve più nessuna impostazione per il plugin.
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
