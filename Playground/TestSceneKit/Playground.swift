//
//  Playground.swift
//  TestSceneKit
//
//  Created by Justin Fincher on 2017/3/25.
//  Copyright © 2017年 Justin Fincher. All rights reserved.
//

import Foundation
//: Golf GO ⛳
//: Build 4

import UIKit
import GameplayKit
import SceneKit
import SceneKit.ModelIO
import SpriteKit
import ModelIO

let GAME_DEBUG_MODE_ON : Bool = false
let XCODE_BEHAVIOR_IPHONE : Bool = true
let GOLF_SITE_SQUARE_MESH_SEGMENTS_COUNT : Int = 149
let GOLF_SITE_SQUARE_MESH_SIZE : Float = 16000.0
let GOLF_SITE_HEIGHT_MULTIPIER : Float = 0.1
let NOISE_SAMPLE_COUNT : Int = 1024
let NOISE_SAMPLE_SIZE : Double = 800.0
let NOTIFICATION_GAME_ASSET_PROCESS_START : String = "NOTIFICATION_GAME_ASSET_PROCESS_START"
let NOTIFICATION_GAME_ASSET_PROCESS_END : String = "NOTIFICATION_GAME_ASSET_PROCESS_END"
let NOTIFICATION_GAME_VIEW_PINCH_GESTURE : String = "NOTIFICATION_GAME_VIEW_PINCH_GESTURE"
let NOTIFICATION_BUTTON_STATE_CHANGED : String = "NOTIFICATION_BUTTON_STATE_CHANGED"
let NOTIFICATION_GOLF_HIT_HOLE : String = "NOTIFICATION_GOLF_HIT_HOLE"



// MARK: - Utility
extension Array where Element: AnyObject {
    mutating func remove(object: Element) {
        if let index = index(where: { $0 === object }) {
            remove(at: index)
        }
    }
}
extension SCNVector3
{
    func length() -> Float {
        return sqrtf(x*x + y*y + z*z)
    }
}
extension Int {
    var degreesToRadians: Double { return Double(self) * .pi / 180 }
}
extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}
func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}
func += ( left: inout SCNVector3, right: SCNVector3) {
    left = left + right
}
func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
}
func -= ( left: inout SCNVector3, right: SCNVector3) {
    left = left - right
}
func * (vector: SCNVector3, scalar: Float) -> SCNVector3 {
    return SCNVector3Make(vector.x * scalar, vector.y * scalar, vector.z * scalar)
}

class JZHelper
{
    static func UIColorFromHex (hex:String) -> UIColor {
        let cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    static func randomBetweenNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat{
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
}

// MARK: - Data Model
class JZNoiseMapManager
{
    static let sharedInstance = JZNoiseMapManager()
    var noiseMap : GKNoiseMap! = GKNoiseMap()
    var noiseImage : UIImage! = UIImage()
    init()
    {
        
    }
    
    func generateNoiseMap() -> Void
    {
        let noiseSource : GKBillowNoiseSource = GKBillowNoiseSource(frequency: Double(JZHelper.randomBetweenNumbers(firstNum: 0.005, secondNum: 0.01)), octaveCount: Int(JZHelper.randomBetweenNumbers(firstNum: 5, secondNum: 10)), persistence: Double(JZHelper.randomBetweenNumbers(firstNum: 0.2, secondNum: 0.5)), lacunarity: Double(JZHelper.randomBetweenNumbers(firstNum: 0.5, secondNum: 2.0)), seed: Int32(JZHelper.randomBetweenNumbers(firstNum: 0, secondNum: 1024)))
        let noise : GKNoise = GKNoise(noiseSource, gradientColors: [-1.0 : JZHelper.UIColorFromHex(hex: "2F971C"), -0.5 : JZHelper.UIColorFromHex(hex: "5CA532") ,-0.0 : JZHelper.UIColorFromHex(hex: "DFED8B"), 0.6 : JZHelper.UIColorFromHex(hex: "A9A172"), 0.8 : JZHelper.UIColorFromHex(hex: "A9A172"), 1.0 : UIColor.white])
        noiseMap = GKNoiseMap(noise, size: vector2(NOISE_SAMPLE_SIZE,NOISE_SAMPLE_SIZE), origin: vector2(0, 0), sampleCount: vector2(Int32(NOISE_SAMPLE_COUNT), Int32(NOISE_SAMPLE_COUNT)), seamless: true)
        let noiseTexture : SKTexture = SKTexture(noiseMap: noiseMap)
        noiseImage = UIImage(cgImage: noiseTexture.cgImage())
    }
}
class JZSceneManager : NSObject,SCNPhysicsContactDelegate
{
    static let sharedInstance = JZSceneManager()
    
    var scene : JZPlayerScene?
    var sceneView : JZPlayerSceneView?
    var gameMenuView : JZGameMenuView?
    
    var goList : [JZGameObject]
    
    override init()
    {
        goList = [JZGameObject]()
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact)
    {
        let nodes = [contact.nodeA, contact.nodeB]
        if (nodes.contains((scene?.golfBallGameObject.node)!) && nodes.contains((scene?.holeGameObject.node)!))
        {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: NOTIFICATION_GOLF_HIT_HOLE), object: nil)
        }
    }
    
    
    
