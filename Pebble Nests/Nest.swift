//
//  Nest.swift
//  Pebble Nest
//
//  Created by ahmet ertek on 11/1/14.
//  Copyright (c) 2014 Ahmet Ertek. All rights reserved.
//

import Foundation
import SpriteKit

class Nest{
    
    var image:             SKSpriteNode
    var enabled:           Bool
    var pebbles:           [SKSpriteNode]
    unowned let player:    Player
    var isMain:            Bool
    let nestId:            Int
    
    init(owner: Player,image: String, location: CGPoint,isEnabled: Bool, pebbleCount: Int,nestId: Int)
    {
        
        self.player            = owner
        self.image             = SKSpriteNode(imageNamed:image)
        self.image.name        = "nest"
        self.image.position    = location
        self.image.zPosition   = 10
        self.enabled           = isEnabled
        self.pebbles           = []
        self.isMain            = false
        self.nestId            = nestId
        
        let pebblePositions = Nest.pebblePositions()
        for( var i=0; i<pebbleCount; i++ )
        {
            self.addNewPebble(pebblePositions[i])
        }
        
        let nestLabel       = SKLabelNode(fontNamed:"Futura")
        nestLabel.fontColor = SKColor(red: 255.0, green: 255.0, blue: 255.0, alpha: 1.0)
        nestLabel.fontSize  = 16
        nestLabel.name      = "nestLabel"
        
        if( nestId <= 5 )
        {
            nestLabel.position  = CGPoint(x:-48,y:0)
        }
        else
        {
            nestLabel.position  = CGPoint(x:48,y:0)
        }
        
        self.image.addChild(nestLabel)
        self.printPebbleCount()
        
    }
    
    convenience init(owner: Player,image: String, location: CGPoint,isEnabled: Bool,nestId: Int)
    {
        self.init(owner: owner,image: image,location: location, isEnabled: isEnabled,pebbleCount: 5,nestId:nestId)
        
    }
    
    convenience init(owner: Player,location: CGPoint,isEnabled: Bool,nestId: Int)
    {
        self.init(owner: owner,image: "nest",location: location, isEnabled: isEnabled,nestId: nestId)
    }
    
    convenience init(owner: Player,nestId: Int)
    {
        self.init(owner: owner,location: CGPoint(x:50,y:50),isEnabled: true,nestId: nestId)
    }
    
    func disable()
    {
        enabled = false
    }
    
    func enable()
    {
        enabled = true
    }
    
    func setActiveNestImage()
    {
        self.image.texture = SKTexture(imageNamed: "nestActive")
    }
    
    func addNewPebble(position: CGPoint)
    {
        let newPebble         = SKSpriteNode(imageNamed:"pebble")
        newPebble.position    = position
        
        self.addPebbleImage(newPebble)
        self.addPebble(newPebble)
    }
    
    func addPebble(pebble:SKSpriteNode)
    {
        self.pebbles.append(pebble)
    }
    
    func removePebble() ->SKSpriteNode?
    {
        return self.pebbles.removeLast()
    }
    
    func removePebbleImage(pebble:SKSpriteNode)
    {
        self.image.removeChildrenInArray([pebble])
    }
    
    func addPebbleImage(pebble:SKSpriteNode)
    {
        pebble.zPosition = 11
        self.image.addChild(pebble)
    }
    
    func resetAttr()
    {
        self.organizePebbles()
        self.printPebbleCount()
    }
    
    func acceptPebble(pebble:SKSpriteNode)
    {
        pebble.position = CGPoint(x:0,y:0)
        self.addPebbleImage(pebble)
        self.addPebble(pebble)
    }
    
    func indexInChain(nestChain:[Nest]) ->Int?
    {
        for(var i=0; i<nestChain.count; i++ )
        {
            if( nestChain[i].enabled && nestChain[i].nestId == self.nestId )
            {
                return i
            }
        }
        
        return nil
    }
    
    func nextIndexInChain(nestChain:[Nest]) ->Int?
    {
        let activeIndex:Int? = self.indexInChain(nestChain)
        
        if let tempInd = activeIndex
        {
            return (activeIndex! + 1) % nestChain.count
        }
        else
        {
            return nil
        }
    }
    
    func movePebblesToTray()
    {
        for p in self.pebbles
        {
            p.removeFromParent()
            self.player.game?.tray.addChild(p)
        }
        
        self.pebbles.removeAll()
        
    }
    
    func unorganizePebbles()
    {
        for p in self.pebbles
        {
            p.physicsBody?.dynamic = false
        }
        
    }
    
    func organizePebbles()
    {
        if( self.pebbles.count <= 5 )
        {
            let pebblePositions = Nest.pebblePositions()
            for (i,p) in enumerate(self.pebbles)
            {
                p.position = pebblePositions[i]
            }
        }
        else
        {
            var a:CGFloat = 0.0
            var r:CGFloat = CGFloat(5.0)
            var i = 0
            
            for p in self.pebbles
            {
                if( i == 0 )
                {
                    p.position = CGPoint(x:0,y:0)
                }
                else
                {
                    let newX = (r+CGFloat(i+2))*cos(a)
                    let newY = (r+CGFloat(i+2))*sin(a)
                    p.position = CGPoint(x:newX,y:newY)
                    a += CGFloat(M_PI/4)
                    
                }
                
                i++
            }
        }
        
    }
    
    func printPebbleCount()
    {
        let label:SKLabelNode? = self.image.childNodeWithName("nestLabel") as? SKLabelNode
        
        if let temp = label
        {
            let lastPebbleCount = self.pebbles.count
            var pebbleTextCount = "\(lastPebbleCount)"
            
            if( lastPebbleCount > 1 )
            {
                //pebbleTextCount = pebbleTextCount + "s"
            }
            
            label!.text = pebbleTextCount
        }
    }
    
    func isEmpty()->Bool
    {
        if( self.pebbles.count == 0 )
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    func canContinue()->Bool
    {
        if( self.pebbles.count > 1 && !self.isMain && self.enabled )
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    
    func movePebblesAndBlink(nestChain: [Nest],currentPlayer:Player)
    {
        let fadeOutAction   = GameActions.nestFadeOut.action()
        let fadeInAction    = GameActions.nestFadeIn.action()
        let blinkSound      = GameActions.blinkSound.action()
        var blink:SKAction
        
        if self.player.game?.audio == true
        {
            blink           = SKAction.sequence([fadeOutAction,blinkSound,fadeInAction])
        }
        else
        {
            blink           = SKAction.sequence([fadeOutAction,fadeInAction])
        }
        
        let blinkForTime    = SKAction.repeatAction(blink, count:1)
        let tray            = self.player.game?.tray
        
        self.image.runAction(blinkForTime,completion:{
            
            self.movePebblesToTray()
            
            //self.image.colorBlendFactor = 1.0
            //self.image.color            = SKColor.whiteColor()
            
            self.printPebbleCount()
            var pebbles     = tray!.children as [SKSpriteNode]
                        
            currentPlayer.playPebbles(pebbles,chain: nestChain, activeNest: self)
            
        })
    }
    
    class func pebblePositions()->[CGPoint]
    {
        return [CGPointMake(0,0),CGPointMake(-15,-15),CGPointMake(15,15),CGPointMake(-15,15),CGPointMake(15,-15)]
    }
    
    deinit
    {
        self.pebbles.map({$0.removeFromParent()})
        self.pebbles.removeAll(keepCapacity: false)
        self.image = SKSpriteNode()
        
    }
}

