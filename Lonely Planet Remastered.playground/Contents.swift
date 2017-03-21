//: Playground - noun: a place where people can play

import UIKit
import GameplayKit
import SceneKit
import SpriteKit
import PlaygroundSupport

class ViewController: UIViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.preferredContentSize = self.view.frame.size
    }
}
class NaviController: UINavigationController
{
    
}

var controller : ViewController = ViewController()
var naviController : UINavigationController = UINavigationController(rootViewController: controller)

PlaygroundPage.current.needsIndefiniteExecution = true
PlaygroundPage.current.liveView = naviController




//var imgView : UIImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
//controller.view.addSubview(imgView)
//
//var sceneView : SCNView = SCNView(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
//var perlinNoiseSource : GKPerlinNoiseSource = GKPerlinNoiseSource(frequency: 4.0, octaveCount: 5, persistence: 0.2, lacunarity: 0.9, seed: 1);
//var noise : GKNoise = GKNoise(perlinNoiseSource, gradientColors: [-1.0 : UIColor.black, 1.0 : UIColor.white])
//var noiseMap : GKNoiseMap = GKNoiseMap(noise, size: vector2(8, 8), origin: vector2(0, 0), sampleCount: vector2(400, 400), seamless: true)
//var noiseTexture : SKTexture = SKTexture(noiseMap: noiseMap)
//imgView.image = UIImage(cgImage: noiseTexture.cgImage())
//
//
//var a : Int32 = 1
//var timer : Timer = Timer(timeInterval: 1.0, repeats: true, block: {(t : Timer) -> Void in
//
//    perlinNoiseSource.seed = perlinNoiseSource.seed + 1
//    a = a + 1
//    noise = GKNoise(perlinNoiseSource, gradientColors: [-1.0 : UIColor.black, 1.0 : UIColor.white])
//    noiseMap = GKNoiseMap(noise, size: vector2(8, 8), origin: vector2(0, 0), sampleCount: vector2(400, 400), seamless: true)
//    noiseTexture = SKTexture(noiseMap: noiseMap)
//    imgView.image = UIImage(cgImage: noiseTexture.cgImage())
//})
//timer.fire()

