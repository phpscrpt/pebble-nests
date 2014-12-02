//
//  Board.swift
//  Pebble Nest
//
//  Created by ahmet ertek on 11/1/14.
//  Copyright (c) 2014 Ahmet Ertek. All rights reserved.
//

import Foundation
import SpriteKit

class Board{
    
    var nests:             [Nest]
    let row:               SKSpriteNode
    unowned let player:    Player
    let nestHeight:        Int
    let nestWidth:         Int
    
    init(position: CGPoint, player: Player, label: String)
    {
        row                = SKSpriteNode()
        let rowLabel       = SKLabelNode(fontNamed:"Futura")
        rowLabel.name      = "playerName"
        rowLabel.fontColor = SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        rowLabel.text      = label
        rowLabel.fontSize  = 16
        rowLabel.position  = CGPoint(x:63,y:10)
        
        row.position       = position
        row.addChild(rowLabel)
        
        self.player  = player
        self.nests   = []
        nestHeight   = 80
        nestWidth    = 80
        
    }
    
    func locateNests(count: Int=5,nestId:Int)
    {
        let xInit  = (self.nestWidth / 2) + 20
        let yInit  = 0
        let height = self.nestHeight
        
        for (var i=0; i<count; i++)
        {
            autoreleasepool {
                
                let xCoord       = xInit
                let yCoord       = yInit + (i+1) * height
                let nestLocation = CGPoint(x: xCoord, y: yCoord)
                var nest: Nest
                
                if( i < count - 1 )
                {
                    nest = Nest(owner: self.player,location: nestLocation,isEnabled: true,nestId: nestId+i+1)
                }
                else
                {
                    nest = Nest(owner: self.player,image:"nestMain",location: nestLocation,isEnabled: true,pebbleCount: 0,nestId: nestId+i+1)
                    nest.isMain = true
                }
                
                self.row.addChild(nest.image)
                self.nests.append(nest)
                
            }
            
        }
    }
    
    func playableNests()->[Nest]
    {
        return self.nests.filter({!$0.isMain && $0.enabled && $0.pebbles.count > 0})
    }
    
    func stabilizeNests()
    {
        for n in self.playableNests()
        {
            n.pebbles.map({
                
                (var pebble)->SKSpriteNode in
                pebble!.removeActionForKey("pulsePebbles")
                pebble!.setScale(1.0)
                return pebble!
            })
        }
    }
    
    func unstabilizeNests()
    {
        let scaleAmount     = CGFloat(1.0)
        let actionEnlarge   = SKAction.scaleBy(scaleAmount, duration:1)
        let actionShrink    = SKAction.scaleBy(-scaleAmount, duration:0.2)
        let pulse           = SKAction.sequence([actionEnlarge,actionShrink])
        
        for n in self.playableNests()
        {
            n.pebbles.map({$0!.runAction(SKAction.repeatActionForever(pulse),withKey:"pulsePebbles")})
        }
    }
    
    deinit
    {
        self.nests.removeAll(keepCapacity: false)
        self.row.removeAllChildren()
        self.row.removeFromParent()
    }
    
}
