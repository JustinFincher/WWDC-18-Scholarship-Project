//
//  Playground.swift
//  TestSceneKit
//
//  Created by Justin Fincher on 2017/3/25.
//  Copyright © 2017年 Justin Fincher. All rights reserved.
//

import Foundation
//: Golf GO ⛳
//: Build 3

import UIKit
import GameplayKit
import SceneKit
import SceneKit.ModelIO
import SpriteKit
import ModelIO

let GAME_DEBUG_MODE_ON : Bool = false
let XCODE_BEHAVIOR_IPHONE : Bool = true
let GOLF_SITE_SQUARE_MESH_SEGMENTS_COUNT : Int = 89
let GOLF_SITE_SQUARE_MESH_SIZE : Float = 8000.0
let GOLF_SITE_HEIGHT_MULTIPIER : Float = 0.10
let NOISE_SAMPLE_COUNT : Int = 1024
let NOISE_SAMPLE_SIZE : Double = 800.0
let NOTIFICATION_GAME_ASSET_PROCESS_START : String = "NOTIFICATION_GAME_ASSET_PROCESS_START"
let NOTIFICATION_GAME_ASSET_PROCESS_END : String = "NOTIFICATION_GAME_ASSET_PROCESS_END"
let NOTIFICATION_GAME_VIEW_PINCH_GESTURE : String = "NOTIFICATION_GAME_VIEW_PINCH_GESTURE"



// MARK: - Utility
extension Array where Element: AnyObject {
    mutating func remove(object: Element) {
        if let index = index(where: { $0 === object }) {
            remove(at: index)
        }
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
        let noiseSource : GKBillowNoiseSource = GKBillowNoiseSource(frequency: 0.01, octaveCount: 10, persistence: 0.4, lacunarity: 2.0, seed: 1)
        let noise : GKNoise = GKNoise(noiseSource, gradientColors: [-1.0 : JZHelper.UIColorFromHex(hex: "2F971C"), -0.5 : JZHelper.UIColorFromHex(hex: "5CA532") ,-0.0 : JZHelper.UIColorFromHex(hex: "DFED8B"), 0.6 : JZHelper.UIColorFromHex(hex: "A9A172"), 0.8 : JZHelper.UIColorFromHex(hex: "A9A172"), 1.0 : UIColor.white])
        noiseMap = GKNoiseMap(noise, size: vector2(NOISE_SAMPLE_SIZE,NOISE_SAMPLE_SIZE), origin: vector2(0, 0), sampleCount: vector2(Int32(NOISE_SAMPLE_COUNT), Int32(NOISE_SAMPLE_COUNT)), seamless: true)
        let noiseTexture : SKTexture = SKTexture(noiseMap: noiseMap)
        noiseImage = UIImage(cgImage: noiseTexture.cgImage())
    }
}
class JZSceneManager
{
    static let sharedInstance = JZSceneManager()
    
    var scene : JZPlayerScene?
    var sceneView : JZPlayerSceneView?
    var gameMenuView : JZGameMenuView?
    
    var goList : [JZGameObject]
    
    init()
    {
        goList = [JZGameObject]()
    }
    
