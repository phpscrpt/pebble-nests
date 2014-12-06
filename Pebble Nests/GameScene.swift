
//
//  GameScene.swift
//  Pebble Nest
//
//  Created by ahmet ertek on 11/1/14.
//  Copyright (c) 2014 Ahmet Ertek. All rights reserved.
//

import SpriteKit
import iAd

class GameScene: SKScene, SettingsSceneDelegate, ADBannerViewDelegate {
    
    var game: Game?
    var settingsView: SKView?
    var manuallyPaused: Bool=false
    var sounds:[String:SKAction]=[:]
    var adBannerView: ADBannerView?
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        //--- preload sound actions ----
        self.loadSounds()
        
        //------ IAD BANNER VIEW -------
        let adBanner = ADBannerView(frame: CGRect.zeroRect)
        adBanner.center = CGPoint(x: adBanner.center.x, y: view.bounds.size.height - adBanner.frame.size.height / 2)
        adBanner.delegate = self
        adBanner.hidden   = true
        self.adBannerView = adBanner
        
        let boardSize      = CGSize(width:280,height: 500)
        let gameBoard      = SKSpriteNode(imageNamed:"board")
        
        gameBoard.name     = "gameBoard"
        gameBoard.position = CGPoint(x:CGRectGetMidX(self.frame),y:CGRectGetMidY(self.frame))
        self.addChild(gameBoard)
        
        var defaultMode  = GameMode.CompXHuman
        let gameSettings = NSUserDefaults.standardUserDefaults()
        
        if ( gameSettings.objectForKey("mode") != nil )
        {
            defaultMode = GameMode(rawValue: gameSettings.integerForKey("mode"))!
        }
        
        self.game = Game(scene:self,mode:defaultMode)
        
        let player1 = Player(game:self.game!)
        
        let board1Position = CGPoint(x:-boardSize.width/2+20,y:-boardSize.height/2)
        player1.setBoard(board1Position,nestId:0)
        gameBoard.addChild(player1.board!.row)
        
        let player2 = Player(game:self.game!)
        
        let board2Position = CGPoint(x:5,y:-boardSize.height/2)
        player2.setBoard(board2Position,nestId:5)
        gameBoard.addChild(player2.board!.row)
        player2.setTurn(true)
        
        self.game!.players      += [player1,player2]
        self.game!.activePlayer = player2
        self.game!.setPlayerModes()
        
        player1.declareNotPlaying()
        player2.declarePlaying()
        player2.board?.unstabilizeNests()
        
        //---- buttons ----
        
        let settingsButton      = SKSpriteNode(imageNamed:"settingsButton")
        settingsButton.name     = "settingsButton"
        settingsButton.position = CGPointMake(-70,-290)
        gameBoard.addChild(settingsButton)
        
        let helpButton      = SKSpriteNode(imageNamed:"helpButton")
        helpButton.name     = "helpButton"
        helpButton.position = CGPointMake(0,-290)
        gameBoard.addChild(helpButton)
        
        let replayButton      = SKSpriteNode(imageNamed:"replayButton")
        replayButton.name     = "replayButton"
        replayButton.position = CGPointMake(70, -290)
        gameBoard.addChild(replayButton)
        
        //------- Settings View and Scene ------
        
        self.settingsView = SKView(
            frame: CGRectMake(
                0, 0,
                self.view!.frame.width, self.view!.frame.height))
        
        self.settingsView!.ignoresSiblingOrder = true
        self.settingsView!.opaque=true
        
        let settingsScene            = SettingsScene.unarchiveFromFile("SettingsScene") as? SettingsScene
        settingsScene!.scaleMode     = .AspectFill
        settingsScene!.thisDelegate  = self
        self.settingsView!.presentScene(settingsScene!)
        
