package it.overside.irenefy

import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

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
    }
}
