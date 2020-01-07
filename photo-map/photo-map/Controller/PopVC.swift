//
//  PopVC.swift
//  photo-map
//
//  Created by Kilyan SOCKALINGUM on 07/01/2020.
//  Copyright © 2020 Kilyan SOCKALINGUM. All rights reserved.
//

import UIKit

class PopVC: UIViewController, UIGestureRecognizerDelegate {
    //Outlets
    @IBOutlet weak var popImageView: UIImageView!
    
    //Variables
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        popImageView.image = image
        
        addDoubleTap()
    }
    
    func initData(forImage image: UIImage) {
        self.image = image
    }
    
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapHandler))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        view.addGestureRecognizer(doubleTap)
    }
    
    @objc func doubleTapHandler() {
        dismiss(animated: true, completion: nil)
    }
}