    func processNewGameAssets() -> Void
    {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NOTIFICATION_GAME_ASSET_PROCESS_START), object: nil)
        OperationQueue().addOperation(
            {
                self.scene?.skylineGameObject = JZSkylineGameObject()
                self.scene?.rootNode.addChildNode((self.scene?.skylineGameObject.node)!)
                
                self.scene?.golfSiteGameObject = JZGolfSiteGameObject()
                self.scene?.rootNode.addChildNode((self.scene?.golfSiteGameObject.node)!)
                
                self.scene?.golfBallGameObject = JZGolfBallGameObject()
                self.scene?.rootNode.addChildNode((self.scene?.golfBallGameObject.node)!)
                
                self.scene?.cameraGameObject = JZCameraGameObject()
                self.scene?.rootNode.addChildNode((self.scene?.cameraGameObject.node)!)
                self.sceneView?.pointOfView = self.scene?.cameraGameObject.node
                
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
class JZStartBallButton : UIVisualEffectView
{
    enum JZStartBallButtonType: Int {
        case standby = 1
        case choosingFlatDirection = 2
        case choosingVerticalDirection = 3
        case choosingForce = 4
    }
    
    var currentState : JZStartBallButtonType
    {
        get { return _currentState }
        set
        {
            _currentState = newValue
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
        isUserInteractionEnabled = true
        backgroundColor = UIColor.white
        
        startGameIcon = UILabel(frame: CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height / 2))
        startGameIcon.text = "GOLF GO"
        startGameIcon.textAlignment = .center
        startGameIcon.font = UIFont.systemFont(ofSize: 80)
        addSubview(startGameIcon)
        startGameIcon.autoresizingMask = [.flexibleLeftMargin,.flexibleRightMargin,.flexibleTopMargin,.flexibleHeight]
        
        loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        addSubview(loadingIndicator)
        loadingIndicator.frame.origin = CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0)
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.autoresizingMask = [.flexibleBottomMargin,.flexibleLeftMargin,.flexibleRightMargin,.flexibleTopMargin]
        
        NotificationCenter.default.addObserver(self, selector: #selector(onGameAssetProcessStart(notif:)), name: NSNotification.Name(rawValue: NOTIFICATION_GAME_ASSET_PROCESS_START), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onGameAssetProcessEnd(notif:)), name: NSNotification.Name(rawValue: NOTIFICATION_GAME_ASSET_PROCESS_END), object: nil)
    }
    
    func onGameAssetProcessStart(notif:Notification) -> Void
    {
        loadingIndicator.startAnimating()
        isUserInteractionEnabled = false
    }
    func onGameAssetProcessEnd(notif:Notification) -> Void
    {
        loadingIndicator.stopAnimating()
        UIView.animate(withDuration: 0.5, animations: { self.alpha = 0.0 }, completion: { (finished) -> Void in
            self.controller?.navigationController?.setNavigationBarHidden(false, animated: true)
            self.removeFromSuperview()
        })
    }
    
}
class JZPlayerScene : SCNScene
{
    var golfSiteGameObject : JZGolfSiteGameObject!
    var golfBallGameObject : JZGolfBallGameObject!
    var skylineGameObject : JZSkylineGameObject!
    var cameraGameObject : JZCameraGameObject!
    
    var directLightGameObject : JZGameObject!
    var areaLightGameObject : JZGameObject!
    
    override init() {
        super.init()
        JZSceneManager.sharedInstance.scene = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
class JZPlayerSceneView : SCNView, SCNSceneRendererDelegate
{
    var pinchGesture : UIPinchGestureRecognizer?
    var startBallButton : JZStartBallButton?
    
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
        let scene : JZPlayerScene = JZPlayerScene()
        self.scene = scene
        self.backgroundColor = UIColor.lightGray
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleTopMargin, .flexibleLeftMargin ,.flexibleRightMargin]
        self.isPlaying = true
        self.delegate = self
        self.allowsCameraControl = false
        self.autoenablesDefaultLighting = false
        if (GAME_DEBUG_MODE_ON)
        {
            debugOptions = .showWireframe
        }
        startBallButton = JZStartBallButton(frame: CGRect(x: 40, y: self.frame.height - 120, width: self.frame.width - 80, height: 60))
        addSubview(startBallButton!)
        
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(JZPlayerSceneView.handleGesture(gesture:)))
        addGestureRecognizer(pinchGesture!)
        JZSceneManager.sharedInstance.processNewGameAssets()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
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
    var aboutProductCell : UITableViewCell = UITableViewCell()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        tableView.allowsSelection = false
        aboutProductCell.textLabel?.text = "Golf GO is a small game written by ZHENG HAOTIAN (Justin Fincher). It  is built on top of Swift Playground and uses serveral new iOS framework and APIs, like SceneKit, ModelIO, GameplayKit."
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self.aboutProductCell
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "⛳⛳⛳ What is Golf GO?"
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
        
        self.view.addSubview(sceneView)
        self.view.addSubview(menuView)
    }
    func leftBarButtonPressed(_ sender : UIBarButtonItem) -> Void
    {
        
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
    
}
class JZNaviController: UINavigationController
{
    override func viewDidLoad()
    {
        view.backgroundColor = UIColor.white
    }
}
// MARK: - Controllers / Game
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
            customEntity.gameObject?.position = ballToFollow.position + SCNVector3(3000,3000,3000)
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
        self.node.camera?.xFov = 70
        self.node.camera?.yFov = 70
        self.node.camera?.orthographicScale = 1000
        self.node.camera?.automaticallyAdjustsZRange = false
        self.node.camera?.usesOrthographicProjection = true
        self.node.camera?.zNear = 0.01
        self.node.camera?.zFar = 100000
        self.addComponent(component: cameraFollowBehavior)
    }
    
}
class JZGolfBallGameObject : JZGameObject
{
    override init()
    {
        super.init()
        name = "Golf Ball"
        self.geometry = SCNSphere(radius: 20.0)
        self.position = SCNVector3(0, 400 , GOLF_SITE_SQUARE_MESH_SIZE/2)
        self.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        self.physicsBody.isAffectedByGravity = true
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
    
    override init()
    {
        super.init()
        name = "Golf Site"
        JZNoiseMapManager.sharedInstance.generateNoiseMap()
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
//        meshMaterial.normal.contents = JZNoiseMapManager.sharedInstance.noiseImage
//        meshMaterial.reflective.contents = JZSceneManager.sharedInstance.scene?.background
//        meshMaterial.isDoubleSided = true
        
        deformedGeometry.materials = [meshMaterial]
        geometry = deformedGeometry
    }
    
    func applyPhysics() -> Void
    {
        self.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: self.geometry, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
        self.physicsBody.isAffectedByGravity = false
    }
}
