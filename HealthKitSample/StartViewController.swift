//
//  StartViewController.swift
//  HealthKitSample
//
//  Created by Pavel Deinega on 11/24/17.
//  Copyright © 2017 Pavel Deinega. All rights reserved.
//

import UIKit

class StartViewController: UIViewController {
    @IBOutlet weak var authLabel: UILabel!
    let authManager = HealthKitAuthorizationManagerFactory.default()
    
    override func viewDidLoad() {
        updateAuthStatus()
    }
    
    @IBAction func onRequestAuthDidTap(_ sender: Any) {
        authManager.authorize {[weak self] (status, error) in
            if let error = error {
                self?.updateAuthLabel(error.localizedDescription)
            } else {
                self?.updateAuthStatus()
            }
        }
    }
    
    private func updateAuthStatus() {
        let status = authManager.isAuthorized() ? "Authorized" : "Not authorized"
        updateAuthLabel(status)
    }
    
    private func updateAuthLabel(_ text: String) {
        authLabel.text = text
    }
}