    func processNewGameAssets() -> Void
    {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NOTIFICATION_GAME_ASSET_PROCESS_START), object: nil)
        OperationQueue().addOperation(
            {
                JZNoiseMapManager.sharedInstance.generateNoiseMap()
                
                let sceneToLoad : JZPlayerScene = JZPlayerScene()
                self.scene? = sceneToLoad
                self.scene?.physicsWorld.contactDelegate = self
                self.sceneView?.scene = self.scene
                
                let directLight : JZGameObject = JZGameObject()
                directLight.node.light = SCNLight()
                directLight.node.light?.type = SCNLight.LightType.directional
                directLight.node.light?.color = UIColor.white
                directLight.node.light?.castsShadow = true
                directLight.eulerAngles = SCNVector3(-30.degreesToRadians,0,0)
                directLight.position = SCNVector3(0,400,0)
                directLight.node.light?.intensity = 2000
                self.scene?.directLightGameObject = directLight
                self.scene?.rootNode.addChildNode(directLight.node)
                
                let areaLight : JZGameObject = JZGameObject()
                areaLight.node.light = SCNLight()
                areaLight.node.light?.type = SCNLight.LightType.ambient
                areaLight.node.light?.color = UIColor.white
                areaLight.position = SCNVector3(0,40,0)
                areaLight.node.light?.intensity = 500
                self.scene?.areaLightGameObject = areaLight
                self.scene?.rootNode.addChildNode(areaLight.node)
                
                self.scene?.cameraGameObject = JZCameraGameObject()
                self.scene?.rootNode.addChildNode((self.scene?.cameraGameObject.node)!)
                self.sceneView?.pointOfView = self.scene?.cameraGameObject.node
                
                self.scene?.golfSiteGameObject = JZGolfSiteGameObject()
                self.scene?.rootNode.addChildNode((self.scene?.golfSiteGameObject.node)!)
                
                self.scene?.skylineGameObject = JZSkylineGameObject()
                self.scene?.rootNode.addChildNode((self.scene?.skylineGameObject.node)!)
                
                self.scene?.golfBallGameObject = JZGolfBallGameObject()
                self.scene?.rootNode.addChildNode((self.scene?.golfBallGameObject.node)!)
                
                self.scene?.directionArrow = JZGolfDirectionArrow()
                self.scene?.directionArrow.golfGameObject = self.scene?.golfBallGameObject
                self.scene?.golfBallGameObject.addChildNode(go: (self.scene?.directionArrow)!)
                
                self.scene?.golfBallGameObject.delegate = self.sceneView?.startBallButton
                
                self.scene?.holeGameObject = JZGolfHoleGameObject()
                self.scene?.golfSiteGameObject.addChildNode(go: (self.scene?.holeGameObject)!)
                
                self.setSkyboxTexture()
                
                OperationQueue.main.addOperation
                    {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NOTIFICATION_GAME_ASSET_PROCESS_END), object: nil)
                }
        })
        
    }
    
    func setSkyboxTexture() -> Void
    {
        let skyboxTexture : MDLSkyCubeTexture = MDLSkyCubeTexture(name: "skybox", channelEncoding: .uInt8, textureDimensions: vector2(256, 256), turbidity: 0.2, sunElevation: 0.7, upperAtmosphereScattering: 0.4, groundAlbedo: 1.0)
        self.scene?.background.contents = skyboxTexture.imageFromTexture()?.takeRetainedValue()
    }
    
    
}

// MARK: - Data Model For GameObject
class JZGameObject
{
    let node : JZSCNNode
    let entity : JZGKEntity
    
    var name : String { get { return node.name! } set { node.name = newValue } }
    var transfrom : SCNMatrix4 { get { return node.transform } set { node.transform = newValue } }
    var position : SCNVector3 { get { return node.position } set { node.position = newValue } }
    var scale : SCNVector3 { get { return node.scale } set { node.scale = newValue } }
    var eulerAngles : SCNVector3 { get { return node.eulerAngles } set { node.eulerAngles = newValue } }
    var components : [GKComponent] { get { return entity.components } }
    var physicsBody : SCNPhysicsBody { get { return node.physicsBody! } set { node.physicsBody = newValue }}
    var physicsField : SCNPhysicsField { get { return node.physicsField! } set { node.physicsField = newValue }}
    
    var geometry : SCNGeometry { get { return node.geometry! } set { node.geometry = newValue } }
    var isHidde : Bool { get {return node.isHidden } set { node.isHidden = newValue } }
    var opacity : CGFloat { get {return node.opacity } set { node.opacity = newValue } }
    
    var parentNode : SCNNode? { get { return node.parent } }
    var childNodes : [SCNNode] { get { return node.childNodes } }
    
    init()
    {
        node = JZSCNNode()
        entity = JZGKEntity()
        node.gameObject = self
        entity.gameObject = self
        JZSceneManager.sharedInstance.goList.append(self)
    }
    deinit
    {
        JZSceneManager.sharedInstance.goList.remove(object: self)
    }
    
