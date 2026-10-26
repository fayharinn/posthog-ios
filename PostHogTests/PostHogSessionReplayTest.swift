#if os(iOS)
    @testable import PostHog
    import Testing
    import UIKit

    @Suite("Session Replay tests", .serialized)
    class PostHogSessionReplayTests {
        let testAPIKey = "test_api_key"
        let server: MockPostHogServer

        init() {
            server = MockPostHogServer()
            server.start()
        }

        deinit {
            server.stop()
        }

        private func getSut(
            sessionReplay: Bool
        ) -> PostHogSDK {
            let config = PostHogConfig(apiKey: testAPIKey, host: "http://localhost:9001")
            config.sessionReplay = sessionReplay
            config.disableReachabilityForTesting = true
            config.disableQueueTimerForTesting = true
            return PostHogSDK.with(config)
        }

        @Test("Session replay can be manually started when disabled in config")
        func manualSessionReplayStart() async throws {
            // Setup SDK with session replay disabled
            let sut = getSut(sessionReplay: false)

            // Initially session replay should be inactive
            #expect(sut.getReplayIntegration() == nil)

            // Manually start session replay
            sut.startSessionRecording()

            // Session replay should now be active
            #expect(sut.getReplayIntegration() != nil)

            sut.reset()
        }

        @Test("Session replay can be toggled multiple times")
        func sessionReplayToggle() async throws {
            // Setup SDK with session replay disabled
            let sut = getSut(sessionReplay: false)

            // Initially session replay should be inactive
            #expect(sut.getReplayIntegration() == nil)

            // Start session replay
            sut.startSessionRecording()
            #expect(sut.getReplayIntegration() != nil)

            // Stop session replay
            sut.stopSessionRecording()
            sut.optOut()

            #expect(sut.getReplayIntegration() == nil)

            // Start again
            sut.optIn()
            sut.startSessionRecording()
            #expect(sut.getReplayIntegration() != nil)

            sut.reset()
        }
    }

    @Suite("Replay camera exclusion", .serialized)
    @MainActor
    struct PostHogReplayCameraTests {
        // Exercise controller containment without starting a camera capture session.
        private final class CameraPicker: UIImagePickerController {
            override var sourceType: UIImagePickerController.SourceType {
                get { .camera }
                set {}
            }

            override func loadView() {
                view = UIView()
            }
        }

        private func window(root: UIViewController) -> UIWindow {
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
            window.rootViewController = root
            window.makeKeyAndVisible()
            root.view.frame = window.bounds
            return window
        }

        @Test("A camera picker at the root blocks capture")
        func rootCamera() {
            let window = window(root: CameraPicker())
            defer { window.isHidden = true }
            #expect(window.hasCameraForReplay())
        }

        @Test("A nested camera blocks capture until removed, without affecting another window")
        func containedCameraAndRemoval() {
            let root = UIViewController()
            let picker = CameraPicker()
            root.addChild(picker)
            let window = window(root: root)
            defer { window.isHidden = true }
            // A retained, offscreen controller does not put camera layers in the window.
            #expect(!window.hasCameraForReplay())
            root.view.addSubview(picker.view)
            picker.didMove(toParent: root)
            #expect(window.hasCameraForReplay())
            let other = self.window(root: UIViewController())
            defer { other.isHidden = true }
            #expect(!other.hasCameraForReplay())
            picker.willMove(toParent: nil)
            picker.view.removeFromSuperview()
            picker.removeFromParent()
            #expect(!window.hasCameraForReplay())
        }

        @Test("Photo-library pickers do not block capture")
        func photoLibraryIsNotCamera() {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            let window = window(root: picker)
            defer { window.isHidden = true }
            #expect(!window.hasCameraForReplay())
        }
    }
#endif
