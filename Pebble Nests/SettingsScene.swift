
//
//  SettingsScene.swift
//  Pebble Nest
//
//  Created by ahmet ertek on 11/1/14.
//  Copyright (c) 2014 Ahmet Ertek. All rights reserved.
//

import SpriteKit
import UIKit

protocol SettingsSceneDelegate
{
    func settingsOk(myScene:SettingsScene,command:String)
}

class SettingsScene: SKScene {
    
    var switchButton:UISwitch?
    var thisDelegate: SettingsSceneDelegate?
    
    override func didMoveToView(view: SKView) {
        
        
        //--------- SETTINGS BOARD ------------------------
        
        let fw = view.frame.width
        let fh = view.frame.height
        let boardSize = CGSize(width:fw*4/5,height:fh/2)
        
        let settingsBoard = SKView(frame: CGRect(origin: CGPoint(x:fw/10,y:fh/5),size:boardSize))
        settingsBoard.backgroundColor = UIColor.brownColor()
        
        //---- scene name --
        
        let sceneLabel       = self.sceneLabel(CGRectMake(0, 20, settingsBoard.frame.width-20, 30))
        settingsBoard.addSubview(sceneLabel)
        
        //---- buttons ----
        
        //------- SWITCH AUDIO BUTTON ----------------------
        
        let switchFrame   = CGRectMake(100.0, (boardSize.height/2 - 30), 50.0, 25.0)
        let swButton      = UISwitch(frame:switchFrame)
        swButton.setOn(true, animated: false)
        swButton.addTarget(self, action: "audioButtonAction", forControlEvents: UIControlEvents.ValueChanged)
        
        let gameSettings = NSUserDefaults.standardUserDefaults()
        if ( gameSettings.objectForKey("audio") != nil)
        {
            swButton.on = gameSettings.boolForKey("audio")
        }
        
        let switchLabel  = self.fieldLabel(CGRectMake(10.0, (boardSize.height/2 - 30), 100.0, 25.0),text:"Audio:")
        settingsBoard.addSubview(switchLabel)
        
        settingsBoard.addSubview(swButton)
        self.switchButton = swButton
        
        //---- OK BUTTON ---------------------------------
        
        let leftMargin = view.bounds.width/4
        let topMargin  = view.bounds.height/5
        let okButton   = self.okButton(CGRectMake(leftMargin, topMargin + 30,100,50))
        settingsBoard.addSubview(okButton)
        
        //--- GAME MODE PICKER ---------------------------
        
        let modeLabel  = self.fieldLabel(CGRectMake(10.0, (boardSize.height/2 - 30), 100.0, 25.0),text:"Game Mode:")
        settingsBoard.addSubview(modeLabel)
        
        
        let pickerFrame   = CGRectMake(100.0, 60, 100.0, 25.0)
        let modePicker    = self.modePicker(pickerFrame)
        settingsBoard.addSubview(modePicker)
        
        view.addSubview(settingsBoard)
        
        
    }
    
    func audioButtonAction()
    {
        
        let gameSettings = NSUserDefaults.standardUserDefaults()
        
        if ( self.switchButton!.on.boolValue )
        {
            gameSettings.setBool(true,forKey:"audio")
        }
        else
        {
            gameSettings.setBool(false,forKey:"audio")
        }
    }
    
    func sceneLabel(labelFrame:CGRect)->UILabel
    {
        let sceneLabel       = UILabel(frame: labelFrame)
        sceneLabel.font      = UIFont(name: "Futura", size: 20)
        sceneLabel.textColor = SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        sceneLabel.text      = "Pebble Nest - Game Settings"
        sceneLabel.tag       = 11
        sceneLabel.textAlignment    = .Center
        sceneLabel.adjustsFontSizeToFitWidth = true
        
        return sceneLabel
    }
    
    func fieldLabel(labelFrame:CGRect,text:String)->UILabel
    {
        let sceneLabel       = UILabel(frame: labelFrame)
        sceneLabel.font      = UIFont(name: "Futura", size: 20)
        sceneLabel.textColor = SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        sceneLabel.text      = text
        sceneLabel.tag       = 12
        sceneLabel.textAlignment    = .Center
        sceneLabel.adjustsFontSizeToFitWidth = true
        
        return sceneLabel
    }
    
    func okButton(buttonFrame:CGRect)->UIButton
    {
        let okButton    = UIButton.buttonWithType(UIButtonType.Custom) as UIButton
        okButton.frame  = buttonFrame
        
        let btnImage = UIImage(contentsOfFile: "okButton.png")
        okButton.setBackgroundImage(btnImage, forState:UIControlState.Normal)
        
        //okButton.backgroundColor = UIColor.clearColor()
        okButton.setTitle("OK", forState: UIControlState.Normal)
        okButton.titleLabel!.font =  UIFont(name: "Futura", size: 20)
        okButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        okButton.addTarget(self, action: "okAction:",forControlEvents: UIControlEvents.TouchDown)
        okButton.setNeedsLayout()
        
        return okButton
    }
    
    func modePicker(frame:CGRect)->UIPickerView
    {
        let picker = UIPickerView(frame: frame)
        
        
        return picker
    }
    
    func okAction(sender:UIButton!) {
        if sender!.currentTitle=="OK"
        {
            // close ReplayScene and start the game again
            self.thisDelegate!.settingsOk(self, command: "SettingsOk")
        }
    }
    
}
