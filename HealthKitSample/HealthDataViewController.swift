//
//  HealthDataViewController.swift
//  HealthKitSample
//
//  Created by Pavel Deinega on 11/24/17.
//  Copyright © 2017 Pavel Deinega. All rights reserved.
//

import UIKit

class HealthDataViewController: UIViewController {
    @IBOutlet weak var healthDataTableView: UITableView!
    let sectionHeaders: [HealthKitObjectType] = [.dateOfBirth, .sleepAnalysis, .heartRate, .dietaryEnergy, .steps, .weight, .activeEnergy, .walkingRunningDistance]
    var data = [HealthKitObjectType: String]()
    let healthStorageManager = HealthKitStorageManagerFactory.default()
    private let dispatchGroup = DispatchGroup()
    private var serialQueue = DispatchQueue(label: "my.serial.queue")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadData()
    }
    
    private func loadData() {
        serialQueue.async { [weak self] in
            guard let strongSelf = self else { return }
            for index in strongSelf.sectionHeaders.indices {
                guard let objectType = HealthKitObjectType(rawValue: index) else { continue }
                let completion: (String?) -> () = {
                    if let value = $0 {
                        strongSelf.data[objectType] = value
                    }
                    strongSelf.dispatchGroup.leave()
                }

                strongSelf.dispatchGroup.enter()
                switch objectType {
                case .dateOfBirth:
                    if let text = try? strongSelf.healthStorageManager.getDateOfBirth() {
                        strongSelf.data[objectType] = text
                    }
                    strongSelf.dispatchGroup.leave()
                case .sleepAnalysis: strongSelf.healthStorageManager.getSleepAnalysis(completion: completion)
                case .heartRate: strongSelf.healthStorageManager.getHeartRate(completion: completion)
                case .dietaryEnergy: strongSelf.healthStorageManager.getDietaryEnergy(completion: completion)
                case .steps: strongSelf.healthStorageManager.getSteps(completion: completion)
                case .weight: strongSelf.healthStorageManager.getWeight(completion: completion)
                case .activeEnergy: strongSelf.healthStorageManager.getActiveEnergy(completion: completion)
                case .walkingRunningDistance: strongSelf.healthStorageManager.getWalkingRunningDistance(completion: completion)
                }
            }
            _ = strongSelf.dispatchGroup.wait(timeout: .now() + 25)
            strongSelf.dispatchGroup.notify(queue: .main, execute: {
                strongSelf.healthDataTableView.reloadData()
            })
        }
    }
}

extension HealthDataViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 8
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: "HealthDataCell"),
            let objectType = HealthKitObjectType(rawValue: indexPath.section)
        else {
            return UITableViewCell()
        }
        
        cell.textLabel?.text = nil
        if let text = data[objectType] {
            cell.textLabel?.text = text
        }
        
        return cell
    }
    
    // MARK: Helpers
    
//    private func fillCell(_ cell: UITableViewCell, type: HealthKitObjectType) {
//
//        switch type {
//        case .dateOfBirth:
//            if let text = try? healthStorageManager.getDateOfBirth() {
//                cell.textLabel?.text = text
//            }
//        case .sleepAnalysis: healthStorageManager.getSleepAnalysis(completion: completion)
//        case .heartRate: healthStorageManager.getHeartRate(completion: completion)
//        case .dietaryEnergy: healthStorageManager.getDietaryEnergy(completion: completion)
//        case .steps: healthStorageManager.getSteps(completion: completion)
//        case .weight: healthStorageManager.getWeight(completion: completion)
//        case .activeEnergy: healthStorageManager.getActiveEnergy(completion: completion)
//        case .walkingRunningDistance: healthStorageManager.getWalkingRunningDistance(completion: completion)
//        }
//    }
}

extension HealthDataViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionHeaders[section].stringValue()
    }
}
