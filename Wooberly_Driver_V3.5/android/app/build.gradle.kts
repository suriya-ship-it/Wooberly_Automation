import java.util.Properties
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
    id("com.apollographql.apollo")
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

fun getValue(name: String): String {
    val stringsFile = project.file("src/main/res/values/strings.xml")
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
    val apiKeyIndex = jsonString.indexOf("\"driverAppAndroidMapApiKey\"")
    if (apiKeyIndex == -1) {
        throw GradleException("driverAppAndroidMapApiKey not found in GraphQL response: $jsonString")
    }
    val valueIndex = jsonString.indexOf("\"value\"", apiKeyIndex)
    if (valueIndex == -1) {
        throw GradleException("value field not found after driverAppAndroidMapApiKey in GraphQL response: $jsonString")
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
    val localKey = localProperties.getProperty("maps.apiKey")
        ?: keystoreProperties.getProperty("maps.apiKey")
    if (!localKey.isNullOrEmpty()) {
        return localKey
    }

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

android {
    namespace = "com.radicalstart.wooberlydriver"
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

    sourceSets.configureEach {
        if (name == "main") {
            java.srcDir("src/main/kotlin")
        }
    }

    apollo {
        service("service") {
            packageName.set("com.radicalstart.wooberlydriver")
        }
    }

    defaultConfig {
        ndk {
            abiFilters.addAll(setOf("arm64-v8a", "armeabi-v7a"))
        }

        val secureKey = "x6Qbs<0]`Ed{Y{}WoA{oBro**]2V"
        val graphQLURL = getValue("GRAPHQL_DOMAIN")
        val socketURL = getValue("SOCKET_URL")

        applicationId = "com.radicalstart.wooberlydriver"
        minSdk = 25
        targetSdk = 37
        versionCode = getValue("BUILD_VERSION").toInt()
        versionName = getValue("APP_VERSION")

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        resValue("string", "graphql_url", graphQLURL)
        resValue("string", "socket_url", socketURL)
        resValue("string", "api_security_key", secureKey)

        val apiKey = fetchApiKeyFromGraphQL(graphQLURL, secureKey)
        manifestPlaceholders["PLACEHOLDER_API_KEY"] = apiKey
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { project.file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.work:work-runtime-ktx:2.7.1")
    testImplementation("junit:junit:4.12")
    implementation("com.google.android.gms:play-services-location:21.3.0")
    implementation("com.google.android.gms:play-services-maps:19.0.0")
    implementation("com.apollographql.apollo:apollo-runtime:4.1.1")
    val lifecycleVersion = "2.2.0"
    implementation("com.github.nkzawa:socket.io-client:0.6.0")
    implementation("androidx.core:core-splashscreen:1.2.0-rc01")
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:$lifecycleVersion")
    implementation("androidx.lifecycle:lifecycle-livedata-ktx:$lifecycleVersion")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:$lifecycleVersion")
    implementation("androidx.lifecycle:lifecycle-extensions:2.0.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel:2.0.0")
    implementation("com.google.code.gson:gson:2.8.6")
    implementation("com.google.android.gms:play-services-auth:18.1.0")
    implementation("androidx.annotation:annotation:1.0.0")
    implementation("com.google.guava:guava:27.0.1-android")
    // AndroidX Credentials – Zero-Tap Sign-In / Restore Credentials API (Google Play requirement Apr 2027)
    implementation("androidx.credentials:credentials:1.5.0")
    implementation("androidx.credentials:credentials-play-services-auth:1.5.0")
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

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_24)
    }
}