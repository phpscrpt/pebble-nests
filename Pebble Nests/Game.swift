//
//  Game.swift
//  Pebble Nest
//
//  Created by ahmet ertek on 11/3/14.
//  Copyright (c) 2014 Ahmet Ertek. All rights reserved.
//

import Foundation
import SpriteKit

enum GameStatus{
    case STARTED, PAUSED, FINISHED, WAITING, PLAYING
}

// let gameSettings = NSUserDefaults.standardUserDefaults()


enum GameMode:Int{
    case CompXHuman=0, CompXComp=1, HumanXHuman=2
    
    
    func name()->String{
        switch self{
        case .CompXComp:
            return "Computer Vs Computer"
        case .CompXComp:
            return "Computer Vs Human"
        case .HumanXHuman:
            return "Human Vs Human"
        default:
            return "Unknown Game Mode"
        }
    }
}

enum GameActions{
    
    case movePebbleSound
    case turnEnd
    case blinkSound
    case nestFadeOut
    case nestFadeIn
    case boardFadeOut
    case boardFadeIn
    case nestClosedSound
    case gameOver
    case replayGameSound
    
    func action()->SKAction{
        
        switch self {
        case .movePebbleSound:
            return SKAction.playSoundFileNamed(self.name(), waitForCompletion: false)
        case .turnEnd:
            return SKAction.playSoundFileNamed(self.name(), waitForCompletion: false)
        case .blinkSound:
            return SKAction.playSoundFileNamed(self.name(), waitForCompletion: false)
        case .nestFadeOut:
            return SKAction.fadeOutWithDuration(0.2)
        case .nestFadeIn:
            return SKAction.fadeInWithDuration(0.2)
        case .boardFadeOut:
            return SKAction.fadeOutWithDuration(3)
        case .boardFadeIn:
            return SKAction.fadeInWithDuration(3)
        case .nestClosedSound:
            return SKAction.playSoundFileNamed(self.name(), waitForCompletion: true)
        case .gameOver:
            return SKAction.playSoundFileNamed(self.name(), waitForCompletion: true)
        case .replayGameSound:
            return SKAction.playSoundFileNamed(self.name(), waitForCompletion: true)
        default:
            return SKAction.waitForDuration(0.001)
        }
    }
    
    func name()->String{
        
        switch self {
        case .movePebbleSound:
            return "pebble.mp3"
        case .turnEnd:
            return "turnend.mp3"
        case .blinkSound:
            return "blink.mp3"
        case .nestClosedSound:
            return "nestclosed.mp3"
        case .gameOver:
            return "gameover.mp3"
        case .replayGameSound:
            return "replay.mp3"
        default:
            return ""
        }
    }
    
}


class Game{
    
    let name:                 String
    var activePlayer:         Player?
    var players:              [Player]
    var status:               GameStatus
    var prevStatus:           GameStatus?
    unowned var gameScene:    GameScene
    let tray:                 SKSpriteNode
    let moveDuration:NSTimeInterval = 0.4
    
    let mode:                 GameMode
    var audio:                Bool
    
    init(scene:GameScene,name: String,mode:GameMode)
    {
        self.name           = name
        self.players        = []
        self.status         = GameStatus.STARTED
        self.mode           = mode
        self.gameScene      = scene
        self.tray           = SKSpriteNode()
        self.tray.position  = CGPoint(x:0,y:200)
        self.audio          = true
        
        scene.childNodeWithName("gameBoard")!.addChild(self.tray)
        
        self.refreshSettings()
        
    }
    
    convenience init(scene: GameScene)
    {
        self.init(scene: scene,name: "Pebble Nests",mode:GameMode.CompXHuman)
    }
    
    convenience init(scene: GameScene,mode:GameMode)
    {
        self.init(scene: scene,name: "Pebble Nests",mode:mode)
    }
    
