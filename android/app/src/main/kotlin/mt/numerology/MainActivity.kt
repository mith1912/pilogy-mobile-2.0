package mt.numerology

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private var exportResult: MethodChannel.Result? = null
    private var exportJson: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mt.numerology/export")
            .setMethodCallHandler { call, result ->
                if (call.method != "exportProfiles") {
                    result.notImplemented()
                } else if (exportResult != null) {
                    result.error("BUSY", "Export already in progress", null)
                } else {
                    val json = call.argument<String>("json")
                    if (json == null) {
                        result.error("INVALID", "Export unavailable", null)
                    } else {
                        exportJson = json
                        exportResult = result
                        try {
                            val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                type = "application/json"
                                putExtra(Intent.EXTRA_TITLE, "pilogy-profiles.json")
                            }
                            startActivityForResult(intent, 804)
                        } catch (_: Exception) {
                            exportJson = null
                            exportResult = null
                            result.error("UNAVAILABLE", "Export unavailable", null)
                        }
                    }
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 804) return
        val result = exportResult ?: return
        val json = exportJson
        exportResult = null
        exportJson = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null || json == null) {
            result.success(false)
            return
        }
        try {
            val stream = contentResolver.openOutputStream(uri, "wt")
                ?: throw IllegalStateException()
            stream.use { it.write(json.toByteArray(Charsets.UTF_8)) }
            result.success(true)
        } catch (_: Exception) {
            result.error("UNAVAILABLE", "Export unavailable", null)
        }
    }

    override fun onDestroy() {
        exportJson = null
        exportResult?.error("CANCELLED", "Export cancelled", null)
        exportResult = null
        super.onDestroy()
    }
}
