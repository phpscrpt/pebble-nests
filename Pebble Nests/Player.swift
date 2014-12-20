//
//  Player.swift
//  Pebble Nest
//
//  Created by ahmet ertek on 11/1/14.
//  Copyright (c) 2014 Ahmet Ertek. All rights reserved.
//

import Foundation
import SpriteKit

class Player{
    
    var name:          String
    var turn:          Bool
    var board:         Board?
    let game:          Game?
    var autoPlay:      Bool
    var isThirdPerson: Bool
    
    init(game:Game,playerName: String)
    {
        self.turn          = false
        self.name          = playerName
        self.game          = game
        self.autoPlay      = false
        self.isThirdPerson = false
        
        self.setTurn(false)
        
    }
    
    convenience init(game:Game)
    {
        self.init(game:game,playerName: "Computer")
    }
    
    func setBoard(boardPosition: CGPoint,nestId:Int)
    {
        self.board = Board(position: boardPosition, player: self, label: self.name)
        self.board?.locateNests(count: 5,nestId: nestId)
        
    }
    
    func opponent()->Player?
    {
        return self.game?.opponentOf(self)
    }
    
    func setTurn(turnStatus: Bool)
    {
        turn = turnStatus
        
        if turn
        {
            self.declarePlaying()
            self.game?.activePlayer = self
        }
        else
        {
            self.declareNotPlaying()
        }
    }
    
    func playRandom() ->Bool
    {
        var listOk:[Nest] = []
        for n in self.board!.nests as [Nest]
        {
            if (n.pebbles.count > 0 && !n.isMain && n.enabled )
            {
                listOk.append(n)
            }
        }
        
        if( listOk.count > 0 )
        {
            
            var selectedNest:Nest
            
            if( self.game?.smartPlay === false )
            {
                let randomIndex = Int(arc4random_uniform(UInt32(listOk.count)))
                selectedNest = listOk[randomIndex]
            }
            else
            {
                selectedNest = self.selectSmart(listOk)
            }
            
            let waitAction = SKAction.waitForDuration(1)
            selectedNest.image.runAction(waitAction, completion:{
                
                //--- we need to assign the return value, otherwise completion complains --
                let turnFinished = self.playTurn(selectedNest)
            })
            
            return true
            
        }
        else
        {
            return false
        }
    }
    
    func pebbleCount()->Int
    {
        var countPebbes = 0
        let playables   = self.board?.playableNests()
        
        for n in playables! as [Nest]
        {
            countPebbes += n.pebbles.count
        }
        
        return countPebbes
    }
    
    func maxNestId()->Int
    {
        var minValue  = 0
        var maxNestId = 0
        for n in self.board?.nests as [Nest]!
        {
            if( n.nestId > minValue )
            {
                maxNestId = n.nestId
                minValue  = maxNestId
            }
        }
        
        return maxNestId
    }
    
    func aboutToFinish()->Bool
    {
        let playables       = self.board?.playableNests()
        let criticalNestId  = self.maxNestId()-1
        
        if( playables?.count <= 2 && playables?.filter({$0.nestId == criticalNestId || $0.nestId == criticalNestId - 1}).count > 0 )
        {
            //NSLog("Attacking...")
            return true
        }
        else
        {
            //NSLog("NOT EQUAL TO %d",self.maxNestId()-1)
            return false
        }
    }
    