    func addComponent(component: GKComponent) -> Void
    {
        entity.addComponent(component)
    }
    func removeComponent(ofType componentClass: GKComponent.Type) -> Void
    {
        entity.removeComponent(ofType: componentClass)
    }
    func update(deltaTime seconds: TimeInterval)
    {
        entity.update(deltaTime: seconds)
    }
    func addChildNode(go : JZGameObject) -> Void
    {
        node.addChildNode(go.node)
    }
    func addChildNode(nodeToAdd : SCNNode) -> Void
    {
        node.addChildNode(nodeToAdd)
    }
}

class JZSCNNode : SCNNode
{
    weak var gameObject : JZGameObject? = nil
}
class JZGKEntity : GKEntity
{
    weak var gameObject : JZGameObject? = nil
    override func update(deltaTime seconds: TimeInterval)
    {
        super.update(deltaTime: seconds)
        for com in components
        {
            com.update(deltaTime: seconds)
        }
    }
}

// MARK: - Views
class JZStartBallButton : UIVisualEffectView,JZGolfBallGameObjectStatDelegate
{
    enum JZStartBallButtonType: Int {
        case standby = 1
        case choosingFlatDirection = 2
        case choosingVerticalDirection = 3
        case choosingForce = 4
    }
    
    func nodeVelocityUpdate(sender: JZGolfBallGameObject, velocity: SCNVector3)
    {
        //        let isRolling : Bool = (velocity.length() > 1.0)
        //        OperationQueue.main.addOperation {
        //            if (self.isHidden != isRolling)
        //            {
        //                self.isHidden = isRolling
        //            }
        //        }
    }
    
    var currentState : JZStartBallButtonType
    {
        get { return _currentState }
        set
        {
            _currentState = newValue
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: NOTIFICATION_BUTTON_STATE_CHANGED), object: nil, userInfo: ["state":_currentState])
            switch (_currentState)
            {
            case .standby:
                btn.setTitle("Ready", for: .normal)
                break
            case .choosingFlatDirection:
                btn.setTitle("Set Direction", for: .normal)
                break
            case .choosingVerticalDirection:
                btn.setTitle("Set Angle", for: .normal)
                break
            case .choosingForce:
                btn.setTitle("Set Force", for: .normal)
                break
            }
        }
    }
    var _currentState : JZStartBallButtonType = .standby
    let blurEffect : UIBlurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
    let btn : UIButton = UIButton(type: UIButtonType.custom)
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    init(frame : CGRect)
    {
        super.init(effect: blurEffect)
        self.frame = frame
        btn.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        btn.autoresizingMask = [.flexibleBottomMargin,.flexibleHeight,.flexibleLeftMargin,.flexibleRightMargin,.flexibleTopMargin,.flexibleWidth]
        btn.setTitleColor(UIColor.gray, for: .normal)
        btn.addTarget(self, action: #selector(btnPressed), for: .touchUpInside)
        autoresizingMask = [.flexibleBottomMargin,.flexibleHeight,.flexibleLeftMargin,.flexibleRightMargin,.flexibleTopMargin,.flexibleWidth]
        addSubview(btn)
        layer.cornerRadius = 5
        layer.masksToBounds = true
        currentState = .standby
    }
    
    func btnPressed() -> Void
    {
        var nextEnum = currentState.rawValue + 1
        if (nextEnum == 5) { nextEnum = 1 }
        currentState =  JZStartBallButtonType(rawValue: nextEnum)!
    }
    
}
class JZGameMenuView : UIView
{
    weak var controller : JZViewController?
    var blurView : UIVisualEffectView!
    var startGameIcon : UILabel!
    var loadingIndicator : UIActivityIndicatorView!
    
    required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
    
    required override init(frame: CGRect)
    {
        super.init(frame: frame)
        JZSceneManager.sharedInstance.gameMenuView = self
        baseSetup()
    }
    
    func baseSetup() -> Void
    {
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleTopMargin, .flexibleLeftMargin ,.flexibleRightMargin]
        isUserInteractionEnabled = false
        backgroundColor = UIColor.clear
        
        blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.light))
        blurView.frame = frame
        blurView.autoresizingMask = [.flexibleLeftMargin,.flexibleRightMargin,.flexibleTopMargin,.flexibleBottomMargin,.flexibleHeight,.flexibleWidth]
        addSubview(blurView)
        
        startGameIcon = UILabel(frame: CGRect(x: 20, y: 0, width: bounds.size.width - 40, height: bounds.size.height))
        startGameIcon.text = "GENERATING PROCEDRUAL MAP FOR GOLF GO 😐"
        startGameIcon.numberOfLines = 0
        startGameIcon.font = UIFont.systemFont(ofSize: 26, weight: 10)
        startGameIcon.textAlignment = .center
        addSubview(startGameIcon)
        startGameIcon.autoresizingMask = [.flexibleLeftMargin,.flexibleRightMargin,.flexibleTopMargin,.flexibleBottomMargin,.flexibleWidth,.flexibleHeight]
        
        loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        addSubview(loadingIndicator)
        loadingIndicator.frame.origin = CGPoint(x: frame.size.width / 2.0, y: frame.size.height - 100)
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.autoresizingMask = [.flexibleHeight,.flexibleWidth]
        
        NotificationCenter.default.addObserver(self, selector: #selector(onGameAssetProcessStart(notif:)), name: NSNotification.Name(rawValue: NOTIFICATION_GAME_ASSET_PROCESS_START), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onGameAssetProcessEnd(notif:)), name: NSNotification.Name(rawValue: NOTIFICATION_GAME_ASSET_PROCESS_END), object: nil)
    }
    
    func onGameAssetProcessStart(notif:Notification) -> Void
    {
        self.controller?.navigationController?.setNavigationBarHidden(true, animated: true)
        UIView.animate(withDuration: 0.5, animations: { self.alpha = 1.0 }, completion: { (finished) -> Void in
            self.loadingIndicator.startAnimating()
        })
    }
    func onGameAssetProcessEnd(notif:Notification) -> Void
    {
        UIView.animate(withDuration: 0.5, animations: { self.alpha = 0.0 }, completion: { (finished) -> Void in
            self.loadingIndicator.stopAnimating()
            self.controller?.navigationController?.setNavigationBarHidden(false, animated: true)
        })
    }
    
}
class JZPlayerScene : SCNScene
{
    var golfSiteGameObject : JZGolfSiteGameObject!
    var golfBallGameObject : JZGolfBallGameObject!
    var skylineGameObject : JZSkylineGameObject!
    var cameraGameObject : JZCameraGameObject!
    var holeGameObject : JZGolfHoleGameObject!
    
    var directLightGameObject : JZGameObject!
    var areaLightGameObject : JZGameObject!
    
    var directionArrow : JZGolfDirectionArrow!
    
    override init() {
        super.init()
        JZSceneManager.sharedInstance.scene = self
        physicsWorld.speed = 10.0
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
class JZPlayerSceneView : SCNView, SCNSceneRendererDelegate
{
    var pinchGesture : UIPinchGestureRecognizer?
    var startBallButton : JZStartBallButton?
    var holeIndicator : UILabel?
    
    required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
    
    required override init(frame: CGRect)
    {
        super.init(frame: frame)
        JZSceneManager.sharedInstance.sceneView = self
        baseSetup()
    }
    
    override init(frame: CGRect, options: [String : Any]? = nil) { super.init(frame: frame, options: options) }
    
    func baseSetup() -> Void
    {
        self.antialiasingMode = .multisampling2X
        self.showsStatistics = true
        self.backgroundColor = UIColor.green
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleTopMargin, .flexibleLeftMargin ,.flexibleRightMargin]
        self.isPlaying = true
        self.delegate = self
        self.allowsCameraControl = false
        self.autoenablesDefaultLighting = false
        if (GAME_DEBUG_MODE_ON)
        {
            debugOptions = .showPhysicsShapes
        }
        startBallButton = JZStartBallButton(frame: CGRect(x: 40, y: self.frame.height - 120, width: self.frame.width - 80, height: 60))
        addSubview(startBallButton!)
        
        holeIndicator = UILabel(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        holeIndicator?.text = "⏺"
        holeIndicator?.textAlignment = .center
        holeIndicator?.font = UIFont.systemFont(ofSize: 26.0)
        addSubview(holeIndicator!)
        
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(JZPlayerSceneView.handleGesture(gesture:)))
        addGestureRecognizer(pinchGesture!)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval)
    {
        if (JZSceneManager.sharedInstance.scene?.holeGameObject != nil)
        {
            let innerRect = CGRect(x: 20, y: 80, width: frame.width - 40, height: frame.height - 100)
            let go : JZGolfHoleGameObject = (JZSceneManager.sharedInstance.scene?.holeGameObject)!
            let vector = go.node.convertPosition(SCNVector3(0.0,0.0,0.0), to: JZSceneManager.sharedInstance.scene?.rootNode)
            let screenSpacePos = projectPoint(vector)
            let point : CGPoint = CGPoint(x:  CGFloat(screenSpacePos.x) - frame.width / 2, y: CGFloat(screenSpacePos.y) - frame.height / 2 )
            let innerRectPoint : CGPoint = CGPoint(x: point.x, y: point.y - CGFloat(30.0))
            var originToSet : CGPoint? = nil;
            if (abs(innerRectPoint.x) > innerRect.width / 2 || abs(innerRectPoint.y) > innerRect.height / 2)
            {
                let scaleX = innerRectPoint.x / ((innerRectPoint.x > 0) ? (innerRect.width / 2) : (-innerRect.width / 2))
                let scaleY = innerRectPoint.y / ((innerRectPoint.y > 0) ? (innerRect.height / 2) : (-innerRect.height / 2))
                let scale = (scaleX < scaleY) ? scaleY : scaleX
                originToSet = CGPoint(x: bounds.width / 2 + innerRectPoint.x / scale, y: bounds.height / 2 + innerRectPoint.y / scale + CGFloat(30.0))
            }else
            {
                originToSet = CGPoint(x: bounds.width / 2 + point.x, y: bounds.height / 2 + point.y)
            }
            OperationQueue.main.addOperation {
                self.holeIndicator?.frame = CGRect(x: originToSet!.x - CGFloat(20.0), y: originToSet!.y - CGFloat(20.0), width: 40, height: 40)
            }
            
        }
        
        for go in JZSceneManager.sharedInstance.goList
        {
            go.update(deltaTime: time)
        }
    }
    
    func handleGesture(gesture : UIPinchGestureRecognizer) -> Void
    {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NOTIFICATION_GAME_VIEW_PINCH_GESTURE), object: self, userInfo: ["gesture":gesture])
    }
}


