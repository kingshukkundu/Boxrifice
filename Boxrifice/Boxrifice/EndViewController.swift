//
//  EndViewController.swift
//  Boxrifice
//
//  Created by Kingshuk Kundu on 12/9/20.
//

import UIKit

class EndViewController: UIViewController {
    
    @IBOutlet weak var scoreLabel: UILabel!
    var scoreData:String!
    
    //Show scoreData to the user passed in from previous class using scoreLabel
    override func viewDidLoad() {
        super.viewDidLoad()
        scoreLabel.text = scoreData
    }
    
    //Dismiss the previous UIViewController and current UIViewController
    @IBAction func restartGame(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
        self.presentingViewController?.dismiss(animated: false, completion: nil)
    }
    
    
}
