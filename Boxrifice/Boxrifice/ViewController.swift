//
//  ViewController.swift
//  Boxrifice
//
//  Created by Kingshuk Kundu on 12/3/20.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, SCNPhysicsContactDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    var trackingEnabled = true
    var surfaceDetected = false
    var tracker:SCNNode?
    var container: SCNNode!
    var totalTime = 10
    var startTimer = Timer()
    var score = 0
    var prevHScore: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the view's delegate
        sceneView.delegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/scene.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        //Prepare viewController to start the game
        totalTime = 10
        timeLabel.text = String(Int(totalTime))
        score = 0
        scoreLabel.text = String(score)
        let userDefaults = Foundation.UserDefaults.standard
        prevHScore = userDefaults.string(forKey: "highScore")
        
    }
    
    //maintains time constraints of the game. When time is up, changes viewcontroller
    @objc func GameTimer() {
        totalTime -= 1
        timeLabel.text = String(totalTime)
        if totalTime == 0 {
            //ensures timer is stopped when reaches 0
            self.startTimer.invalidate()
            //if current score greater than previous high score, store new high score
            if prevHScore == nil{
                let userDefaults = Foundation.UserDefaults.standard
                userDefaults.set(self.score, forKey: "highScore")
            }else{
                if Int(prevHScore)! < self.score {
                    let userDefaults = Foundation.UserDefaults.standard
                    userDefaults.set(self.score, forKey: "highScore")
                }
            }
            viewWillDisappear(false)
            //switch viewcontroller
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "endView") as! EndViewController
            vc.modalPresentationStyle = .fullScreen
            vc.scoreData = String(self.score)
            self.present(vc, animated: false, completion: nil)
        }
    }
    
    //increments scorecount by 1 everytime called
    @objc func scoreUp() {
        score += 1
        DispatchQueue.main.async {
            self.scoreLabel.text = String(self.score)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
    
    //remove the bullet if its hit or if contact detected increment score
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let bullet = contact.nodeA.physicsBody!.contactTestBitMask == 1 ? contact.nodeA : contact.nodeB
        bullet.removeFromParentNode()
        scoreUp()
    }
    
    // locates horizontal plane and places a tracker on the plane
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard trackingEnabled
        else { return }
        DispatchQueue.main.async {
            let query = self.sceneView.raycastQuery(from: self.sceneView.center, allowing: .estimatedPlane, alignment: .horizontal)
            
            if let nonOptQuery: ARRaycastQuery = query {
                let result: [ARRaycastResult] = self.sceneView.session.raycast(nonOptQuery)
                guard let rayCast: ARRaycastResult = result.first else { return }
                self.loadTracker(rayCast)
            }
        }
    }
    //load and place the tracker where horizontal plane is located
    func loadTracker(_ result: ARRaycastResult) {
        let pos = SCNVector3(result.worldTransform.columns.3.x,
                             result.worldTransform.columns.3.y,
                             result.worldTransform.columns.3.z)
        if tracker == nil {
            let detectedPlane = SCNPlane(width: 0.3, height: 0.3)
            detectedPlane.firstMaterial?.diffuse.contents = UIImage(named: "place.png")
            detectedPlane.firstMaterial?.isDoubleSided = true
            tracker = SCNNode(geometry: detectedPlane)
            self.sceneView.scene.rootNode.addChildNode(self.tracker!)
            surfaceDetected = true
        }
        self.tracker?.position = pos
    }
    
    //launches bullet
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if trackingEnabled {
            guard surfaceDetected else { return }
            let trackerPosition = tracker!.position
            tracker?.removeFromParentNode()
            container = sceneView.scene.rootNode.childNode(withName: "container", recursively: false)!
            container.position = trackerPosition
            container.isHidden = false
            sceneView.scene.physicsWorld.contactDelegate = self
            trackingEnabled = false
            startTimer =  Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ViewController.GameTimer), userInfo: nil, repeats: true)
        }
        else {
            //get current frame of ARSession
            guard let viewDir = sceneView.session.currentFrame else { return }
            //get ARCamera
            let camCrdn = SCNMatrix4(viewDir.camera.transform)
            //use the negated rotation direction as a force
            let direction = SCNVector3Make(-camCrdn.m31 * 5.0, -camCrdn.m32 * 5.0, -camCrdn.m33 * 5.0)
            //get position of the camera
            let position = SCNVector3Make(camCrdn.m41, camCrdn.m42, camCrdn.m43)
            //generate the bullet
            let bullet = SCNCapsule(capRadius: 0.01, height: 0.05)
            bullet.firstMaterial?.emission.contents = UIColor.gray
            bullet.firstMaterial?.diffuse.contents = UIColor.gray
            let bulletNode = SCNNode(geometry: bullet)
            
            bulletNode.position = position
            //add physics properties to bullet
            bulletNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
            bulletNode.physicsBody?.categoryBitMask = 3
            bulletNode.physicsBody?.contactTestBitMask = 1
            //add bullet to the scene
            sceneView.scene.rootNode.addChildNode(bulletNode)
            bulletNode.runAction(SCNAction.sequence([SCNAction.wait(duration: 3.0), SCNAction.removeFromParentNode()]))
            //apply direction as a force on the bullet
            bulletNode.physicsBody?.applyForce(direction, asImpulse: true)
        }
    }
}
