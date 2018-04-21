![Banner](https://raw.githubusercontent.com/JustinFincher/WWDC-17-Scholarship-Project/master/Screenshot/Banner.jpg)
# GOLF GO.

# Project
~~The playground which used for application for WWDC 2017. Unfortunately I didn't make it to the selection (which is really a bummer for me :-( ), so I open-sourced it.~~  
The same playground which wasn't chosen by Apple in 2017 won me a WWDC Scholarship this year (2018). I guess the reason that my project didn't make it to the selection in 2017 was a bug in SceneKit (radar `#39027796 Change widthSegmentCount/heightSegmentCount on SCNPlane doesn't change vertex immediately`), which I bypassed with a Thread.Sleep workaround. :-P

# Usage 
The Swift Playground (both Xcode and iPad) is unstable at the moment (2017.4.2), so directly open `Playground.xcodeproj` is more recommended. The code is the same as the playground but intergated into a single page application template.  

If you really want to use Swift Playground, I would like you to open the “Golf GO.playgroundbook” on iPad instead of “Golf GO.playground”, which contains the disable logging key of Swift Playground to enable a faster runtime performance.  
Both “Golf GO.playgroundbook” and “Golf GO.playground” have the same code, the only difference is the first has logging system disabled in plist as I mentioned. The logging system is useful but somehow too annoying to log everything out and wastes huge amount of memory.  


# Tech Info  
This Swift playground (as "Golf GO"), uses various APIs from SceneKit, GameplayKit and ModelIO.  

Golf GO is a golf game with infinte map generation!

- Procedurally generated terrain : Golf GO uses GKNoiseMap and GKBillowNoiseSource to provide a procedurally generated noise map as terrain height map. It reads noise value at specific point, then pass the value to SCNGeometrySource to modify the vertex position of a SCNPlane. After the modification to SCNGeometry, a MDLMesh is used to re-generate normals to the current terrain mesh and with a colored noise diffuse texture, the terrain node is fully generated at runtime.  

- GameObject system using GKComponent, GKEntity and SCNNode : To achieve a more simple Entity-Component behavior system in SceneKit, I created a custom class named JZGameObject, which contains both instances of GKEntity and SCNNode. Then I can have references to SCNNode from GKEntity, thus bridges both framework to work in a Unity3D engine’s GameObject-MonoBehavior like style. For example, a JZGameObject subclass called JZCameraGameObject can have SCNSceneRendererDelegate’s renderer(_:updateAtTime:) dispatched to GKEntitys attached to the camera. So a GKEntity subclass called JZCameraFollowBehavior can access to SCNNode’s transform in update() function and make the camera near to the golf ball every frame.  

# Screenshot

Running as a single page application. On iPad Pro 9.7 Simulator.

![1](https://raw.githubusercontent.com/JustinFincher/WWDC-18-Scholarship-Project/master/Screenshot/1.jpg)
![2](https://raw.githubusercontent.com/JustinFincher/WWDC-18-Scholarship-Project/master/Screenshot/2.jpg)
![3](https://raw.githubusercontent.com/JustinFincher/WWDC-18-Scholarship-Project/master/Screenshot/3.jpg)
![4](https://raw.githubusercontent.com/JustinFincher/WWDC-18-Scholarship-Project/master/Screenshot/4.jpg)


