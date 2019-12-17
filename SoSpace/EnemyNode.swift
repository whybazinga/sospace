//
//  EnemyNode.swift
//  SoSpace
//

import SpriteKit

let OFFSCREEN_COORDINATE_X:CGFloat = -10000
let ENEMY_SHIP_CURVE_PATH_TO_POINT_X:CGFloat = -3500
let ENEMY_SHIP_CURVE_PATH_TO_POINT_Y:CGFloat = 0
let ENEMY_SHIP_CURVE_PATH_COTROL_POINT_1_X:CGFloat = -1000
let ENEMY_SHIP_CURVE_PATH_COTROL_POINT_2_X:CGFloat = -1000
let ENEMY_WEAPON_MASS:CGFloat = 0.001

class EnemyNode: SKSpriteNode {
    let type:EnemyType
    var lastFireTime:Double = 0
    var shields:Int
    
    init(type:EnemyType, startPosition:CGPoint, xOffset:CGFloat, moveStraight:Bool) {
        self.type = type
        shields = type.shields
        
        let texture = SKTexture(imageNamed: type.name)
        super.init(texture: texture, color: .white, size: texture.size())
        
        physicsBody = SKPhysicsBody(rectangleOf: texture.size())
        physicsBody?.categoryBitMask = CollisionType.enemy.rawValue
        physicsBody?.collisionBitMask = CollisionType.player.rawValue | CollisionType.playerWeapon.rawValue
        physicsBody?.contactTestBitMask = CollisionType.player.rawValue | CollisionType.playerWeapon.rawValue
        
        name = "enemy"
        position = CGPoint(x: startPosition.x + xOffset, y: startPosition.y)
        
        configureMovement(moveStraight)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not supported")
    }
    
    func configureMovement(_ moveStraight:Bool) {
        let path = UIBezierPath()
        path.move(to: .zero)
        
        if moveStraight {
            path.addLine(to: CGPoint(x: OFFSCREEN_COORDINATE_X, y: 0))
        } else {
            path.addCurve(
                to: CGPoint(x: ENEMY_SHIP_CURVE_PATH_TO_POINT_X, y: ENEMY_SHIP_CURVE_PATH_TO_POINT_Y),
                controlPoint1: CGPoint(x: ENEMY_SHIP_CURVE_PATH_COTROL_POINT_1_X, y: -position.y * 4),
                controlPoint2: CGPoint(x: ENEMY_SHIP_CURVE_PATH_COTROL_POINT_2_X, y: -position.y)
            )
        }
        
        let movement = SKAction.follow(path.cgPath, asOffset: true, orientToPath: true, speed: type.speed)
        let lifeSequence = SKAction.sequence([movement, .removeFromParent()])
        run(lifeSequence)
    }
    
    func fire() {
        let weaponType = "\(type.name)Weapon"
        
        let weapon = SKSpriteNode(imageNamed: weaponType)
        weapon.name = "enemyWeapon"
        weapon.position = position
        weapon.zRotation = zRotation
        parent?.addChild(weapon)
        
        weapon.physicsBody = SKPhysicsBody(rectangleOf: weapon.size)
        weapon.physicsBody?.categoryBitMask = CollisionType.enemyWeapon.rawValue
        weapon.physicsBody?.collisionBitMask = CollisionType.player.rawValue
        weapon.physicsBody?.contactTestBitMask = CollisionType.player.rawValue
        weapon.physicsBody?.mass = ENEMY_WEAPON_MASS
        
        let speed:CGFloat = 1
        let adjustedRotation = zRotation + CGFloat.pi / 2
        
        let deltaX = speed * cos(adjustedRotation)
        let deltaY = speed * sin(adjustedRotation)
        
        weapon.physicsBody?.applyImpulse(CGVector(dx: deltaX, dy: deltaY))
    }
}
