import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    (UIApplication.shared.delegate as? AppDelegate)?.menuCommands.setScene(scene, active: true)
  }

  override func sceneWillResignActive(_ scene: UIScene) {
    (UIApplication.shared.delegate as? AppDelegate)?.menuCommands.setScene(scene, active: false)
    super.sceneWillResignActive(scene)
  }

  override func sceneDidDisconnect(_ scene: UIScene) {
    (UIApplication.shared.delegate as? AppDelegate)?.menuCommands.setScene(scene, active: false)
    super.sceneDidDisconnect(scene)
  }
}
