//
//  ViewController.swift
//  Example
//
//  Created by Rudd Fawcett on 4/28/20.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var strokeTimer: BZYStrokeTimer!
    var longPressGesture: UILongPressGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setup()
    }
    
    func setup() {
        self.strokeTimer.duration = 3
        self.strokeTimer.lineWidth = 10
        self.strokeTimer.timerColor = .systemBlue
        
        self.longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))
        self.view.addGestureRecognizer(self.longPressGesture)
    }
    
    @objc func handleLongPress(sender: Any) {
        if self.longPressGesture.state == .began {
            if self.strokeTimer.paused {
                self.strokeTimer.resume()
            }
            
            if !self.strokeTimer.running {
                self.strokeTimer.start()
            }
        } else if (self.longPressGesture.state == .ended ||
            self.longPressGesture.state == .failed ||
            self.longPressGesture.state == .cancelled) && self.strokeTimer.running {
            self.strokeTimer.pause()
        }
    }
}
