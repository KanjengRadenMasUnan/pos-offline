allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Tambahkan blok ini untuk memaksa SEMUA plugin
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            android?.apply {
                // Baris kunci: Memaksa versi meskipun plugin minta 25.0.2
                buildToolsVersion = "36.0.0"
                compileSdkVersion(36)
            }
        }
    }
    
    // Memaksa konfigurasi agar tidak mencari Build Tools lama di level dependensi
    configurations.all {
        resolutionStrategy {
            eachDependency {
                if (requested.group == "com.android.tools.build" && requested.name == "gradle") {
                    useVersion("8.7.0") // Pastikan versi gradle sinkron
                }
            }
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}