// MARK: - Controllers / UI
class JZHelpViewController : UITableViewController
{
    let dataSource : Dictionary<String,String> = ["1. ⛳⛳⛳ What is Golf GO?":"Golf GO is a little game written by ZHENG HAOTIAN (Justin Fincher). It  is built on top of Swift Playground and uses serveral new iOS frameworks and APIs, like SceneKit, ModelIO and GameplayKit.",
                                                  "2. How to play this little game?":"Just smash the ready button and set golf ball direction, angle and force. The ⏺ indicator stands for golf hole, aim for that! If you want to generate another different golf site map, just press the 🔀 button.",
                                                  "3. What's special about this game?":"Golf GO can generate nearly 1 million different maps on runtime because it uses procedrual noise as terrain heightmap.",
                                                  "4. Who is the author?":"ZHENG HAOTIAN (Justin Fincher), currently a junior student in CSU, China. Indie iOS & Unity Developer. More info at https://fincher.im."]
    var keys : Array<String>? = nil
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        keys = Array(dataSource.keys).sorted()
        tableView.allowsSelection = false
        tableView.estimatedRowHeight = 85.0
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        var cell : UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "tableViewCell")
        if (cell == nil)
        {
            cell = UITableViewCell(style: .default, reuseIdentifier: "tableViewCell")
        }
        cell.textLabel?.text = dataSource[(keys?[indexPath.section])!]
        cell.textLabel?.numberOfLines = 0
        return cell
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        return keys?[section]
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}
class JZViewController: UIViewController,UIPopoverPresentationControllerDelegate
{
    var sceneView : JZPlayerSceneView!
    var menuView : JZGameMenuView!
    override func viewDidLoad()
    {
        super.viewDidLoad()
        if (!XCODE_BEHAVIOR_IPHONE)
        {
            self.preferredContentSize = self.view.frame.size
        }
        self.title = "⛳ GOLF GO"
        
        menuView = JZGameMenuView(frame: self.view.frame)
        menuView.controller = self
        sceneView = JZPlayerSceneView(frame: self.view.frame)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "🤔", style: .plain, target: self, action: #selector(rightBarButtonPressed(_:)))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "🔀", style: .plain, target: self, action: #selector(leftBarButtonPressed(_:)))
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        NotificationCenter.default.addObserver(self, selector: #selector(onBallIntoHole(notification:)), name: NSNotification.Name(rawValue: NOTIFICATION_GOLF_HIT_HOLE), object: nil)
        
        self.view.addSubview(sceneView)
        self.view.addSubview(menuView)
        JZSceneManager.sharedInstance.processNewGameAssets()
    }
    func leftBarButtonPressed(_ sender : UIBarButtonItem) -> Void
    {
        let alert = UIAlertController(title: "Regenerate level?", message: "Golf GO uses procedrually generated noise map to generate golf site level. This would take a while (about 20 sec)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel 😶", style: .cancel) { _ in
        })
        alert.addAction(UIAlertAction(title: "Go Ahead 🙃", style: .default) { _ in
            JZSceneManager.sharedInstance.processNewGameAssets()
        })
        present(alert, animated: true)
    }
    