        //------ add pauseGame action as observer to pause the game
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "pauseGameAuto", name: UIApplicationWillResignActiveNotification, object: nil)
        
        
        //------ add resumeGame action as observer to resume the game
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "resumeGameAuto", name: UIApplicationDidBecomeActiveNotification, object: nil)
        
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
            
            
            self.releaseSubViews(self.view?.subviews as [UIView])
            self.releaseSubViews(self.settingsView?.subviews as [UIView])
            
            self.settingsView?.removeFromSuperview()
            
            self.game?.activePlayer=nil
            self.game?.players.removeAll(keepCapacity: false)
            self.game?.prevStatus=nil
            self.game=nil
            self.settingsView=nil

            self.removeAllChildren()
            self.removeAllActions()
            self.removeFromParent()
            
            let transition = SKTransition.doorwayWithDuration(1.0)
            let newGameScene = GameScene.unarchiveFromFile("GameScene") as? GameScene
            newGameScene!.scaleMode = SKSceneScaleMode.AspectFill
            self.scene?.view!.presentScene(newGameScene!, transition: transition)
            
            if newGameScene?.game?.audio == true
            {
                let replaySound = self.getSound(GameActions.nestClosedSound.name())
                newGameScene!.runAction(replaySound)
            }
            
            
        }
        else if( node.name == "helpButton" )
        {
            self.manuallyPaused = true
            self.pauseGame()
            
            let howToPlay = "The objective of the game is to move all pebbles you have in 4 nests to either your main nest or to your opponent's side. Each time you empty all your nests, you cover one of your nests. The game ends when one of players covers all nests he/she has. You may have to push pebbles of your opponent backward or add pebbles to his/her nests in order to make it difficult for him/her to win. Therefore, you need to calculate up to which nest your pebbles can reach before selecting a nest to play."
            
            // Create the alert controller
            var alertController = UIAlertController(title: "How To Play Pebble Nests:", message: howToPlay, preferredStyle: .Alert)
            
            // Create the actions
            var okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
                UIAlertAction in
                
                self.manuallyPaused = false
                self.resumeGame()
            }

            
            // Add the actions
            alertController.addAction(okAction)
            
            // Present the controller
            self.view!.window?.rootViewController!.presentViewController(alertController, animated: true, completion: nil)
            
        }
        else if ( node.name == "settingsButton" )
        {
            let nodeImage = node as SKSpriteNode
            nodeImage.texture = SKTexture(imageNamed: "settingsButtonPressed")
            nodeImage.runAction(SKAction.waitForDuration(0.2),completion:{
                
                nodeImage.texture = SKTexture(imageNamed: "settingsButton")
                
            })
            
            //-- pause the game for a while ---
            self.manuallyPaused = true
            self.pauseGame()
            
            // set a transition style
            let transitionOptions = UIViewAnimationOptions.TransitionFlipFromLeft
            
            UIView.transitionWithView(self.view!, duration: 1.0, options: transitionOptions, animations: {
                // remove the front object...
                self.view!.addSubview(self.settingsView!)
                
                }, completion: nil)
            
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
    
    func loadSounds()
    {
        self.sounds[GameActions.movePebbleSound.name()] = GameActions.movePebbleSound.action()
        self.sounds[GameActions.blinkSound.name()]      = GameActions.blinkSound.action()
        self.sounds[GameActions.turnEnd.name()]         = GameActions.turnEnd.action()
        self.sounds[GameActions.nestClosedSound.name()] = GameActions.nestClosedSound.action()
        self.sounds[GameActions.gameOver.name()]        = GameActions.gameOver.action()
        self.sounds[GameActions.replayGameSound.name()] = GameActions.replayGameSound.action()
        
    }
    
    func getSound(sound:String)->SKAction
    {
        return self.sounds[sound]!
    }
    
    func releaseSubViews(var subs:[UIView])
    {
        
        if( subs.count > 0 )
        {
            for ui:UIView in subs as [UIView]
            {
                if( ui.subviews.count > 0 )
                {
                    self.releaseSubViews(ui.subviews as [UIView])
                }
                
                ui.removeFromSuperview()
            }
            
        }
        
        
    }
    
    func settingsOk(myScene: SettingsScene, command: String)
    {
        myScene.view!.removeFromSuperview()
        if command == "SettingsOk"
        {
            self.manuallyPaused = false
            self.game?.refreshSettings()
            self.resumeGame()
        }
    }
    
    func pauseGame()
    {
        self.view?.paused=true
        self.game?.pause()
    }
    
    func resumeGame()
    {
        //--- preload sound actions ----
        self.loadSounds()

        self.view?.paused=false
        self.game?.resume()
        
    }
    
    func pauseGameAuto()
    {
        if( !self.manuallyPaused )
        {
            self.pauseGame()
        }
    }
    
    func resumeGameAuto()
    {
        if( !self.manuallyPaused )
        {
            self.resumeGame()
        }
        else
        {
            self.view?.paused=true
        }

    }
    
    func bannerViewWillLoadAd(banner: ADBannerView!) {
        //NSLog("bannerViewWillLoadAd")
    }
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        //NSLog("bannerViewDidLoadAd")
        self.adBannerView?.hidden = false
    }
    
    func bannerViewActionDidFinish(banner: ADBannerView!) {
        //NSLog("bannerViewDidLoadAd")
        
        self.resumeGame()
        
    }
    
    func bannerViewActionShouldBegin(banner: ADBannerView!, willLeaveApplication willLeave: Bool) -> Bool {
        //NSLog("bannerViewActionShouldBegin")
        
        self.pauseGame()
        return true
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        //NSLog("bannerView")
        
        self.adBannerView?.hidden=true
    }
    
    deinit
    {
        self.sounds.removeAll(keepCapacity: false)
        self.game=nil
        self.settingsView=nil
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}
