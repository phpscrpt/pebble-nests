
//
//  GameScene.swift
//  Pebble Nest
//
//  Created by ahmet ertek on 11/1/14.
//  Copyright (c) 2014 Ahmet Ertek. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SettingsSceneDelegate {
    
    var game: Game?
    
    var settingsView: SKView?
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        
        let boardSize = CGSize(width:280,height: 500)
        
        let gameBoard      = SKSpriteNode(imageNamed:"board")
        
        gameBoard.name     = "gameBoard"
        gameBoard.position = CGPoint(x:CGRectGetMidX(self.frame),y:CGRectGetMidY(self.frame))
        self.addChild(gameBoard)
        
        self.game = Game(scene:self,mode:GameMode.CompXComp)
        
        let player1 = Player(game:self.game!)
        
        let board1Position = CGPoint(x:-boardSize.width/2+10,y:-boardSize.height/2+10)
        player1.setBoard(board1Position,nestId:0)
        gameBoard.addChild(player1.board!.row)
        
        let player2 = Player(game:self.game!)
        
        let board2Position = CGPoint(x:0,y:-boardSize.height/2+10)
        player2.setBoard(board2Position,nestId:5)
        gameBoard.addChild(player2.board!.row)
        player2.setTurn(true)
        
        self.game!.players      += [player1,player2]
        self.game!.activePlayer = player2
        self.game!.setPlayerModes()
        
        player2.declarePlaying()
        player1.declareNotPlaying()
        
        //---- buttons ----
        
        let settingsButton      = SKSpriteNode(imageNamed:"settingsButton")
        settingsButton.name     = "settingsButton"
        settingsButton.position = CGPointMake(-70,-280)
        gameBoard.addChild(settingsButton)
        
        let replayButton      = SKSpriteNode(imageNamed:"replayButton")
        replayButton.name     = "replayButton"
        replayButton.position = CGPointMake(65, -280)
        gameBoard.addChild(replayButton)
        
        if( self.game!.mode == GameMode.CompXComp )
        {
            player2.board?.unstabilizeNests()
        }
        
        
        self.settingsView = SKView(
            frame: CGRectMake(
                0, 0,
                self.view!.frame.width, self.view!.frame.height))
        
        self.settingsView!.ignoresSiblingOrder = true
        
        self.settingsView?.backgroundColor = UIColor.yellowColor()
        
        let settingsScene            = SettingsScene.unarchiveFromFile("SettingsScene") as? SettingsScene
        settingsScene!.scaleMode     = .AspectFill
        settingsScene!.thisDelegate  = self
        self.settingsView!.presentScene(settingsScene!)
        
    }
    
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        
        for touch: AnyObject in touches
        {
            let location  = touch.locationInNode(self)
            self.handleTouch(location)
        }
        
    }
    
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
    
    func handleTouch(location:CGPoint)
    {
        let node = self.nodeAtPoint(location)
        
        if ( node.name == "replayButton" )
        {
            let nodeImage = node as SKSpriteNode
            nodeImage.texture = SKTexture(imageNamed: "replayButtonPressed")
            nodeImage.runAction(SKAction.waitForDuration(0.2),completion:{
                
                nodeImage.texture = SKTexture(imageNamed: "replayButton")
                
            })
            
            self.scene!.removeFromParent()
            let transition = SKTransition.doorwayWithDuration(1.0)
            
            let skView = self.view! as SKView
            skView.ignoresSiblingOrder = true
            
            let newGameScene = GameScene.unarchiveFromFile("GameScene") as? GameScene
            newGameScene!.scaleMode = SKSceneScaleMode.AspectFill
            
            skView.presentScene(newGameScene!, transition: transition)
            
            if self.game?.audio == true
            {
                newGameScene!.runAction(GameActions.replayGameSound.action())
            }
            
        }
        else if ( node.name == "settingsButton" )
        {
            let nodeImage = node as SKSpriteNode
            nodeImage.texture = SKTexture(imageNamed: "settingsButtonPressed")
            nodeImage.runAction(SKAction.waitForDuration(0.2),completion:{
                
                nodeImage.texture = SKTexture(imageNamed: "settingsButton")
                
            })
            
            //-- pause the game for a while ---
            self.game?.pause()
            
            self.view!.addSubview(self.settingsView!)
            
        }
        else if let player  = self.game?.whosTurn()
        {
            if self.game!.waitingForPlayer()
            {
                if ( (node.name == "nest" || node.parent?.name == "nest") && node.name != "nestLabel")
                {
                    
                    var sprite:SKSpriteNode
                    if node.parent?.name == "nest"
                    {
                        sprite = node.parent! as SKSpriteNode
                    }
                    else
                    {
                        sprite = node as SKSpriteNode
                    }
                    
                    let nest:Nest? = player.findNestWithSprite(sprite)
                    
                    if let temp = nest
                    {
                        player.playTurn(nest!)
                    }
                }
            }
            
        }
    }
    
    func settingsOk(myScene: SettingsScene, command: String)
    {
        myScene.view!.removeFromSuperview()
        if command == "SettingsOk"
        {
            self.game?.refreshSettings()
            self.game?.self.resume()
        }
    }
}