    func rightBarButtonPressed(_ sender : UIBarButtonItem) -> Void
    {
        let helpVC : JZHelpViewController = JZHelpViewController(style: .grouped)
        helpVC.title = "Need Help? 🤣"
        let naviVC : UINavigationController = UINavigationController(rootViewController: helpVC)
        naviVC.modalPresentationStyle = UIModalPresentationStyle.popover
        let popoverPresentationViewController : UIPopoverPresentationController = naviVC.popoverPresentationController!
        popoverPresentationViewController.permittedArrowDirections = .any
        popoverPresentationViewController.delegate = self
        popoverPresentationViewController.sourceView = self.view;
        popoverPresentationViewController.barButtonItem = sender
        var frame:CGRect = (sender.value(forKey: "view") as! UIView).frame
        frame.origin.y = frame.origin.y+20
        popoverPresentationViewController.sourceRect = frame
        
        present(naviVC, animated: true, completion: nil)
    }
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.none
    }
    func onBallIntoHole(notification:Notification) -> Void
    {
        let alert = UIAlertController(title: "Yeah 🎉🎉🎉", message: "You hit the golf ball into the hole! 🆒", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "🏌️‍♀️ Again! 🏌️", style: .default) { _ in
            JZSceneManager.sharedInstance.processNewGameAssets()
        })
        present(alert, animated: true)
    }
    
    
}
class JZNaviController: UINavigationController
{
    override func viewDidLoad()
    {
        view.backgroundColor = UIColor.white
    }
}
// MARK: - Controllers / Game
class JZGolfHoleGameObject : JZGameObject
{
    override init()
    {
        super.init()
        setup()
    }
    func setup() -> Void
    {
        geometry = SCNTorus(ringRadius: 50, pipeRadius: 20)
        physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        physicsBody.contactTestBitMask = 1
        let min : Int = (Int)(Float(NOISE_SAMPLE_COUNT) / 3.0)
        let max : Int = (Int)(Float(NOISE_SAMPLE_COUNT) * 2.0 / 3.0)
        var (fx,fy) = (0,0)
        var noiseValue : Float = 1.0
        
        for x in min..<max
        {
            for y in min..<max
            {
                let newValue = JZNoiseMapManager.sharedInstance.noiseMap.value(at: vector2(Int32(x), Int32(y)))
                if (newValue < noiseValue)
                {
                    noiseValue = newValue
                    fx = x
                    fy = y
                }
            }
        }
        self.position = SCNVector3((Float(fx) / Float(NOISE_SAMPLE_COUNT) - 0.5) * GOLF_SITE_SQUARE_MESH_SIZE , (Float(fy) / Float(NOISE_SAMPLE_COUNT) - 0.5) * GOLF_SITE_SQUARE_MESH_SIZE , GOLF_SITE_SQUARE_MESH_SIZE / 2.0 * GOLF_SITE_HEIGHT_MULTIPIER * (noiseValue / 2.0 + 0.5))
    }
}
class JZGolfDirectionArrow : JZGameObject
{
    let ARROW_HEIGHT = 100.0
    let POLE_HEIGHT = 300.0
    let ARROW_DISTANCE_TO_BALL = 20.0
    weak var golfGameObject : JZGolfBallGameObject? = nil
    
    var alwaysOnTopMaterial : SCNMaterial = SCNMaterial()
    var isHiddenInScene : Bool
    {
        get  { return _isHiddenInScene }
        set
        {
            _isHiddenInScene = newValue
            node.opacity = _isHiddenInScene ? 0.0 : 1.0
        }
    }
    var _isHiddenInScene : Bool = true
    
    var arrowNode : SCNNode? = nil
    var poleNode : SCNNode? = nil
    
    var timer : Timer? = nil
    var timerHelperBool : Bool = false
    
    override init()
    {
        super.init()
        setup()
    }
    
    func setup() -> Void
    {
        isHiddenInScene = true
        NotificationCenter.default.addObserver(self, selector: #selector(handleStateChangedNotification(notification:)), name: NSNotification.Name(rawValue: NOTIFICATION_BUTTON_STATE_CHANGED), object: nil)
        alwaysOnTopMaterial.readsFromDepthBuffer = false
        alwaysOnTopMaterial.diffuse.contents = UIColor.red
        alwaysOnTopMaterial.emission.contents = UIColor.red
        poleNode = SCNNode(geometry: SCNCylinder(radius: 10, height: CGFloat(POLE_HEIGHT)))
        poleNode?.geometry?.materials = [alwaysOnTopMaterial]
        poleNode?.renderingOrder = 1
        arrowNode = SCNNode(geometry: SCNCone(topRadius: 0, bottomRadius: 30, height: 50))
        arrowNode?.geometry?.materials = [alwaysOnTopMaterial]
        arrowNode?.renderingOrder = 1
        addChildNode(nodeToAdd: poleNode!)
        poleNode?.addChildNode(arrowNode!)
        arrowNode?.position = SCNVector3(0, (POLE_HEIGHT + ARROW_HEIGHT) / 2,0)
        arrowNode?.eulerAngles = SCNVector3(0.0, 0.0, 0.0)
        poleNode?.eulerAngles = SCNVector3(90.0.degreesToRadians,0.0,0.0)
        poleNode?.position = SCNVector3(0.0,0,(Float(ARROW_DISTANCE_TO_BALL + POLE_HEIGHT / 2.0 + 20.0)))
        setDirection(yAngle: 0.0)
    }
    @objc func handleStateChangedNotification(notification:Notification) -> Void
    {
        let userInfo = notification.userInfo
        let state : JZStartBallButton.JZStartBallButtonType = userInfo!["state"] as! JZStartBallButton.JZStartBallButtonType
        if (state == .standby)
        {
            isHiddenInScene = true
            let worldArrow : SCNVector3 = self.arrowNode!.convertPosition(SCNVector3(0,0,0), to: nil)
            let worldBall : SCNVector3 = self.node.convertPosition(SCNVector3(0,0,0), to: nil)
            let vector : SCNVector3 = (worldArrow - worldBall) * self.scale.z * 0.05
            self.golfGameObject?.node.physicsBody?.velocity = vector
        }else if (state == .choosingFlatDirection)
        {
            isHiddenInScene = false
        }
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true, block: {_ in
            switch(state)
            {
            case .choosingFlatDirection:
                self.setDirection(yAngle: Double(self.eulerAngles.y) + 5.degreesToRadians)
                break
            case .choosingVerticalDirection:
                let x = Double(self.eulerAngles.x)
                if (x > 0.degreesToRadians){ self.timerHelperBool = true }
                if (x < -90.degreesToRadians){ self.timerHelperBool = false }
                let angle = x + (self.timerHelperBool ? -2 : 2).degreesToRadians
                self.setAngle(xAngle: angle)
                break
            case .choosingForce:
                let z = self.scale.z
                if (z > 5){ self.timerHelperBool = true }
                if (z < 0.5){ self.timerHelperBool = false }
                let force = z + (self.timerHelperBool ? -0.2 : 0.2)
                self.setForce(force: force)
                break
            case .standby:
                self.eulerAngles = SCNVector3(0,0,0)
                self.scale = SCNVector3(1,1,1)
                break
            }
        })
        
    }
    
