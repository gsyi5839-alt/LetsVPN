import Cocoa
import FlutterMacOS
import desktop_multi_window
import shared_preferences_foundation
import url_launcher_macos
import window_manager
import LaunchAtLogin

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)


 // Add FlutterMethodChannel platform code
    FlutterMethodChannel(
      name: "launch_at_startup", binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    .setMethodCallHandler { (_ call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "launchAtStartupIsEnabled":
        result(LaunchAtLogin.isEnabled)
      case "launchAtStartupSetEnabled":
        if let arguments = call.arguments as? [String: Any] {
          LaunchAtLogin.isEnabled = arguments["setEnabledValue"] as! Bool
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    //
    RegisterGeneratedPlugins(registry: flutterViewController)

    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
      SharedPreferencesPlugin.register(with: controller.registrar(forPlugin: "SharedPreferencesPlugin"))
      WindowManagerPlugin.register(with: controller.registrar(forPlugin: "WindowManagerPlugin"))
      UrlLauncherPlugin.register(with: controller.registrar(forPlugin: "UrlLauncherPlugin"))

      DispatchQueue.main.async {
        self.configureDesktopSubWindowStyle(for: controller)
      }
    }

    super.awakeFromNib()
  }

  private func configureDesktopSubWindowStyle(for controller: FlutterViewController) {
    guard let subWindow = controller.view.window else {
      return
    }

    // Keep only one native macOS traffic-light button group.
    subWindow.styleMask.remove(.fullSizeContentView)
    subWindow.titlebarAppearsTransparent = false
    subWindow.titleVisibility = .hidden
  }

  // window manager hidden at launch
  override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
    super.order(place, relativeTo: otherWin)
    hiddenWindowAtLaunch()
  }
}
