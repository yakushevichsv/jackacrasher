//
//  PyramidScene.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 10/14/15.
//  Copyright © 2015 Siarhei Yakushevich. All rights reserved.
//

import SceneKit

class PyramidScene: SCNScene {

    internal var camera:SCNNode!
    
    class func pyramidScene() -> PyramidScene {
        
        
        let scene = PyramidScene()
        
        scene.rootNode.addChildNode(PyramidNode())
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.position = SCNVector3Make(0, 0, 15)
        cameraNode.name = "cameraNode"
        
        let camera = SCNCamera()
        camera.xFov = 40
        camera.yFov = 40
        cameraNode.camera = camera
        scene.rootNode.addChildNode(cameraNode)
        scene.camera = cameraNode
        
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight();
        lightNode.light?.type = SCNLightTypeDirectional;
        lightNode.light?.color = UIColor(red: 0.7, green: 0.7, blue: 7, alpha: 1)
        lightNode.position = SCNVector3Make(0, 10, 10);
        lightNode.rotation = SCNVector4Make(1, 1, 0, -Float(M_PI_4));
        scene.rootNode.addChildNode(lightNode)
        
        //[scene.rootNode addChildNode:lightNode];
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = SCNLightTypeAmbient
        ambientLightNode.light?.color = UIColor.darkGrayColor()
        scene.rootNode.addChildNode(ambientLightNode)
        
        
        return scene
    }
    
    
    private class func PyramidNode() -> SCNNode {
        let pyramid = SCNPyramid(width: 10.0, height: 20.0, length: 10.0)
        let pyramidNode = SCNNode(geometry: pyramid)
        pyramidNode.name = "pyramid"
        let position = SCNVector3Make(30, 0, -40)
        pyramidNode.position = position
        pyramidNode.geometry?.firstMaterial?.diffuse.contents = UIColor.redColor()
        pyramidNode.geometry?.firstMaterial?.shininess = 1.0
        return pyramidNode
    }
}
