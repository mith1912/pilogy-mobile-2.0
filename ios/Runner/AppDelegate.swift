import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var exportActive = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "mt.numerology/export", binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { [weak self, weak controller] call, result in
        guard call.method == "exportProfiles" else { result(FlutterMethodNotImplemented); return }
        guard let owner = self, let presenter = controller, !owner.exportActive,
              let args = call.arguments as? [String: Any], let json = args["json"] as? String else {
          result(FlutterError(code: "UNAVAILABLE", message: "Export unavailable", details: nil)); return
        }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let url = directory.appendingPathComponent("pilogy-profiles.json")
        do {
          try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
          try json.write(to: url, atomically: true, encoding: .utf8)
          try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: url.path)
          owner.exportActive = true
          let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
          sheet.popoverPresentationController?.sourceView = presenter.view
          sheet.popoverPresentationController?.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 1, height: 1)
          sheet.completionWithItemsHandler = { _, completed, _, _ in
            try? FileManager.default.removeItem(at: directory)
            owner.exportActive = false
            result(completed)
          }
          presenter.present(sheet, animated: true)
        } catch {
          try? FileManager.default.removeItem(at: directory)
          result(FlutterError(code: "UNAVAILABLE", message: "Export unavailable", details: nil))
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
