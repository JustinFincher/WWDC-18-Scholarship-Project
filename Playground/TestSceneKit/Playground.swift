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

let GAME_DEBUG_MODE_ON : Bool = true
let XCODE_BEHAVIOR_IPHONE : Bool = true
let GOLF_SITE_SQUARE_MESH_SEGMENTS_COUNT : Int = 99
let GOLF_SITE_SQUARE_MESH_SIZE : Float = 2000.0
let GOLF_SITE_HEIGHT_MULTIPIER : Float = 0.2
let NOISE_SAMPLE_COUNT : Int = 1024
let NOISE_SAMPLE_SIZE : Double = 800.0
let NOTIFICATION_GAME_ASSET_PROCESS_START : String = "NOTIFICATION_GAME_ASSET_PROCESS_START"
let NOTIFICATION_GAME_ASSET_PROCESS_END : String = "NOTIFICATION_GAME_ASSET_PROCESS_END"



// MARK: - Utility
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
        //        let noiseSource : GKPerlinNoiseSource = GKPerlinNoiseSource(frequency: 0.01, octaveCount: 10, persistence: 0.4, lacunarity: 2.0, seed: 1)
        //        let noiseSource : GKRidgedNoiseSource = GKRidgedNoiseSource(frequency: 0.01, octaveCount: 1, lacunarity: 2.0, seed: 2)
        let noise : GKNoise = GKNoise(noiseSource, gradientColors: [-1.0 : JZHelper.UIColorFromHex(hex: "18BD00") ,-0.0 : UIColor.green, 0.5 : UIColor.yellow, 1.0 : UIColor.white])
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
    
    init()
    {
        
    }
    
    func processNewGameAssets() -> Void
    {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NOTIFICATION_GAME_ASSET_PROCESS_START), object: nil)
        OperationQueue().addOperation(
            {
                self.scene?.golfSiteGameObject = JZGolfSiteGameObject()
                self.scene?.rootNode.addChildNode((self.scene?.golfSiteGameObject.node)!)
                
                OperationQueue.main.addOperation
                    {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NOTIFICATION_GAME_ASSET_PROCESS_END), object: nil)
                }
        })
        
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
    }
    
    func addComponent(component: GKComponent) -> Void
    {
        entity.addComponent(component)
    }
    func removeComponent(ofType componentClass: GKComponent.Type) -> Void
    {
        entity.removeComponent(ofType: componentClass)
    }
}

class JZSCNNode : SCNNode
{
    weak var gameObject : JZGameObject? = nil
}
class JZGKEntity : GKEntity
{
    weak var gameObject : JZGameObject? = nil
}

// MARK: - Views
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
        })
    }
    
}
class JZPlayerScene : SCNScene
{
    var golfSiteGameObject : JZGolfSiteGameObject!
    
    override init() {
        super.init()
        JZSceneManager.sharedInstance.scene = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
class JZPlayerSceneView : SCNView
{
    
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
        self.allowsCameraControl = true
        if (GAME_DEBUG_MODE_ON)
        {
            debugOptions = .showPhysicsShapes
        }
        
        JZSceneManager.sharedInstance.processNewGameAssets()
    }
}


// MARK: - Controllers / UI
class JZHelpViewController : UITableViewController
{
    var aboutProductCell : UITableViewCell = UITableViewCell()
    override func viewDidLoad()
    {
        super.viewDidLoad()
        aboutProductCell.textLabel?.text = "⛳⛳⛳ Golf GO"
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self.aboutProductCell
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Introduction"
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
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        self.view.addSubview(sceneView)
        self.view.addSubview(menuView)
    }
    
    func rightBarButtonPressed(_ sender : UIBarButtonItem) -> Void
    {
        let helpVC : JZHelpViewController = JZHelpViewController()
        helpVC.modalPresentationStyle = UIModalPresentationStyle.popover
        let popoverPresentationViewController : UIPopoverPresentationController = helpVC.popoverPresentationController!
        popoverPresentationViewController.permittedArrowDirections = .any
        popoverPresentationViewController.delegate = self
        popoverPresentationViewController.sourceView = self.view;
        popoverPresentationViewController.barButtonItem = sender
        var frame:CGRect = (sender.value(forKey: "view") as! UIView).frame
        frame.origin.y = frame.origin.y+20
        popoverPresentationViewController.sourceRect = frame
        
        present(helpVC, animated: true, completion: nil)
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
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
class JZGolfSiteGameObject : JZGameObject
{
    var planeMeshGeometry : SCNPlane = SCNPlane(width: CGFloat(GOLF_SITE_SQUARE_MESH_SIZE), height: CGFloat(GOLF_SITE_SQUARE_MESH_SIZE))
    var meshMaterial : SCNMaterial = SCNMaterial()
    
    override init()
    {
        super.init()
        name = "Golf Site"
        eulerAngles = SCNVector3(0,0,0)
        JZNoiseMapManager.sharedInstance.generateNoiseMap()
        planeMeshGeometry.widthSegmentCount = GOLF_SITE_SQUARE_MESH_SEGMENTS_COUNT
        planeMeshGeometry.heightSegmentCount = GOLF_SITE_SQUARE_MESH_SEGMENTS_COUNT
        planeMeshGeometry.cornerRadius = 0.0
        
        Thread.sleep(forTimeInterval: 0.5)
        
        eulerAngles = SCNVector3(-90,0,0)
        
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
        let deformedGeometry
            : SCNGeometry = SCNGeometry(sources: SCNGeometrySourceArray, elements: planeMeshGeometry.geometryElements)
        //        let deformedGeometryUsingMDL : MDLMesh = MDLMesh(scnGeometry: deformedGeometry)
        //        deformedGeometryUsingMDL.addNormals(withAttributeNamed: MDLVertexAttributeNormal, creaseThreshold: 0.2)
        //        deformedGeometry = SCNGeometry(mdlMesh: deformedGeometryUsingMDL)
        
        meshMaterial.diffuse.contents = JZNoiseMapManager.sharedInstance.noiseImage
        deformedGeometry.materials = [meshMaterial]
        geometry = deformedGeometry
    }
    
    func applyPhysics() -> Void
    {
        self.node.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: self.geometry, options: [SCNPhysicsShape.Option.keepAsCompound:true,SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
    }
}
