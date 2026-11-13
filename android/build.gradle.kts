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
// flutter_pcm_sound 3.3.3 hard-codes compileSdk 33, but the androidx
// libraries it pulls in require 34+. Compile it against the app's SDK (36).
// Must be registered before evaluationDependsOn below evaluates the plugins.
subprojects {
    if (name == "flutter_pcm_sound") {
        afterEvaluate {
            extensions.getByName("android").withGroovyBuilder {
                "compileSdkVersion"(36)
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
