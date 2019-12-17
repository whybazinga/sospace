//
//  MenuScene.swift
//  SoSpace
//

import SpriteKit

class MenuScene: SKScene {

    override func didMove(to view: SKView) {
        insertBackground()
        
        let gameTitleLabel = SKLabelNode(text: "sospace")
        gameTitleLabel.fontSize = 50
        gameTitleLabel.zPosition = 1
        gameTitleLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        
        let hintLabel = SKLabelNode(text: "tap to play")
        hintLabel.fontSize = 20
        hintLabel.position = CGPoint(x: gameTitleLabel.position.x, y: gameTitleLabel.position.y - 30)
        
        addChild(gameTitleLabel)
        addChild(hintLabel)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let gameScene = SKScene(fileNamed: "GameScene") {
            // Set the scale mode to scale to fit the window
            gameScene.scaleMode = .aspectFill
            
            // Present the scene
            view?.presentScene(gameScene, transition: SKTransition.reveal(with: .down, duration: 1))
        }
    }
    
    func insertBackground() {
        let gradient = CAGradientLayer()
        
        gradient.colors = [UIColor.black.cgColor, UIColor.darkGray.cgColor]
        gradient.locations = [0.0, 2.0]
        gradient.startPoint = CGPoint(x: 0.5, y: 1)
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        
        gradient.frame = self.frame
//        self.view!.layer.addSublayer(gradient)
    }
}