    func setDirection(yAngle : Double) -> Void
    {
        eulerAngles = SCNVector3(eulerAngles.x,Float(yAngle),eulerAngles.z)
    }
    func setAngle(xAngle : Double) -> Void
    {
        eulerAngles = SCNVector3(Float(xAngle),eulerAngles.y,eulerAngles.z)
    }
    func setForce(force : Float) -> Void {
        scale = SCNVector3(1,1,force)
    }
    
}
class JZCameraFollowBehavior : GKComponent
{
    var ballToFollow : JZGameObject!
    override init()
    {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(JZCameraFollowBehavior.handlePinchNotification), name: NSNotification.Name(rawValue: NOTIFICATION_GAME_VIEW_PINCH_GESTURE), object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func handlePinchNotification(notification:Notification) -> Void
    {
        let customEntity : JZGKEntity = entity as! JZGKEntity
        let userInfo = notification.userInfo
        let gesture : UIPinchGestureRecognizer = userInfo!["gesture"] as! UIPinchGestureRecognizer
        customEntity.gameObject!.node.camera?.orthographicScale = (gesture.velocity < 0) ? customEntity.gameObject!.node.camera!.orthographicScale + 10 : customEntity.gameObject!.node.camera!.orthographicScale - 10
    }
    
    override func update(deltaTime seconds: TimeInterval)
    {
        super.update(deltaTime: seconds)
        if (ballToFollow == nil)
        {
            ballToFollow = (JZSceneManager.sharedInstance.scene!).golfBallGameObject
        }
        if (entity != nil && ballToFollow != nil)
        {
            let customEntity : JZGKEntity = entity as! JZGKEntity
            let newPos = ballToFollow.node.presentation.position + SCNVector3(10000,10000,10000)
            customEntity.gameObject?.position = newPos
            customEntity.gameObject?.eulerAngles = SCNVector3(-36.degreesToRadians,45.degreesToRadians,0.degreesToRadians)
        }
    }
}
class JZCameraGameObject : JZGameObject
{
    let cameraFollowBehavior : JZCameraFollowBehavior = JZCameraFollowBehavior()
    override init()
    {
        super.init()
        name = "Camera"
        self.node.camera = SCNCamera()
        self.node.camera?.motionBlurIntensity = 0.6
        self.node.camera?.bloomIntensity = 0.4
        self.node.camera?.xFov = 50
        self.node.camera?.yFov = 50
        self.node.camera?.orthographicScale = 1000
        self.node.camera?.automaticallyAdjustsZRange = false
        self.node.camera?.usesOrthographicProjection = true
        self.node.camera?.zNear = 10
        self.node.camera?.zFar = 100000
        self.addComponent(component: cameraFollowBehavior)
    }
    
}
protocol JZGolfBallGameObjectStatDelegate: class
{
    func nodeVelocityUpdate(sender: JZGolfBallGameObject, velocity : SCNVector3)
}
class JZGolfBallGameObject : JZGameObject
{
    let GOLF_BALL_RADIUS = 20.0
    
    weak var delegate:JZGolfBallGameObjectStatDelegate?
    
    override init()
    {
        super.init()
        name = "Golf Ball"
        self.geometry = SCNSphere(radius: CGFloat(GOLF_BALL_RADIUS))
        self.node.castsShadow = true
        self.position = SCNVector3(0, GOLF_SITE_SQUARE_MESH_SIZE / 4 , GOLF_SITE_SQUARE_MESH_SIZE/2)
        self.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        self.physicsBody.mass = 1.0
        self.physicsBody.isAffectedByGravity = true
        physicsBody.contactTestBitMask = 1
    }
    
    override func update(deltaTime seconds: TimeInterval)
    {
        super.update(deltaTime: seconds)
        delegate?.nodeVelocityUpdate(sender: self, velocity: (self.node.physicsBody?.velocity)!)
    }
}
class JZSkylineGameObject: JZGameObject
{
    override init()
    {
        super.init()
        geometry = SCNFloor()
        let material : SCNMaterial = SCNMaterial()
        material.diffuse.contents = UIColor.green
        geometry.materials = [material]
    }
}
class JZGolfSiteGameObject : JZGameObject
{
    var planeMeshGeometry : SCNPlane = SCNPlane(width: CGFloat(GOLF_SITE_SQUARE_MESH_SIZE), height: CGFloat(GOLF_SITE_SQUARE_MESH_SIZE))
    var meshMaterial : SCNMaterial = SCNMaterial()
    var colliderWalls : [SCNNode]? = nil
    var clearMaterial : SCNMaterial = SCNMaterial()
    
