//
//  GameScene.swift
//  PeevedPenguins
//
//  Created by Carlos Diez on 6/24/16.
//  Copyright (c) 2016 Carlos Diez. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    enum GameState {
        case Playing, GameOver
    }
    
    var catapultArm: SKSpriteNode!
    var catapult: SKSpriteNode!
    var levelNode: SKNode!
    var cameraTarget: SKNode?
    var buttonRestart: MSButtonNode!
    var buttonPlayAgain: MSButtonNode!
    var buttonNextLevel: MSButtonNode!
    var cantileverNode: SKSpriteNode!
    var touchNode: SKSpriteNode!
    var penguinToRemove: SKSpriteNode?
    
    var scoreLabel: SKLabelNode!
    var scoreOverLabel: SKLabelNode!
    var highScoreLabel: SKLabelNode!
    var scoreTextLabel: SKLabelNode!
    var highScoreTextLabel1: SKLabelNode!
    var highScoreTextLabel2: SKLabelNode!
    
    var touchJoint: SKPhysicsJointSpring?
    var penguinJoint: SKPhysicsJointPin?
    
    var gameState: GameState = .Playing
    var levelLives = 3
    var score = 0
    var currentLevel: SKReferenceNode!
    var currentLevelNumber = 1
    let levelCount = 2
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        physicsWorld.contactDelegate = self
        
        catapultArm = self.childNodeWithName("catapultArm") as! SKSpriteNode
        catapult = self.childNodeWithName("catapult") as! SKSpriteNode
        levelNode = self.childNodeWithName("//levelNode")
        buttonRestart = self.childNodeWithName("//buttonRestart") as! MSButtonNode
        buttonPlayAgain = self.childNodeWithName("buttonPlayAgain") as! MSButtonNode
        buttonNextLevel = self.childNodeWithName("buttonNextLevel") as! MSButtonNode
        cantileverNode = self.childNodeWithName("cantileverNode") as! SKSpriteNode
        touchNode = self.childNodeWithName("touchNode") as! SKSpriteNode
        
        scoreLabel = self.childNodeWithName("//scoreLabel") as! SKLabelNode
        scoreOverLabel = self.childNodeWithName("scoreOverLabel") as! SKLabelNode
        highScoreLabel = self.childNodeWithName("highScoreLabel") as! SKLabelNode
        scoreTextLabel = self.childNodeWithName("scoreTextLabel") as! SKLabelNode
        highScoreTextLabel1 = self.childNodeWithName("highScoreTextLabel1") as! SKLabelNode
        highScoreTextLabel2 = self.childNodeWithName("highScoreTextLabel2") as! SKLabelNode
        
        let resourcePath = NSBundle.mainBundle().pathForResource("Level1", ofType: "sks")
        let newLevel = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath!))
        levelNode.addChild(newLevel)
        currentLevel = newLevel
        
        /* Create catapult arm physics body of type alpha */
        let catapultArmBody = SKPhysicsBody (texture: catapultArm!.texture!, size: catapultArm.size)
        
        /* Set mass, needs to be heavy enough to hit the penguin with solid force */
        catapultArmBody.mass = 0.5
        
        /* Improves physics collision handling of fast moving objects */
        catapultArmBody.usesPreciseCollisionDetection = true
        
        catapultArmBody.affectedByGravity = false
        
        /* Assign the physics body to the catapult arm */
        catapultArm.physicsBody = catapultArmBody
        
        /* Pin joint catapult and catapult arm */
        let catapultPinJoint = SKPhysicsJointPin.jointWithBodyA(catapult.physicsBody!, bodyB: catapultArm.physicsBody!, anchor: CGPoint(x:220 ,y:105))
        physicsWorld.addJoint(catapultPinJoint)
        
        /* Spring joint catapult arm and cantilever node */
        let catapultSpringJoint = SKPhysicsJointSpring.jointWithBodyA(catapultArm.physicsBody!, bodyB: cantileverNode.physicsBody!, anchorA: catapultArm.position + CGPoint(x:15, y:30), anchorB: cantileverNode.position)
        physicsWorld.addJoint(catapultSpringJoint)
        
        /* Make this joint a bit more springy */
        catapultSpringJoint.frequency = 1.5
        
        /* Setup restart button selection handler */
        buttonRestart.selectedHandler = {
            self.restartGame()
        }
        
        buttonPlayAgain.selectedHandler = {
            self.restartGame()
        }
        
        buttonNextLevel.selectedHandler = {
            self.loadNextLevel()
        }
        
        toggleHideGameOverElements(hideElements: true)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
       /* Called when a touch begins */
        if gameState != .Playing { return }
        
        /* There will only be one touch as multi touch is not enabled by default */
        for touch in touches {
            
            /* Grab scene position of touch */
            let location = touch.locationInNode(self)
            
            /* Get node reference if we're touching a node */
            let touchedNode = nodeAtPoint(location)
            
            /* Is it the catapult arm? */
            if touchedNode.name == "catapultArm" {
                
                /* Reset touch node position */
                touchNode.position = location
                
                /* Spring joint touch node and catapult arm */
                touchJoint = SKPhysicsJointSpring.jointWithBodyA(touchNode.physicsBody!, bodyB: catapultArm.physicsBody!, anchorA: location, anchorB: location)
                physicsWorld.addJoint(touchJoint!)
                
                let resourcePath = NSBundle.mainBundle().pathForResource("Penguin", ofType: "sks")
                let penguin = MSReferenceNode(URL: NSURL (fileURLWithPath: resourcePath!))
                addChild(penguin)
                
                /* Position penguin in the catapult bucket area */
                penguin.avatar.position = catapultArm.position + CGPoint(x: 32, y: 50)
                
                /* Improves physics collision handling of fast moving objects */
                penguin.avatar.physicsBody?.usesPreciseCollisionDetection = true
                
                /* Setup pin joint between penguin and catapult arm */
                penguinJoint = SKPhysicsJointPin.jointWithBodyA(catapultArm.physicsBody!, bodyB: penguin.avatar.physicsBody!, anchor: penguin.avatar.position)
                physicsWorld.addJoint(penguinJoint!)
                
                camera?.removeAllActions()
                
                /* Set camera to follow penguin */
                cameraTarget = penguin.avatar
            }
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* There will only be one touch as multi touch is not enabled by default */
        for touch in touches {
            
            /* Grab scene position of touch and update touchNode position */
            let location = touch.locationInNode(self)
            touchNode.position = location
            
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Let it fly!, remove joints used in catapult launch */
        if let touchJoint = touchJoint { physicsWorld.removeJoint(touchJoint) }
        if let penguinJoint = penguinJoint {
            physicsWorld.removeJoint(penguinJoint)
            penguinToRemove = self.childNodeWithName("live\(levelLives)") as? SKSpriteNode
            if let penguinToRemove = penguinToRemove {
                penguinToRemove.removeFromParent()
                levelLives -= 1
            }
        }
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        if gameState != .Playing { return }
        
        /* Check we have a valid camera target to follow */
        if let cameraTarget = cameraTarget {
            
            /* Set camera position to follow target horizontally, keep vertical locked */
            camera?.position = CGPoint(x:cameraTarget.position.x, y:camera!.position.y)
            camera?.position.x.clamp(283, 677)
            
            /* Check penguin has come to rest */
            if cameraTarget.physicsBody?.joints.count == 0 && cameraTarget.physicsBody?.velocity.length() < 0.18 {
                
                cameraTarget.removeFromParent()
                
                /* Reset catapult arm */
                catapultArm.physicsBody?.velocity = CGVector(dx:0, dy:0)
                catapultArm.physicsBody?.angularVelocity = 0
                catapultArm.zRotation = 0
                
                /* Reset camera */
                let cameraReset = SKAction.moveTo(CGPoint(x:284, y:camera!.position.y), duration: 1.5)
                let cameraDelay = SKAction.waitForDuration(0.5)
                let cameraSequence = SKAction.sequence([cameraDelay,cameraReset])
                
                camera?.runAction(cameraSequence)
                
                if levelLives == 0 {
                    gameState = .GameOver
                    toggleHideGameOverElements(hideElements: false)
                    let userDefaults = NSUserDefaults.standardUserDefaults()
                    var highscore = userDefaults.integerForKey("highscore")
                    
                    if score > highscore {
                        userDefaults.setValue(score, forKey: "highscore")
                        userDefaults.synchronize()
                    }
                    
                    highscore = userDefaults.integerForKey("highscore")
                    
                    highScoreLabel.text = String(highscore)
                    
                    if score > 350 && currentLevelNumber < levelCount {
                        buttonNextLevel.state = .MSButtonNodeStateActive
                    }
                }
            }
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        /* Physics contact delegate implementation */
        if gameState != .Playing { return }
        
        /* Get references to the bodies involved in the collision */
        let contactA:SKPhysicsBody = contact.bodyA
        let contactB:SKPhysicsBody = contact.bodyB
        
        /* Get references to the physics body parent SKSpriteNode */
        let nodeA = contactA.node as! SKSpriteNode
        let nodeB = contactB.node as! SKSpriteNode
        
        /* Check if either physics bodies was a seal */
        if contactA.categoryBitMask == 2 || contactB.categoryBitMask == 2 {
            
            if contact.collisionImpulse > 2.0 {
                
                /* Kill Seal(s) */
                if contactA.categoryBitMask == 2 { dieSeal(nodeA) }
                if contactB.categoryBitMask == 2 { dieSeal(nodeB) }
            }
        }
    }
    
    func dieSeal(node: SKNode) {
        
        /* Load our particle effect */
        let particles = SKEmitterNode(fileNamed: "FireParticleTest")!
        
        /* Convert node location (currently inside Level 1, to scene space) */
        particles.position = convertPoint(node.position, fromNode: node)
        
        /* Restrict total particles to reduce runtime of particle */
        particles.numParticlesToEmit = 25
        
        /* Add particles to scene */
        addChild(particles)
        
        /* Create our hero death action */
        let sealDeath = SKAction.runBlock({
            /* Remove seal node from scene */
            node.removeFromParent()
        })
        
        self.runAction(sealDeath)
        
        let sealSFX = SKAction.playSoundFileNamed("sfx_seal", waitForCompletion: false)
        self.runAction(sealSFX)
        
        score += 100
        scoreLabel.text = "Score: \(score)"
        scoreOverLabel.text = String(score)
    }
    
    func restartGame() {
        /* Grab reference to our SpriteKit view */
        let skView = self.view as SKView!
        
        /* Load Game scene */
        let scene = GameScene(fileNamed:"GameScene") as GameScene!
        
        /* Ensure correct aspect mode */
        scene.scaleMode = .AspectFit
        
        /* Show debug */
        //skView.showsPhysics = true
        skView.showsDrawCount = true
        skView.showsFPS = false
        
        /* Restart game scene */
        skView.presentScene(scene)
    }
    
    func toggleHideGameOverElements(hideElements hide: Bool) {
        if hide {
            buttonPlayAgain.state = .MSButtonNodeStateHidden
            buttonNextLevel.state = .MSButtonNodeStateHidden
            buttonRestart.state = .MSButtonNodeStateActive
        }
        else {
            buttonPlayAgain.state = .MSButtonNodeStateActive
            buttonRestart.state = .MSButtonNodeStateHidden
        }
        scoreOverLabel.hidden = hide
        highScoreLabel.hidden = hide
        scoreTextLabel.hidden = hide
        highScoreTextLabel1.hidden = hide
        highScoreTextLabel2.hidden = hide
        
        scoreLabel.hidden = !hide
    }
    
    func loadNextLevel() {
        currentLevelNumber += 1
        levelLives = 3
        score = 0
        
        scoreLabel.text = "Score: \(score)"
        
        currentLevel.removeFromParent()
        
        let resourcePath = NSBundle.mainBundle().pathForResource("Level\(currentLevelNumber)", ofType: "sks")
        let nextLevel = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath!))
        
        currentLevel = nextLevel
        
        levelNode.addChild(currentLevel)
        
        toggleHideGameOverElements(hideElements: true)
        
        gameState = .Playing
    }
}
