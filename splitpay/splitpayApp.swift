import SwiftUI
import FirebaseCore

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct SplitpayApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authService = AuthService()
    @StateObject private var store = FirestoreStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(store)
                .onAppear {
                    authService.start()
                    // 匿名認証が完了する前にFirestoreの購読を始めると、
                    // 認証必須のセキュリティルールを適用した際にpermission-deniedになりうるため、
                    // authService.isReady が true になるのを待ってから store.start() を呼ぶ。
                    if authService.isReady {
                        store.start()
                    }
                }
                .onChange(of: authService.isReady) { _, isReady in
                    if isReady {
                        store.start()
                    }
                }
        }
    }
}
