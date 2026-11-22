import Flutter
import Security
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = registrar(forPlugin: "OnharuAuthSession") {
      let channel = FlutterMethodChannel(
        name: "com.onharu.app/auth_session", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler(handleAuthSession)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleAuthSession(_ call: FlutterMethodCall, result: FlutterResult) {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: "com.onharu.app.auth_session",
      kSecAttrAccount as String: "session"
    ]

    switch call.method {
    case "read":
      var request = query
      request[kSecReturnData as String] = true
      request[kSecMatchLimit as String] = kSecMatchLimitOne
      var stored: CFTypeRef?
      let status = SecItemCopyMatching(request as CFDictionary, &stored)
      if status == errSecItemNotFound {
        result(nil)
      } else if status == errSecSuccess, let data = stored as? Data,
                let session = String(data: data, encoding: .utf8) {
        result(session)
      } else {
        result(authStorageError(status))
      }
    case "write":
      guard let session = call.arguments as? String else {
        result(authStorageError(errSecParam))
        return
      }
      let attributes = [kSecValueData as String: Data(session.utf8)]
      var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
      if status == errSecItemNotFound {
        var entry = query
        entry[kSecValueData as String] = Data(session.utf8)
        entry[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        status = SecItemAdd(entry as CFDictionary, nil)
      }
      result(status == errSecSuccess ? nil : authStorageError(status))
    case "delete":
      let status = SecItemDelete(query as CFDictionary)
      result(status == errSecSuccess || status == errSecItemNotFound ? nil : authStorageError(status))
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func authStorageError(_ status: OSStatus) -> FlutterError {
    FlutterError(code: "AUTH_STORAGE", message: "로그인 저장소를 사용할 수 없습니다.", details: status)
  }
}
