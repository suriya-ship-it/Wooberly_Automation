allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.layout.buildDirectory.set(file("../build"))
subprojects {
    project.layout.buildDirectory.set(file("${rootProject.layout.buildDirectory.get().asFile.path}/${project.name}"))
}

subprojects {
    evaluationDependsOn(":app")
}

subprojects {
    project.configurations.all {
        resolutionStrategy {
            force("androidx.datastore:datastore:1.1.7")
            force("androidx.datastore:datastore-preferences:1.1.7")
            force("androidx.datastore:datastore-core:1.1.7")
            force("androidx.datastore:datastore-core-android:1.1.7")
            force("androidx.datastore:datastore-preferences-core:1.1.7")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
