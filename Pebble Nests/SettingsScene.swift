
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
    @IBOutlet var modeSegmentedControl : UISegmentedControl?
    var thisDelegate: SettingsSceneDelegate?
    
    override func didMoveToView(view: SKView) {
        
        //---- default settings that were saved previously ----
        let gameSettings = NSUserDefaults.standardUserDefaults()
        
        //--------- SETTINGS BOARD ------------------------
        
        let fw = view.frame.width
        let fh = view.frame.height
        let boardSize = CGSize(width:fw*4/5,height:fh/2)
        
        let settingsBoard = SKView(frame: CGRect(origin: CGPoint(x:fw/10,y:fh/5),size:boardSize))
        settingsBoard.backgroundColor = UIColor.brownColor()
        
        //---- scene name --
        
        let sceneLabel       = self.sceneLabel(CGRectMake(5.0, 20.0, settingsBoard.frame.width-20, 30))
        settingsBoard.addSubview(sceneLabel)
        
        
        //--- GAME MODE PICKER ---------------------------
        
        //let modeLabel  = self.fieldLabel(CGRectMake(0.0, 70.0, 50.0, 30),text:"Mode:")
        //settingsBoard.addSubview(modeLabel)
        
        let pickerFrame   = CGRectMake(5, 70, settingsBoard.frame.width-10, 30)
        let modePicker    = self.modePicker(pickerFrame)
        
        if ( gameSettings.objectForKey("mode") != nil )
        {
            modePicker.selectedSegmentIndex = gameSettings.integerForKey("mode")
        }
        
        settingsBoard.addSubview(modePicker)
        self.modeSegmentedControl = modePicker
        
        
        //------- SWITCH AUDIO BUTTON ----------------------
        
        let switchLabel  = self.fieldLabel(CGRectMake(5.0, 110.0, 50, 30.0),text:"Audio:")
        settingsBoard.addSubview(switchLabel)
        
        let switchFrame   = CGRectMake(70.0, 110, 50.0, 30)
        let swButton      = UISwitch(frame:switchFrame)
        swButton.setOn(true, animated: false)
        swButton.addTarget(self, action: "audioButtonAction", forControlEvents: UIControlEvents.ValueChanged)
        
        if ( gameSettings.objectForKey("audio") != nil)
        {
            swButton.on = gameSettings.boolForKey("audio")
        }
        
        settingsBoard.addSubview(swButton)
        self.switchButton = swButton
        
        //---- OK BUTTON ---------------------------------
        
        let leftMargin = view.bounds.width/4
        let topMargin:CGFloat  = 150.0
        let okButton   = self.okButton(CGRectMake(leftMargin, topMargin,100,50))
        settingsBoard.addSubview(okButton)
        
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
    
    func modePicker(frame:CGRect)->UISegmentedControl
    {
        let modeOptions:[String] = ["CompXHuman","CompXComp","HumanXHuman"]
        let picker = UISegmentedControl(items: modeOptions)
        picker.frame = frame
        //set the style for the segmented control
        picker.selectedSegmentIndex = 0
        
        let font:UIFont = UIFont.boldSystemFontOfSize(10.0)
        let attributes:NSDictionary  = NSDictionary(object:font,forKey:NSFontAttributeName)
        picker.setTitleTextAttributes(attributes,forState:UIControlState.Normal)
        
        picker.addTarget(self,action:"modeChanged:",forControlEvents:UIControlEvents.ValueChanged)
        
        return picker
    }
    
    func okAction(sender:UIButton!)
    {
        if sender!.currentTitle=="OK"
        {
            // close ReplayScene and start the game again
            self.thisDelegate!.settingsOk(self, command: "SettingsOk")
        }
    }
    
    func modeChanged(sender : UISegmentedControl)
    {
        let gameSettings = NSUserDefaults.standardUserDefaults()
        gameSettings.setInteger(Int(sender.selectedSegmentIndex),forKey:"mode")
        
        let modeMessage = "This will take effect next time you start a game!"
        
        // Create the alert controller
        var alertController = UIAlertController(title: "Game Mode Changed!", message: modeMessage, preferredStyle: .Alert)
        
        // Create the actions
        var okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
            UIAlertAction in
            //NSLog("OK Pressed")
        }
        
        
        // Add the actions
        alertController.addAction(okAction)
        
        // Present the controller
        self.view?.window?.rootViewController!.presentViewController(alertController, animated: true, completion: nil)
    }
    
    deinit
    {
        self.switchButton = nil
        self.modeSegmentedControl = nil
        self.thisDelegate = nil
    }
    
}
