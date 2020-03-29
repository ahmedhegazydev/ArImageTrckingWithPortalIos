//
//  ViewController.swift
//  Tracked Images
//
//  Created by Tony Morales on 6/13/18.
//  Copyright © 2018 Tony Morales. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import HGRippleRadarView
import AVFoundation
import SwiftySound

@available(iOS 12.0, *)
class ImgTrackingViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet weak var lblState: UILabel!
    @IBOutlet weak var radarView: RadarView!
    @IBOutlet var imageViewSearch: UIImageView!
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var magicSwitch: UISwitch!
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    var timer: Timer?
    var index = 0
    var items = [Item]()
    
//    var radarView: RadarView? {
//        return view as? RadarView
//    }
    
    // Create video player
    let isaVideoPlayer: AVPlayer = {
        //load Isa video from bundle
        //        guard let url = Bundle.main.url(forResource: "isa video", withExtension: "mp4", subdirectory: "art.scnassets") else {
        //            print("Could not find video file")
        //            return AVPlayer()
        //        }
        
        guard let path = Bundle.main.path(forResource: "isa video", ofType:"mp4") else {
            
            print("Could not find video file")
            return AVPlayer()
        }
        
        return AVPlayer(url: URL(fileURLWithPath: path))
        
    }()
    let pragueVideoPlayer: AVPlayer = {
        //load Prague video from bundle
        //        guard let url = Bundle.main.url(forResource: "prague video", withExtension: "mp4", subdirectory: "art.scnassets") else {
        //            print("Could not find video file")
        //            return AVPlayer()
        //        }
        //        return AVPlayer(url: url)
        
        
        guard let path = Bundle.main.path(forResource: "prague video", ofType:"mp4") else {
            
            print("Could not find video file")
            return AVPlayer()
        }
        
        return AVPlayer(url: URL(fileURLWithPath: path))
        
    }()
    let fightClubVideoPlayer: AVPlayer = {
        //load Prague video from bundle
        //        guard let url = Bundle.main.url(forResource: "fight club video", withExtension: "mov", subdirectory: "art.scnassets") else {
        //            print("Could not find video file")
        //            return AVPlayer()
        //        }
        //        return AVPlayer(url: url)
        
        guard let path = Bundle.main.path(forResource: "fight club video", ofType:"mov") else {
            
            print("Could not find video file")
            return AVPlayer()
        }
        
        return AVPlayer(url: URL(fileURLWithPath: path))
        
    }()
    let homerVideoPlayer: AVPlayer = {
        //load Prague video from bundle
        //        guard let url = Bundle.main.url(forResource: "homer video", withExtension: "mov", subdirectory: "art.scnassets") else {
        //            print("Could not find video file")
        //            return AVPlayer()
        //        }
        //        return AVPlayer(url: url)
        
        
        guard let path = Bundle.main.path(forResource: "homer video", ofType:"mov") else {
            
            print("Could not find video file")
            return AVPlayer()
        }
        
        return AVPlayer(url: URL(fileURLWithPath: path))
    }()
    
    
    /// The view controller that displays the status and "restart experience" UI.
    lazy var statusViewController: StatusViewController = {
        return childViewControllers.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()
    
    /// A serial queue for thread safety when modifying the SceneKit node graph.
    let updateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! +
        ".serialSceneKitQueue")
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        radarView?.delegate = self
//        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(addItem), userInfo: nil, repeats: true)
        
        
        self.disableViews()
        
        
        
        sceneView.delegate = self
        sceneView.session.delegate = self as ARSessionDelegate
        magicSwitch.setOn(false, animated: false)
        
        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }
    }
    
    
    @objc func addItem() {
            if index > 3 {
                addMultipleItems()
                timer?.invalidate()
                return
            }
            let item = Item(uniqueKey: "item\(index)", value:"item\(index)")
            items.append(item)
            radarView?.add(item: item)
            index += 1
        }
        
        func addMultipleItems() {
            var tempItems = [Item]()
            for _ in 0 ..< 3 {
                let item = Item(uniqueKey: "item\(index)", value:"item\(index)")
                tempItems.append(item)
                index += 1
            }
            items.append(contentsOf: tempItems)
            radarView?.add(items: tempItems)
    //        Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(removeFirstItem), userInfo: nil, repeats: false)
        }
        
        @objc func removeFirstItem() {
            radarView?.remove(item: items.first!)
        }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Prevent the screen from being dimmed to avoid interuppting the AR experience.
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Start the AR experience
        resetTracking()
        
        
        disableViews()
    }
    
    func disableViews(){
        //self.imageViewSearch.isHidden = true;
        self.radarView.isHidden = true;
        self.magicSwitch.isOn = false;
        lblState.text = "Start searching.."
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        session.pause()
    }
    
    // MARK: - Session management (Image detection setup)
    
    /// Prevents restarting the session while a restart is in progress.
    var isRestartAvailable = true
    
    @IBAction func switchOnMagic(_ sender: UISwitch) {
        let configuration = ARImageTrackingConfiguration()
        
        guard let trackingImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            print("Could not load images")
            return
        }
        
        // Setup Configuration
        configuration.trackingImages = trackingImages
        //configuration.maximumNumberOfTrackedImages = 4
        configuration.maximumNumberOfTrackedImages = 1;
        //        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        
        if sender.isOn {
//            self.imageViewSearch.isHidden = false
            self.radarView.isHidden = false;
            lblState.text = "Stop searching"
            Sound.play(file: "search.wav")

            session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }else{
//            self.imageViewSearch.isHidden = true;
            self.radarView.isHidden = true;
            lblState.text = "Start searching..."
            Sound.stopAll()
            session.pause()
            
        }
    }
    
    
    /// Creates a new AR configuration to run on the `session`.
    /// - Tag: ARReferenceImage-Loading
    func resetTracking() {
        
        let configuration = ARImageTrackingConfiguration()
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // MARK: - Image Tracking Results
    
    public func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        
        // Show video overlaid on image
        if let imageAnchor = anchor as? ARImageAnchor {
            
            // Create a plane
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            //            if imageAnchor.referenceImage.name == "prague image" {
//            if imageAnchor.referenceImage.name == "hegazy1"{
            if imageAnchor.referenceImage.name == "marker"{
                debugPrint("marker")
            
                // Set AVPlayer as the plane's texture and play
                //plane.firstMaterial?.diffuse.contents = self.pragueVideoPlayer
                //self.pragueVideoPlayer.play()
                //self.pragueVideoPlayer.volume = 0.4
                
                //go to portal
                goToPortal()
                
                
            }
            
            
            //            else if imageAnchor.referenceImage.name == "fight club image" {
            ////               else  if imageAnchor.referenceImage.name == "hegazy1"{
            //
            //                plane.firstMaterial?.diffuse.contents = self.fightClubVideoPlayer
            //                self.fightClubVideoPlayer.play()
            //            } else if imageAnchor.referenceImage.name == "homer image" {
            //                plane.firstMaterial?.diffuse.contents = self.homerVideoPlayer
            //                self.homerVideoPlayer.play()
            //            } else {
            //                plane.firstMaterial?.diffuse.contents = self.isaVideoPlayer
            //                self.isaVideoPlayer.play()
            //                self.isaVideoPlayer.isMuted = true
            //            }
            
            let planeNode = SCNNode(geometry: plane)
            
            // Rotate the plane to match the anchor
            planeNode.eulerAngles.x = -.pi / 2
            
            // Add plane node to parent
            node.addChildNode(planeNode)
        }
        
        return node
    }
    
    
    func goToPortal(){
        
        //self.pragueVideoPlayer.pause()
        //self.session.pause()
        
        ///instantiate-and-present-a-viewcontroller-in-swift
        DispatchQueue.main.async {
            
            self.dismiss(animated: true) {
                
            }
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "PortalViewController")
            controller.modalPresentationStyle = .fullScreen
            controller.modalTransitionStyle = .flipHorizontal
            self.present(controller, animated: true, completion: nil)
            
            
            
        }
        
        
        
    }
    
}

@available(iOS 12.0, *)
extension ImgTrackingViewController: RadarViewDelegate {
    func radarView(radarView: RadarView, didSelect item: Item) {
        print(item.uniqueKey)
    }
    
    func radarView(radarView: RadarView, didDeselect item: Item) {}
    
    func radarView(radarView: RadarView, didDeselectAllItems lastSelectedItem: Item) {}
}
