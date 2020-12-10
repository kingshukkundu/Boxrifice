//
//  InitialViewController.swift
//  Boxrifice
//
//  Created by Kingshuk Kundu on 12/8/20.
//

import UIKit

class InitialViewController: UIViewController {
    
    @IBOutlet weak var highScoreLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    //To display new highest score everytime the following code is included in the
    //viewWillAppear instead of viewDidLoad
    override func viewWillAppear(_ animated: Bool) {
        //show all time highest score in highScoreLabel
        let userDefaults = Foundation.UserDefaults.standard
        let highScore = userDefaults.string(forKey: "highScore")
        //if user is playing the game for the first time, show 0 as highest score
        if highScore == nil {
            highScoreLabel.text = "0"
        }
        else{
            highScoreLabel.text = highScore
        }
    }
    
}
