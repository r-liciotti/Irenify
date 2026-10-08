package it.overside.irenefy

import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Riaperta dalle app recenti dopo la chiusura del processo, Android
        // riconsegna la condivisione originale e receive_sharing_intent la
        // tratterebbe come nuova, creando un job doppione. La sostituiamo con
        // un avvio normale prima che il plugin la legga.
        if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) {
            intent = Intent(Intent.ACTION_MAIN)
                .addCategory(Intent.CATEGORY_LAUNCHER)
                .setClass(this, MainActivity::class.java)
        }
        super.onCreate(savedInstanceState)
        publishShareShortcut()
        reportShare(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BUNDLED_ASSETS_CHANNEL)
            .setMethodCallHandler { call, result ->
                val asset = call.argument<String>("asset")
                if (asset == null) {
                    result.error("bad_args", "Manca l'asset", null)
                    return@setMethodCallHandler
                }
                when (call.method) {
                    "exists" -> result.success(assetExists(asset))
                    "copy" -> {
                        val destination = call.argument<String>("destination")
                        if (destination == null) {
                            result.error("bad_args", "Manca la destinazione", null)
                        } else {
                            copyAsset(asset, destination, result)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** Chiave dell'asset Flutter [asset] dentro l'APK (`flutter_assets/...`). */
    private fun assetKey(asset: String): String =
        FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(asset)

    private fun assetExists(asset: String): Boolean = try {
        assets.open(assetKey(asset)).close()
        true
    } catch (e: IOException) {
        false
    }

    /**
     * Copia l'asset [asset] in [destination] a flusso, con un buffer da 1 MB
     * e su un thread a parte (D-67: il modello Whisper è di 264 MB). Scrive in
     * `<destination>.part` e rinomina solo a copia finita; in caso di errore
     * il file parziale viene eliminato. Il risultato torna sul main thread.
     */
    private fun copyAsset(asset: String, destination: String, result: MethodChannel.Result) {
        val key = assetKey(asset)
        val appAssets = applicationContext.assets
        val main = Handler(Looper.getMainLooper())
        copyExecutor.execute {
            val target = File(destination)
            val partial = File("$destination.part")
            try {
                target.parentFile?.mkdirs()
                appAssets.open(key).use { input ->
                    partial.outputStream().use { output ->
                        val buffer = ByteArray(1024 * 1024)
                        while (true) {
                            val read = input.read(buffer)
                            if (read < 0) break
                            output.write(buffer, 0, read)
                        }
                        output.fd.sync()
                    }
                }
                if (target.exists() && !target.delete()) {
                    throw IOException("Impossibile sostituire $destination")
                }
                if (!partial.renameTo(target)) {
                    throw IOException("Impossibile rinominare ${partial.path}")
                }
                main.post { result.success(null) }
            } catch (e: Exception) {
                partial.delete()
                main.post { result.error("copy_failed", e.toString(), null) }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        reportShare(intent)
    }

    /** Pubblica "Importa ricetta" per la fila in alto del menu di condivisione. */
    private fun publishShareShortcut() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return
        val builder = ShortcutInfo.Builder(this, SHARE_SHORTCUT_ID)
            .setShortLabel(getString(R.string.share_shortcut_label))
            .setLongLabel(getString(R.string.share_shortcut_long_label))
            .setIcon(Icon.createWithResource(this, R.mipmap.ic_launcher))
            .setIntent(Intent(Intent.ACTION_MAIN, null, this, MainActivity::class.java))
            .setCategories(setOf(SHARE_CATEGORY))
            .setLongLived(true)
        // Niente setExcludedFromSurfaces(SURFACE_LAUNCHER): sul Pixel (Android
        // 17) una scorciatoia esclusa dal launcher non viene pubblicata affatto
        // (verificato il 2026-09-29). Effetto collaterale: tenendo premuta
        // l'icona dell'app compare "Importa ricetta", che apre l'app.
        getSystemService(ShortcutManager::class.java).pushDynamicShortcut(builder.build())
    }

    /** Android ordina le scorciatoie di condivisione in base all'uso. */
    private fun reportShare(intent: Intent?) {
        if (intent?.action != Intent.ACTION_SEND) return
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return
        getSystemService(ShortcutManager::class.java).reportShortcutUsed(SHARE_SHORTCUT_ID)
    }

    private companion object {
        const val SHARE_SHORTCUT_ID = "importa-ricetta"
        const val SHARE_CATEGORY = "it.overside.irenefy.category.IMPORT_RECIPE"
        const val BUNDLED_ASSETS_CHANNEL = "it.overside.irenefy/bundled_assets"

        /** Una copia alla volta, fuori dal main thread. */
        val copyExecutor = Executors.newSingleThreadExecutor()
    }
}
