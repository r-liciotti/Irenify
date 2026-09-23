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
// whisper_ggml compila whisper.cpp per ARMv8.0 base, senza fp16/dotprod/i8mm, per non andare
// in crash (SIGILL) sui telefoni più vecchi. Il Pixel 9 Pro (Tensor G4) ha tutte e tre le estensioni,
// che sono quelle usate da ggml per accelerare i prodotti tra matrici, soprattutto con i modelli
// quantizzati. Le abilitiamo solo su arm64-v8a (gli altri ABI del plugin vengono esclusi: niente
// libwhisper per emulatori x86 e telefoni a 32 bit). Da rivedere prima di distribuire l'app.
subprojects {
    if (name == "whisper_ggml") {
        plugins.withId("com.android.library") {
            extensions.configure<com.android.build.api.variant.LibraryAndroidComponentsExtension> {
                finalizeDsl { android ->
                    val armFlags = "-march=armv8.2-a+fp16+dotprod+i8mm"
                    android.defaultConfig.ndk.abiFilters.retainAll(setOf("arm64-v8a"))
                    android.defaultConfig.externalNativeBuild.cmake.cFlags.add(armFlags)
                    android.defaultConfig.externalNativeBuild.cmake.cppFlags.add(armFlags)
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
