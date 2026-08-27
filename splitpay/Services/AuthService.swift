import Foundation
import FirebaseAuth

/// 匿名認証で自分専用ユーザーを作成/維持する。
/// Web版にはログイン機能自体が無いが、Firestoreのセキュリティルールで
/// 「認証済みユーザーのみ読み書き可」を掛けられるようにするための最小構成。
@MainActor
final class AuthService: ObservableObject {
    @Published var userId: String?
    @Published var isReady = false
    @Published var errorMessage: String?

    private var handle: AuthStateDidChangeListenerHandle?

    func start() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            if let user {
                self.userId = user.uid
                self.isReady = true
            } else {
                self.signInAnonymously()
            }
        }
    }

    private func signInAnonymously() {
        Auth.auth().signInAnonymously { [weak self] result, error in
            guard let self else { return }
            if let error {
                self.errorMessage = error.localizedDescription
                self.isReady = true
                return
            }
            self.userId = result?.user.uid
            self.isReady = true
        }
    }

    deinit {
        if let handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
