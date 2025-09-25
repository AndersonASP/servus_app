import Flutter
import UIKit
import GoogleSignIn

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Configuração robusta do Google Sign-In
    configureGoogleSignIn()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func configureGoogleSignIn() {
    guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
          let plist = NSDictionary(contentsOfFile: path),
          let clientId = plist["CLIENT_ID"] as? String else {
      print("❌ GoogleService-Info.plist não encontrado ou CLIENT_ID inválido")
      print("❌ Verifique se o arquivo existe e tem as chaves necessárias")
      return
    }
    
    print("✅ Configurando Google Sign-In com Client ID: \(clientId)")
    GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
  }
  
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    print("🔗 URL recebida: \(url)")
    return GIDSignIn.sharedInstance.handle(url)
  }
}