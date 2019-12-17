//
//  GameViewController.swift
//  SoSpace
//
//  Created by LeverX on 12/16/19.
//

import UIKit
import SpriteKit

class MenuViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        if let view = self.view as! SKView? {
            view
        }
    }

    @IBAction func playGame(_ sender: UIButton) {
        let gameViewController = GameViewController()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window!.rootViewController!.present(gameViewController, animated: true, completion: nil)
    }
    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