    override init()
    {
        super.init()
        name = "Golf Site"
        
        clearMaterial.diffuse.contents = UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
        for i in 0..<4
        {
            let wallNode : SCNNode = SCNNode(geometry: SCNPlane(width: CGFloat(GOLF_SITE_SQUARE_MESH_SIZE)/2, height: CGFloat(GOLF_SITE_SQUARE_MESH_SIZE)/2))
            wallNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            addChildNode(nodeToAdd: wallNode)
            wallNode.geometry?.materials = [clearMaterial]
            wallNode.position = SCNVector3(GOLF_SITE_SQUARE_MESH_SIZE / 4.0 * sin(Float(90.degreesToRadians) * Float(i)),GOLF_SITE_SQUARE_MESH_SIZE / 4 * cos(Float(90.degreesToRadians) * Float(i)),GOLF_SITE_SQUARE_MESH_SIZE / 4)
            wallNode.eulerAngles = SCNVector3( ((i % 2 == 0) ? 90.degreesToRadians : 0) , ((i % 2 == 1) ? 90.degreesToRadians : 0) , 0.0 )
        }
        
        planeMeshGeometry.widthSegmentCount = GOLF_SITE_SQUARE_MESH_SEGMENTS_COUNT
        planeMeshGeometry.heightSegmentCount = GOLF_SITE_SQUARE_MESH_SEGMENTS_COUNT
        planeMeshGeometry.cornerRadius = 0.0
        position = SCNVector3(0,1,GOLF_SITE_SQUARE_MESH_SIZE/2)
        
        Thread.sleep(forTimeInterval: 1.0)
        
        eulerAngles = SCNVector3(-90.degreesToRadians,0,0)
        
        self.meshModifer()
        self.applyPhysics()
    }
    
    func meshModifer() -> Void
    {
        
        var vertexSources : [SCNGeometrySource] = planeMeshGeometry.getGeometrySources(for: .vertex)
        let vertexSource : SCNGeometrySource = vertexSources[0]
        
        var texCoordSources : [SCNGeometrySource] = planeMeshGeometry.getGeometrySources(for: .texcoord)
        let texCorrdSource : SCNGeometrySource = texCoordSources[0]
        
        let stride : Int = vertexSource.dataStride
        let offest : Int = vertexSource.dataOffset
        let componentsPerVector : Int = vertexSource.componentsPerVector
        let bytesPerVector : Int = componentsPerVector * vertexSource.bytesPerComponent
        let vectorCount : Int = vertexSource.vectorCount
        
        var vertices : [SCNVector3] = [SCNVector3](repeatElement(SCNVector3(0,0,0), count: vectorCount))
        for i in 0..<vectorCount
        {
            var vectorData : [Float] = [Float](repeatElement(0.0, count: 3))
            let byteRange : NSRange = NSMakeRange(i * stride + offest, bytesPerVector)
            let vertexData = vertexSource.data as NSData
            vertexData.getBytes(&vectorData, range: byteRange)
            
            let x : Float = vectorData[0]
            let y : Float = vectorData[1]
            let xNormalized : Float = x / GOLF_SITE_SQUARE_MESH_SIZE + 0.5
            let yNormalized : Float = y / GOLF_SITE_SQUARE_MESH_SIZE + 0.5
            
            let vectorToSample : vector_int2 = vector2(Int32(xNormalized * Float(NOISE_SAMPLE_COUNT)), Int32(yNormalized * Float(NOISE_SAMPLE_COUNT)))
            let noiseMap = JZNoiseMapManager.sharedInstance.noiseMap
            let noiseValie : Float = (noiseMap!.value(at: vectorToSample)) / 2.0 + 0.5
            
            let newVector : SCNVector3 = SCNVector3 (vectorData[0],vectorData[1],noiseValie*GOLF_SITE_SQUARE_MESH_SIZE / 2.0*GOLF_SITE_HEIGHT_MULTIPIER)
            vertices[i] = newVector
        }
        
        let deformedVertexSource : SCNGeometrySource = SCNGeometrySource(vertices: vertices)
        let SCNGeometrySourceArray : [SCNGeometrySource] = [deformedVertexSource, texCorrdSource]
        var deformedGeometry
            : SCNGeometry = SCNGeometry(sources: SCNGeometrySourceArray, elements: planeMeshGeometry.geometryElements)
        
        let mdlDeformedMesh : MDLMesh = MDLMesh(scnGeometry: deformedGeometry)
        mdlDeformedMesh.addNormals(withAttributeNamed: MDLVertexAttributeNormal, creaseThreshold: 0.2)
        deformedGeometry = SCNGeometry(mdlMesh: mdlDeformedMesh)
        meshMaterial.diffuse.contents = JZNoiseMapManager.sharedInstance.noiseImage
        deformedGeometry.materials = [meshMaterial]
        geometry = deformedGeometry
    }
    
    func applyPhysics() -> Void
    {
        self.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: self.geometry, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
        self.physicsBody.isAffectedByGravity = false
    }
}
