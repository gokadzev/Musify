// MIT License - Copyright (c) 2026 Simple Badminton Contributors
// Direct run: ./gradlew assembleRelease --no-daemon --init-script no-build-id.gradle
// Verification of '.note.gnu.build-id' removal: readelf --wide --notes libdartjni.so

def home = System.getenv("ANDROID_HOME") ?: ""
println "[no-build-id] ANDROID_HOME environment variable value: ${home}"
def objcopy = null
if (home) {
    def ndkRoot = new File("${home}/ndk")
    if (ndkRoot.isDirectory()) {
        ndkRoot.eachDir { ver ->
            if (objcopy) return
            println "[no-build-id] first path to check for llvm-objcopy: ${ver}/toolchains/llvm/prebuilt"
            def prebuilt = new File("${ver}/toolchains/llvm/prebuilt")
            if (!prebuilt.isDirectory()) return
            prebuilt.eachDir { platform ->
                if (objcopy) return
                println "[no-build-id] second path to check for llvm-objcopy: ${platform}/bin/llvm-objcopy"
                def c = new File("${platform}/bin/llvm-objcopy")
                if (c.exists()) objcopy = c.absolutePath
            }
        }
    }
}
if (!objcopy) {
    println "[no-build-id] llvm-objcopy not found - Build ID strip skipped"
    return
}
final String oc = objcopy
tasks.matching { it.name.startsWith("merge") && it.name.endsWith("NativeLibs") }
    .configureEach { t ->
        t.doLast {
            t.outputs.files.each { dir ->
                if (!(dir instanceof File) || !dir.isDirectory()) return
                dir.eachFileRecurse { f ->
                    if (!f.name.endsWith('.so')) return
                    exec { commandLine oc, '--remove-section', '.note.gnu.build-id', f.absolutePath }
                    println "[no-build-id] stripped Build ID: ${f.name}"
                }
            }
        }
    }
