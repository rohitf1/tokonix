import XCTest
@testable import Tokonix

final class ConfigurationTests: XCTestCase {
    func testDefaultTokonixHomeUsesMainTokonix() {
        let previous = getenv("TOKONIX_VOICE_OVERLAY_HOME")
        let previousTokonixHome = getenv("TOKONIX_HOME")
        unsetenv("TOKONIX_VOICE_OVERLAY_HOME")
        unsetenv("TOKONIX_HOME")
        defer {
            if let previous {
                setenv("TOKONIX_VOICE_OVERLAY_HOME", previous, 1)
            }
            if let previousTokonixHome {
                setenv("TOKONIX_HOME", previousTokonixHome, 1)
            }
        }

        let config = TokonixAppServerClient.Configuration.loadFromEnvironment()
        let expected = (NSHomeDirectory() as NSString).appendingPathComponent(".tokonix")
        XCTAssertEqual(config.tokonixHome?.path, expected)
    }

    func testTokonixHomeFallsBackToTokonixHomeEnv() {
        let previous = getenv("TOKONIX_VOICE_OVERLAY_HOME")
        let previousTokonixHome = getenv("TOKONIX_HOME")
        unsetenv("TOKONIX_VOICE_OVERLAY_HOME")
        setenv("TOKONIX_HOME", "/tmp/tokonix-main-test", 1)
        defer {
            if let previous {
                setenv("TOKONIX_VOICE_OVERLAY_HOME", previous, 1)
            } else {
                unsetenv("TOKONIX_VOICE_OVERLAY_HOME")
            }
            if let previousTokonixHome {
                setenv("TOKONIX_HOME", previousTokonixHome, 1)
            } else {
                unsetenv("TOKONIX_HOME")
            }
        }

        let config = TokonixAppServerClient.Configuration.loadFromEnvironment()
        XCTAssertEqual(config.tokonixHome?.path, "/tmp/tokonix-main-test")
    }

    func testTokonixHomeOverrideRespected() {
        let previous = getenv("TOKONIX_VOICE_OVERLAY_HOME")
        let previousTokonixHome = getenv("TOKONIX_HOME")
        setenv("TOKONIX_VOICE_OVERLAY_HOME", "/tmp/tokonix-voice-test", 1)
        defer {
            if let previous {
                setenv("TOKONIX_VOICE_OVERLAY_HOME", previous, 1)
            } else {
                unsetenv("TOKONIX_VOICE_OVERLAY_HOME")
            }
            if let previousTokonixHome {
                setenv("TOKONIX_HOME", previousTokonixHome, 1)
            } else {
                unsetenv("TOKONIX_HOME")
            }
        }

        let config = TokonixAppServerClient.Configuration.loadFromEnvironment()
        XCTAssertEqual(config.tokonixHome?.path, "/tmp/tokonix-voice-test")
    }

    func testOverlayLayoutDefaults() {
        XCTAssertEqual(OverlayLayout.windowWidth, 620)
        XCTAssertEqual(OverlayLayout.windowHeight, 620)
        XCTAssertEqual(OverlayLayout.orbSize, 212)
        XCTAssertEqual(OverlayLayout.orbFieldSize, 400)
    }
}
