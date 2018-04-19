//
//  ViewController.swift
//  CoreMotionTest
//
//  Created by Gentrit Abazi on /1504/18.
//  Copyright © 2018 Gentrit Abazi. All rights reserved.
//

import UIKit
import CoreMotion
import CoreLocation

class ViewController: UIViewController, StreamDelegate{
    
    let locationManager = CLLocationManager()
    let motionManager = CMMotionManager()
    let host = "192.168.0.156"
    @IBOutlet weak var xValue: UILabel!
    @IBOutlet weak var yValue: UILabel!
    @IBOutlet weak var zValue: UILabel!
    @IBOutlet weak var wValue: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startReceivingLocationChanges()
        getCoreMotionData()
    }
    
    func startReceivingLocationChanges(){
        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
    }
    
    func getCoreMotionData(){
        setUpStreams(host: host)
        motionManager.startDeviceMotionUpdates(to: OperationQueue()) { (data, error) in
            guard let data = data else {
                print("Error: \(error!)")
                return
            }
            let attitude: CMAttitude = data.attitude
            let quaternion = attitude.quaternion
            var motionData = MotionData()
            motionData.x = quaternion.x
            motionData.y = quaternion.y
            motionData.z = quaternion.z
            motionData.w = quaternion.w
            DispatchQueue.main.async{
                self.xValue.text = String(motionData.x)
                self.yValue.text = String(motionData.y)
                self.zValue.text = String(motionData.z)
                self.wValue.text = String(motionData.w)
            }

            let encoder = JSONEncoder()
            do {
                let json = try encoder.encode(motionData)
                self.send(data: json)
            } catch let error {
                print("Couldn't send data, error: \(error)")
            }
        }
    }
    
    

    
    // MARK: - Streams
    
    var inputStream: InputStream?
    var outputStream: OutputStream?
    
    func setUpStreams(host: String) {
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault,
                                           host as CFString, 9845,
                                           &readStream,
                                           &writeStream)
        inputStream = readStream!.takeRetainedValue()
        outputStream = writeStream!.takeRetainedValue()
        guard let inputStream = inputStream, let outputStream = outputStream else {
            print("Failed to create streams")
            return
        }
        inputStream.delegate = self
        outputStream.delegate = self
        inputStream.schedule(in: .current, forMode: .commonModes)
        outputStream.schedule(in: .current, forMode: .commonModes)
        inputStream.open()
        outputStream.open()
    }
    
    func send(data: Data) {
        guard let outputStream = outputStream else {return}
        _ = data.withUnsafeBytes {outputStream.write($0, maxLength: data.count)}
        
    }

}

// MARK: - Data Model
private struct MotionData: Codable {
    var x: Double = 0
    var y: Double = 0
    var z: Double = 0
    var w: Double = 0
}
