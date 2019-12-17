//
//  GameScene.swift
//  SoSpace
//

import CoreMotion
import SpriteKit

enum CollisionType:UInt32 {
    case player = 1
    case playerWeapon = 2
    case enemy = 4
    case enemyWeapon = 8
}

let DEFAULT_OBJECTS_MARGIN:CGFloat = 40
let ENEMY_POSITIONS_AMOUNT:CGFloat = 9
let ENEMY_OFFSET_X:CGFloat = 100
let ENEMY_START_X:CGFloat  = 1000
let ENEMY_FIRE_RATE:CGFloat = 0.2
let ACCELEROMETER_MOTION_DATA_MULTIPLIER:CGFloat = 50

class GameScene: SKScene, SKPhysicsContactDelegate {
    let motionManager = CMMotionManager()
    let player = SKSpriteNode(imageNamed: "player")
    var isPlayerAlive = true
    
    let waves = Bundle.main.decode([Wave].self, from: "waves.json")
    let enemyTypes = Bundle.main.decode([EnemyType].self, from: "enemy-types.json")
    
    var levelNumber = 0
    var waveNumber = 0
    var playerShields = 10
    
    var positions:[CGFloat]?
    
    
    override func didMove(to view: SKView) {
        positions = Array(stride(
            from: DEFAULT_OBJECTS_MARGIN - self.size.height / 2,
            through: self.size.height / 2 - DEFAULT_OBJECTS_MARGIN,
            by: (self.size.height - DEFAULT_OBJECTS_MARGIN) / ENEMY_POSITIONS_AMOUNT
        ))
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        if let starfieldParticles = SKEmitterNode(fileNamed: "Starfield") {
            starfieldParticles.position = CGPoint(x: self.size.width + DEFAULT_OBJECTS_MARGIN, y: 0)
            starfieldParticles.advanceSimulationTime(60)
            addChild(starfieldParticles)
        }
        
        player.name = "player"
        player.position.x = frame.minX + player.size.width + DEFAULT_OBJECTS_MARGIN
        player.zPosition = 1
        addChild(player)
        
        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.texture!.size())
        player.physicsBody?.categoryBitMask = CollisionType.player.rawValue
        player.physicsBody?.collisionBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        player.physicsBody?.contactTestBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        player.physicsBody?.isDynamic = false
        
        motionManager.startAccelerometerUpdates()
    }
    
    override func update(_ currentTime: TimeInterval) {
        if let accelerometerData = motionManager.accelerometerData {
            player.position.y += CGFloat(CGFloat(accelerometerData.acceleration.x) * ACCELEROMETER_MOTION_DATA_MULTIPLIER)
            
            if player.position.y < frame.minY {
                player.position.y = frame.minY
            } else if player.position.y > frame.maxY {
                player.position.y = frame.maxY
            }
        }
        removeChildrenBehindScene()
        
        let activeEnemies = children.compactMap { $0 as? EnemyNode }
        
        if activeEnemies.isEmpty {
            spawnWave()
        }
        
        for enemy in activeEnemies {
            handleFire(of: enemy, at: currentTime)
        }
    }
    
    func removeChildrenBehindScene() {
        for child in children {
            if child.frame.maxX < 0 {
                if !frame.intersects(child.frame) {
                    child.removeFromParent()
                }
            }
        }
    }
    
    func handleFire(of enemy:EnemyNode, at time:TimeInterval){
        guard frame.intersects(enemy.frame) else { return }
        
        if enemy.lastFireTime + 1 < time {
            enemy.lastFireTime = time
            
            if CGFloat.random(in: 0...1) > ENEMY_FIRE_RATE {
                enemy.fire()
            }
        }
    }
    
    func spawnWave() {
        guard isPlayerAlive else { return }
        
        if waveNumber == waves.count {
            levelNumber += 1
            waveNumber = 0
        }
        
        let currentWave = waves[waveNumber]
        waveNumber += 1
        
        let highestEnemyType = min(enemyTypes.count, levelNumber + 1)
        let enemyType = Int.random(in: 0..<highestEnemyType)
        
        if currentWave.enemies.isEmpty {
            for (index, position) in positions!.shuffled().enumerated() {
                let enemyNode = EnemyNode(
                    type: enemyTypes[enemyType],
                    startPosition: CGPoint(x: ENEMY_START_X, y: position),
                    xOffset: ENEMY_OFFSET_X * CGFloat(index * 3),
                    moveStraight: true
                )
                
                addChild(enemyNode)
            }
        } else {
            for enemy in currentWave.enemies {
                let enemyNode = EnemyNode(
                    type: enemyTypes[enemyType],
                    startPosition: CGPoint(x: ENEMY_START_X, y: positions![enemy.position]),
                    xOffset: ENEMY_OFFSET_X * enemy.xOffset,
                    moveStraight: enemy.moveStraight
                )
                
                addChild(enemyNode)
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isPlayerAlive else {
            let menuScene = MenuScene(size: view!.bounds.size)
            view?.presentScene(menuScene, transition: SKTransition.reveal(with: .up, duration: 1))
            return
        }
        
        let playerWeapon = SKSpriteNode(imageNamed: "playerWeapon")
        playerWeapon.position = player.position
        
        playerWeapon.physicsBody = SKPhysicsBody(rectangleOf: playerWeapon.size)
        playerWeapon.physicsBody?.categoryBitMask = CollisionType.playerWeapon.rawValue
        playerWeapon.physicsBody?.collisionBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        playerWeapon.physicsBody?.contactTestBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        
        addChild(playerWeapon)
        
        let movement = SKAction.move(to: CGPoint(x: ENEMY_START_X, y: playerWeapon.position.y), duration: 3)
        let lifeSequence = SKAction.sequence([movement, .removeFromParent()])
        playerWeapon.run(lifeSequence)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        
        let sortedNodes = [nodeA, nodeB].sorted { $0.name ?? "" < $1.name ?? "" }
        
        let firstNode = sortedNodes[0]
        let secondNode = sortedNodes[1]
        
        if secondNode.name == "player" {
            guard isPlayerAlive else { return }
            
            explode(at: firstNode.position)
            
            playerShields -= 1
            
            if playerShields <= 0 {
                gameOver()
                secondNode.removeFromParent()
            }
            
            firstNode.removeFromParent()
        } else if let enemy = firstNode as? EnemyNode {
            enemy.shields -= 1
            
            if enemy.shields <= 0 {
                explode(at: enemy.position)
                
                enemy.removeFromParent()
            }
            
            explode(at: secondNode.position)
            
            secondNode.removeFromParent()
        } else {
            explode(at: secondNode.position)
            firstNode.removeFromParent()
            secondNode.removeFromParent()
        }
    }
    
    func explode(at position: CGPoint) {
        if let explosion = SKEmitterNode(fileNamed: "Explosion") {
            explosion.position = position
            addChild(explosion)
        }
    }
    
    func gameOver() {
        isPlayerAlive = false
        explode(at: player.position)
        let gameOver = SKSpriteNode(imageNamed: "gameOver")
        addChild(gameOver)
    }
}
