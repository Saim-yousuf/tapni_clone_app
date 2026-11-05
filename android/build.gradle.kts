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

// stripe_android pulls compileOnly stripe-android-issuing-push-provisioning, which
// depends on Google's private play-services-tapandpay (not on public Maven).
// lintVital is the only release task that resolves that classpath; skip it here.
// Push provisioning is unused — PaymentSheet / normal Stripe flows are unaffected.
subprojects {
    if (name == "stripe_android") {
        tasks.configureEach {
            if (name.startsWith("lintVital")) {
                enabled = false
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