    func willFinish()->Bool
    {
        if( self.pebbleCount() <= 3 && self.board?.playableNests().count <= 2  )
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    func nest(nestId:Int)->Nest
    {
        let filterNests = self.board?.nests.filter({$0.nestId==nestId})
        return filterNests![0]
    }
    
    func specialCase()->Int?
    {
        let maxNestId      = self.maxNestId()
        let playablesCount = self.board?.playableNests().count
        
        if( playablesCount! == 2 && self.pebbleCount() <= 3 )
        {
            return 0
        }
        else if( playablesCount! == 2 && self.nest(maxNestId-1).pebbles.count <= 2 && self.nest(maxNestId-3).pebbles.count == 1)
        {
            return 0
        }
        else if( playablesCount! == 2 && self.nest(maxNestId-2).pebbles.count <= 2 && self.nest(maxNestId-3).pebbles.count == 1)
        {
            return 0
        }
        else
        {
            return nil
        }
        
    }
    
    func selectSmart(playableNests:[Nest])->Nest
    {
        
        var maxToCompare:Int = 50
        var minToCompare:Int = 0
        var indFound:Int = -1
        
        if let indTemp = self.specialCase()
        {
            indFound = indTemp
        }
        else if( !self.willFinish() && self.opponent()!.aboutToFinish() )
        {
            for(var i=0; i<playableNests.count; i++)
            {
                let counts  = self.playFakeTurn(playableNests[i])
                let opCount = counts.1
                
                if  opCount >= minToCompare
                {
                    indFound = i
                    minToCompare = opCount
                }
            }
            
        }
        else
        {
            let chance = Int(arc4random_uniform(UInt32(10)))
            
            if( chance != 1 )
            {
                for(var i=0; i<playableNests.count; i++)
                {
                    let counts  = self.playFakeTurn(playableNests[i])
                    let nCount = counts.0
                    
                    if  nCount < maxToCompare
                    {
                        indFound = i
                        maxToCompare = nCount
                    }
                }
            }
            else
            {
                //NSLog("playing by chance...")
            }
        }
        
        
        if( indFound >= 0 )
        {
            return playableNests[indFound]
        }
        else
        {
            let randomIndex = Int(arc4random_uniform(UInt32(playableNests.count)))
            return playableNests[randomIndex]
        }
    }
    
    func declarePlaying()
    {
        let label:SKLabelNode?   = self.board?.row.childNodeWithName("playerName") as? SKLabelNode
        
        if let playerLabel = label
        {
            label!.text="\(self.name) play"
            
            if( self.isThirdPerson )
            {
                label!.text += "s"
            }
            
            label!.text += "..."
            
        }
        
    }
    
    func declareNotPlaying()
    {
        let label:SKLabelNode?   = self.board?.row.childNodeWithName("playerName") as? SKLabelNode
        
        if let playerLabel = label
        {
            label!.text  = self.name
        }
    }
    
    func declareAsWinner()->String
    {
        var t = "\(self.name) win"
        
        if( self.isThirdPerson )
        {
            t += "s"
        }
        
        t += "!"
        
        let label:SKLabelNode?   = self.board?.row.childNodeWithName("playerName") as? SKLabelNode
        if let playerLabel = label
        {
            label!.text = t
        }
        
        return t
        
    }
    
    func won()->Bool
    {
        if let activeNests:[Nest]? = self.board?.nests.filter({$0.enabled && !$0.isMain})
        {
            if( activeNests!.count > 0 )
            {
                return false
            }
            else
            {
                return true
            }
        }
        else
        {
            return true
        }
    }
    
    func playTurn(activeNest:Nest) -> Bool
    {
        
        if let playerBoard = self.board
        {
            var activePebbles = activeNest.pebbles
            
            if( activePebbles.count == 0 )
            {
                return false
            }
            else
            {
                //---- remove the pulse action from playable pebbles --
                self.board?.stabilizeNests()
                
                var nestChain: [Nest] = []
                nestChain += playerBoard.nests.filter({$0.enabled})
                
                let opponent:Player = self.opponent()!
                nestChain += opponent.board!.nests.reverse().filter({$0.enabled})
                
                self.playNest(activeNest,nestChain: nestChain)
                
                return true
            }
        }
        else
        {
            return false
        }
    }
    
    func playNest(activeNest:Nest,nestChain: [Nest]) -> Void
    {
        if( !activeNest.isEmpty() )
        {
            self.game?.status = GameStatus.PLAYING
            activeNest.movePebblesAndBlink(nestChain,currentPlayer:self)
        }
        else
        {
            //NSLog("NEST WAS EMPTY MAN !")
        }
        
    }
    
    func playFakeTurn(activeNest:Nest) -> (Int,Int)
    {
        
        if let playerBoard = self.board
        {
            var activePebbles = activeNest.pebbles
            
            if( activePebbles.count == 0 )
            {
                return (0,0)
            }
            else
            {
                let opponent = self.opponent()!
                
                var nestChain: [Nest] = []
                nestChain += playerBoard.nests.filter({$0.enabled})
                
                nestChain += opponent.board!.nests.reverse().filter({$0.enabled})
                
                var nestPebbles:[Int:Int] = [:]
                
                for(var j=0; j<nestChain.count; j++)
                {
                    nestPebbles[j] = nestChain[j].pebbles.count
                }
                
                return self.playFakeNest(nestChain,activeNest:activeNest,nestPebbles: nestPebbles)
                
            }
        }
        else
        {
            return (0,0)
        }
    }
    
    func playFakeNest(nestChain:[Nest],activeNest:Nest,var nestPebbles: [Int:Int]) -> (Int,Int)
    {
        var nextInd = activeNest.nextIndexInChain(nestChain)
        let currInd = activeNest.indexInChain(nestChain)
        let pc      = nestPebbles[currInd!]
        
        nestPebbles[currInd!] = 0
        var nextIndTemp = nextInd!
        
        for(var i=0; i<pc!; i++)
        {
            nextIndTemp = (nextInd! + i) % nestPebbles.count
            nestPebbles[nextIndTemp]! += 1
        }
        
        let nextNest = nestChain[nextIndTemp]
        
        if( !nextNest.isMain && nestPebbles[nextIndTemp]! > 1 )
        {
            return self.playFakeNest(nestChain,activeNest:nextNest,nestPebbles: nestPebbles)
        }
        else
        {
            var fakeNestCount   = 0
            var fakeNestOpCount = 0
            for n in self.board!.nests.filter({$0.enabled && !$0.isMain}) as [Nest]
            {
                for( var i=0; i<nestChain.count; i++ )
                {
                    if( nestChain[i].nestId == n.nestId && !nestChain[i].isMain && nestPebbles[i]! > 0 )
                    {
                        fakeNestCount++
                    }
                }
            }
            
            for n in self.opponent()!.board!.nests.filter({$0.enabled && !$0.isMain}) as [Nest]
            {
                for( var i=0; i<nestChain.count; i++ )
                {
                    if( nestChain[i].nestId == n.nestId && !nestChain[i].isMain && nestPebbles[i]! > 0 )
                    {
                        fakeNestOpCount++
                    }
                }
            }
            
            nestPebbles.removeAll(keepCapacity: false)
            return (fakeNestCount,fakeNestOpCount)
        }
        
    }
    
    func closeNest()
    {
        let nests = self.board?.nests.filter({!$0.isMain && $0.enabled})
        
        if let temp = nests
        {
            if( nests!.count > 0 )
            {
                let nest = nests!.first
                nest!.disable()
                nest!.image.texture = SKTexture(imageNamed: "nestClosed")
                nest!.pebbles.map({$0!.hidden=true})
                //nest!.pebbles.map({$0.removeFromParent()})
                /*
                nest!.image.colorBlendFactor = 1.0
                nest!.image.color            = SKColor.blackColor()
                */
            }
        }
    }
    
    func finishedNests()->Bool
    {
        var count = 0
        let nests = self.board!.nests.filter({$0.enabled && !$0.isMain})
        for nest in nests
        {
            if( !nest.isEmpty() )
            {
                count++
            }
        }
        
        if( count == 0 )
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    func playPebbles(var pebbles: [SKSpriteNode],chain: [Nest],activeNest:Nest)
    {
        let pebble      = pebbles.last!
        let ni          = activeNest.nextIndexInChain(chain)
        let destNest    = chain[ni!]
        
        let tray        = self.game?.tray
        let newLoc      = pebble.convertPoint(destNest.image.position,fromNode:destNest.image.parent!)
        let moveAction  = SKAction.moveTo(newLoc,duration: self.game!.moveDuration)
        
        
        pebble.runAction(moveAction,completion:{
            
            if self.game?.audio == true
            {
                let pebbleSound = self.game?.gameScene.getSound(GameActions.movePebbleSound.name())
                pebble.runAction(pebbleSound!)
            }
            
            pebble.removeFromParent()
            pebbles.removeLast()
            
            destNest.acceptPebble(pebble)
            destNest.organizePebbles()
            destNest.printPebbleCount()
            
            if( pebbles.count > 0 )
            {
                self.playPebbles(pebbles,chain:chain,activeNest: destNest)
            }
            else
            {
                if( destNest.canContinue() )
                {
                    self.playNest(destNest,nestChain:chain)
                }
                else
                {
                    self.checkTurnPassOrWinner()
                }
                
                //activeNest.image.colorBlendFactor = 0.0
                //activeNest.image.color            = SKColor.grayColor()
                
            }
            
        })
    }
    
    func checkTurnPassOrWinner()
    {
        
        if( self.finishedNests() )
        {
            self.game?.restoreNests()
            self.closeNest()
            self.game?.playClosedNestSound()
            
            if( self.won() )
            {
                self.game?.over(self)
            }
            else
            {
                if( self.autoPlay )
                {
                    self.playRandom()
                }
                else
                {
                    self.willPlayManually()
                }
            }
        }
        else if( self.opponent()!.finishedNests() )
        {
            self.game?.restoreNests()
            
            let opponent = self.opponent()!
            opponent.closeNest()
            self.game?.playClosedNestSound()
            
            if( opponent.won() )
            {
                self.game?.over(opponent)
            }
            else
            {
                if( opponent.autoPlay )
                {
                    opponent.playRandom()
                }
                else
                {
                    //NSLog("player caused the opponent to finish nests.Opponent will touch to continue:")
                    opponent.willPlayManually()
                }
            }
        }
        else
        {
            if self.game?.audio == true
            {
                let turnEnd = self.game?.gameScene.getSound(GameActions.turnEnd.name())
                self.game?.gameScene.runAction(turnEnd)
            }
            
            self.setTurn(false)
            let opponent = self.opponent()!
            opponent.setTurn(true)
            
            if( opponent.autoPlay )
            {
                opponent.playRandom()
            }
            else
            {
                //NSLog("Opponent needs to touch to continue playing:")
                opponent.willPlayManually()
            }
        }
        
    }
    
    func willPlayManually()
    {
        //---- pulse pebbles in playable nests --
        self.board?.unstabilizeNests()
        self.game?.status = GameStatus.WAITING
        
    }
    
    func findNestWithSprite(sprite: SKSpriteNode)->Nest?
    {
        let nests = self.board?.nests.filter({ !$0.isMain && $0.enabled && !$0.isEmpty() })
        
        if let temp = nests
        {
            if( nests!.count > 0 )
            {
                for nest in nests!
                {
                    if nest.image === sprite
                    {
                        return nest
                    }
                }
            }
        }
        
        return nil
    }
    
    func clonePlayer()->Player
    {
        var p = Player(game: self.game!)
        
        p.board = Board(position: CGPointZero, player: p, label: p.name)
        p.board?.locateNests(count: 5,nestId: 1)
        
        return p
    }
    
    deinit
    {
        self.board=nil
        self.name=""
    }
    
}
