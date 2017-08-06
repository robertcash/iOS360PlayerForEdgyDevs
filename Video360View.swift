//
//  Video360View.swift
//  Driver Onboarding 360
//
//  Created by Robert Cash on 8/3/17.
//  Copyright © 2017 Robert Cash. All rights reserved.
//

import UIKit
import SceneKit
import SpriteKit
import CoreMotion
import AVFoundation

class Video360View: SCNView {
    
    var videoPlayer: AVPlayer!
    var currentItem: AVPlayerItem!
    
    var motionManager: CMMotionManager!
    
    var videoScene: SCNScene!
    var cameraNode: SCNNode!
    var sphereNode: SCNNode!
    var videoNode: SKVideoNode!
    
    init(frame: CGRect, videoFileName: String, options: [String : Any]? = nil) {
        super.init(frame: frame, options: options)
        
        // Set up base scene and make it videoScene
        self.videoScene = SCNScene()
        self.scene = self.videoScene
        self.allowsCameraControl = true
        self.isUserInteractionEnabled = false
    
        // Set up video player
        let spriteScene = initVideoPlayer(videoFileName)
        
        // Set up video scene
        self.initVideoScene(spriteScene: spriteScene)
        
        // Set up camera node
        self.initCameraNode()
        
        // Set up gyro motion
        self.initMotionManager()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func initVideoPlayer(_ videoFileName: String) -> SKScene {
        let filePathUrl = URL(fileURLWithPath: Bundle.main.path(forResource: videoFileName, ofType:"MP4")!)
        self.currentItem = AVPlayerItem(url: filePathUrl)
        self.videoPlayer = AVPlayer(playerItem: self.currentItem)
        self.videoNode = SKVideoNode(avPlayer: self.videoPlayer)
        let size = CGSize(width: 1024, height: 512)
        self.videoNode.size = size
        self.videoNode.position = CGPoint(x: size.width/2.0, y: size.height/2.0)
        let spriteScene = SKScene(size: size)
        spriteScene.addChild(self.videoNode)
        
        return spriteScene
    }
    
    func initVideoScene(spriteScene: SKScene) {
        let sphere = SCNSphere(radius: 20.0)
        sphere.firstMaterial!.isDoubleSided = true
        sphere.firstMaterial!.diffuse.contents = spriteScene
        self.sphereNode = SCNNode(geometry: sphere)
        self.sphereNode.position = SCNVector3Make(0, 0, 0)
        self.videoScene.rootNode.addChildNode(self.sphereNode)
    }
    
    func initCameraNode() {
        self.cameraNode = SCNNode()
        self.cameraNode.camera = SCNCamera()
        self.cameraNode.position = SCNVector3Make(0, 0, 0)
        self.cameraNode.camera?.xFov = 60
        self.cameraNode.camera?.yFov = 60
        self.videoScene.rootNode.addChildNode(self.cameraNode)
    }

    func initMotionManager() {
        self.motionManager = CMMotionManager()
        self.motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        self.motionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: {
            [weak self] (deviceMotion, error) in
            self?.cameraNode.orientation = deviceMotion!.gaze(atOrientation: UIApplication.shared.statusBarOrientation)
        })
    }
    
}

extension CMDeviceMotion {
    
    func gaze(atOrientation orientation: UIInterfaceOrientation) -> SCNVector4 {
        
        let attitude = self.attitude.quaternion
        let aq = GLKQuaternionMake(Float(attitude.x), Float(attitude.y), Float(attitude.z), Float(attitude.w))
        
        let final: SCNVector4
        
        switch UIApplication.shared.statusBarOrientation {
            
        case .landscapeRight:
            let cq = GLKQuaternionMakeWithAngleAndAxis(Float(Double.pi / 2), 0, 1, 0)
            let q = GLKQuaternionMultiply(cq, aq)
            
            final = SCNVector4(x: -q.y, y: q.x, z: q.z, w: q.w)
            
        case .landscapeLeft:
            let cq = GLKQuaternionMakeWithAngleAndAxis(Float(-(Double.pi / 2)), 0, 1, 0)
            let q = GLKQuaternionMultiply(cq, aq)
            
            final = SCNVector4(x: q.y, y: -q.x, z: q.z, w: q.w)
            
        case .portraitUpsideDown:
            let cq = GLKQuaternionMakeWithAngleAndAxis(Float(Double.pi / 2), 1, 0, 0)
            let q = GLKQuaternionMultiply(cq, aq)
            
            final = SCNVector4(x: -q.x, y: -q.y, z: q.z, w: q.w)
            
        case .unknown:
            fallthrough

        case .portrait:
            let cq = GLKQuaternionMakeWithAngleAndAxis(Float((Double.pi / 2)), 1, 0, 0)
            let q = GLKQuaternionMultiply(cq, aq)
            
            final = SCNVector4(x: q.x, y: q.y, z: q.z, w: q.w)
        }
        
        return final
    }
}