    func setPlayerModes()
    {
        if self.mode == GameMode.CompXComp
        {
            self.players.map({$0.autoPlay=true})
            
            self.players[0].name="Comp1"
            self.players[1].name="Comp2"
            
            self.players[0].isThirdPerson=true
            self.players[1].isThirdPerson=true
        }
        else if self.mode == GameMode.CompXHuman
        {
            self.players[0].name="Comp"
            self.players[1].name="You"
            
            self.players[0].autoPlay=true
            self.players[0].isThirdPerson=true
            
            self.players[1].autoPlay=false
            self.players[1].isThirdPerson=false
        }
        else
        {
            self.players.map({$0.autoPlay=false})
            self.players[0].name="Your Friend"
            self.players[1].name="You"
            
            self.players[0].isThirdPerson=true
            self.players[1].isThirdPerson=false
        }
    }
    
    func opponentOf(player: Player) ->Player
    {
        let opponents:[Player] = self.players.filter{$0 !== player}
        return opponents[0]
    }
    
    func whosTurn() ->Player?
    {
        return self.activePlayer
    }
    
    func restoreNests()
    {
        
        var pebbleList:[SKSpriteNode] = []
        
        for currentPlayer in self.players
        {
            autoreleasepool {
                
                for nest in currentPlayer.board!.nests.filter({$0.enabled})
                {
                    for pebble in nest.pebbles
                    {
                        nest.removePebble()
                        nest.removePebbleImage(pebble!)
                        pebbleList.append(pebble!)
                        
                    }
                }
                
            }
        }
        
        for currentPlayer in self.players
        {
            for nest in currentPlayer.board!.nests.filter({$0.enabled})
            {
                if( !nest.isMain )
                {
                    autoreleasepool {
                        
                        for i in 1...5
                        {
                            let p = pebbleList.removeLast()
                            p.hidden=false
                            nest.addPebble(p)
                            nest.addPebbleImage(p)
                        }
                    }
                    
                    nest.resetAttr()
                }
                else
                {
                    nest.printPebbleCount()
                }
            }
            
        }
        
    }
    
    func over(winner:Player)
    {
        self.status         = GameStatus.FINISHED
        self.activePlayer   = nil
        
        //---- play game over sound ----
        
        if self.audio == true
        {
            self.gameScene.runAction(GameActions.gameOver.action())
        }
        
        //---- declare the winner ------
        let winnerText = winner.declareAsWinner()
        
        //----- fade out-in gam board ----
        
        /*
        let fadeOutAction   = GameActions.boardFadeOut.action()
        let fadeInAction    = GameActions.boardFadeIn.action()
        let blink           = SKAction.sequence([fadeOutAction,fadeInAction])
        let blinkForTime    = SKAction.repeatAction(blink, count:50)
        
        self.gameScene.childNodeWithName("gameBoard")!.runAction(blinkForTime)
        */
        
        let gameOverMessage = winnerText
        
        // Create the alert controller
        var alertController = UIAlertController(title: "Game Over!", message: gameOverMessage, preferredStyle: .Alert)
        
        // Create the actions
        var okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
            UIAlertAction in
            //NSLog("OK Pressed")
        }
        
        
        // Add the actions
        alertController.addAction(okAction)
        
        // Present the controller
        self.gameScene.view?.window?.rootViewController!.presentViewController(alertController, animated: true, completion: nil)
        
    }
    
    func pause()
    {
        self.prevStatus     = self.status
        self.status         = GameStatus.PAUSED
    }
    
    func resume()
    {
        if let stat = self.prevStatus
        {
            self.status     = self.prevStatus!
            self.prevStatus = nil
        }
    }
    
    func waitingForPlayer()->Bool
    {
        if self.status == GameStatus.WAITING || self.status == GameStatus.STARTED
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    func playClosedNestSound()
    {
        if self.audio == true
        {
            let nestClosedSound = self.gameScene.getSound(GameActions.nestClosedSound.name())
            self.gameScene.runAction(nestClosedSound)
        }
    }
    
    func refreshSettings()
    {
        let gameSettings = NSUserDefaults.standardUserDefaults()
        
        if ( gameSettings.objectForKey("audio") != nil)
        {
            self.audio = gameSettings.boolForKey("audio")
        }
        
        //--- more settings to be applied here -----
        
    }
    
    deinit
    {
        self.activePlayer = nil
        self.players.removeAll(keepCapacity: false)
        self.prevStatus   = nil
        self.tray.removeAllActions()
        self.tray.removeAllChildren()
        self.tray.removeFromParent()
    }
}

