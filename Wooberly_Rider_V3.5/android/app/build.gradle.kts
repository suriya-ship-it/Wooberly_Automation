import java.util.Properties
import java.io.FileInputStream
import java.net.URI
import java.net.HttpURLConnection
import javax.xml.parsers.DocumentBuilderFactory
import org.w3c.dom.Element
import org.w3c.dom.Node

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}



androidComponents {
    // applicationVariants equivalent in new DSL
    onVariants { variant ->
        if (variant.buildType == "release") {
            variant.outputs.forEach { output ->
                if (output is com.android.build.api.variant.impl.BuiltArtifactsImpl) return@forEach
                val apkName = "${getValue("APP_NAME")}_${variant.name}.apk"
                output.outputFileName = apkName
            }
        }
    }
}

android {
    namespace = "com.radicalstart.wooberly"
    compileSdk = 37
    ndkVersion = "29.0.14033849"

    buildFeatures {
        resValues = true
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_24
        targetCompatibility = JavaVersion.VERSION_24
        isCoreLibraryDesugaringEnabled = true
    }

    sourceSets {
        getByName("main").java.srcDir("src/main/kotlin")
    }

    lint {
        checkReleaseBuilds = false
    }

val secureKey = "x6Qbs<0]`Ed{Y{}WoA{oBro**]2V"
    defaultConfig {
        applicationId  = "com.radicalstart.wooberly"
        minSdk = flutter.minSdkVersion
        targetSdk = 37
        versionCode = getValue("BUILD_VERSION").toInt()
        versionName = getValue("APP_VERSION")

        resValue("string", "api_security_key", secureKey)

        val domain = getValue("GRAPHQL_DOMAIN")
        val mapApiKey = fetchApiKeyFromGraphQL(domain, secureKey)
        manifestPlaceholders["PLACEHOLDER_API_KEY"] = mapApiKey

    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            val storeFileVal = keystoreProperties.getProperty("storeFile")
            storeFile = if (!storeFileVal.isNullOrEmpty()) file(storeFileVal) else null
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            setProguardFiles(listOf(file("proguard-rules.pro")))
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_24)
    }
}



flutter {
    source = "../.."
}


dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.14.0"))
    implementation("com.google.android.gms:play-services-location:21.3.0")
    implementation("com.google.android.gms:play-services-maps:19.2.0")
    implementation("androidx.credentials:credentials:1.3.0")
    implementation("androidx.credentials:credentials-play-services-auth:1.3.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

configurations.all {
    resolutionStrategy {
        force("androidx.datastore:datastore:1.1.7")
        force("androidx.datastore:datastore-preferences:1.1.7")
        force("androidx.datastore:datastore-core:1.1.7")
        force("androidx.datastore:datastore-core-android:1.1.7")
        force("androidx.datastore:datastore-preferences-core:1.1.7")
    }
}

fun getValue(name: String): String {
    val stringsFile = file("src/main/res/values/strings.xml")
    if (!stringsFile.exists()) {
        throw GradleException("strings.xml not found at ${stringsFile.absolutePath}")
    }
    val factory = DocumentBuilderFactory.newInstance()
    val builder = factory.newDocumentBuilder()
    val doc = builder.parse(stringsFile)
    doc.documentElement.normalize()
    val list = doc.getElementsByTagName("string")
    for (i in 0 until list.length) {
        val node = list.item(i)
        if (node.nodeType == Node.ELEMENT_NODE) {
            val element = node as Element
            if (element.getAttribute("name") == name) {
                return element.textContent
            }
        }
    }
    throw GradleException("Key '$name' not found in strings.xml")
}

fun extractApiKey(jsonString: String): String {
    val apiKeyIndex = jsonString.indexOf("\"riderAppAndroidMapApiKey\"")
    if (apiKeyIndex == -1) {
        throw GradleException("riderAppAndroidMapApiKey not found in GraphQL response: $jsonString")
    }
    val valueIndex = jsonString.indexOf("\"value\"", apiKeyIndex)
    if (valueIndex == -1) {
        throw GradleException("value field not found after riderAppAndroidMapApiKey in GraphQL response: $jsonString")
    }
    val firstQuote = jsonString.indexOf("\"", valueIndex + 7)
    if (firstQuote == -1) {
        throw GradleException("Opening quote for value field not found in GraphQL response")
    }
    val secondQuote = jsonString.indexOf("\"", firstQuote + 1)
    if (secondQuote == -1) {
        throw GradleException("Closing quote for value field not found in GraphQL response")
    }
    return jsonString.substring(firstQuote + 1, secondQuote)
}

fun fetchApiKeyFromGraphQL(domain: String, secureKey: String): String {
    val url = URI(domain).toURL()
    val conn = url.openConnection() as HttpURLConnection
    conn.requestMethod = "POST"
    conn.doOutput = true
    conn.setRequestProperty("Content-Type", "application/json; charset=UTF-8")

    val graphqlQuery = """
        {
            "query": "query getSecureSiteSettings(${'$'}type: String, ${'$'}securityKey: String!) {getSecureSiteSettings(settingsType: ${'$'}type, securityKey: ${'$'}securityKey) {results {name value}}}",
            "variables": {"securityKey": "$secureKey"}
        }
    """.trimIndent()

    conn.outputStream.use { os ->
        val input = graphqlQuery.toByteArray(Charsets.UTF_8)
        os.write(input, 0, input.size)
    }

    val responseBody = conn.inputStream.use { inputStream ->
        inputStream.bufferedReader(Charsets.UTF_8).readText()
    }
    return extractApiKey(responseBody)
}