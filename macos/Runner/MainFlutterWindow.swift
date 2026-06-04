import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    // Matches native splash / app icon background (#091020).
    self.backgroundColor = NSColor(
      red: 9.0 / 255.0,
      green: 16.0 / 255.0,
      blue: 32.0 / 255.0,
      alpha: 1.0
    )
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
