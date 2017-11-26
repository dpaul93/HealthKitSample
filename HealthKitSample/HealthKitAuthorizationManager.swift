//
//  HealthKitAuthorizationManager.swift
//  HealthKitSample
//
//  Created by Pavel Deinega on 11/24/17.
//  Copyright © 2017 Pavel Deinega. All rights reserved.
//

import HealthKit

enum HealthKitObjectType: Int {
    case dateOfBirth
    case sleepAnalysis
    case heartRate
    case dietaryEnergy
    case steps
    case weight
    case activeEnergy
    case walkingRunningDistance
    
    func stringValue() -> String {
        switch self {
        case .dateOfBirth: return "Date of birth"
        case .sleepAnalysis: return "Sleep analysis"
        case .heartRate: return "Heart rate"
        case .dietaryEnergy: return "Dietary energy"
        case .steps: return "Steps"
        case .weight: return "Weight"
        case .activeEnergy: return "Active energy"
        case .walkingRunningDistance: return "Walking and running distance"

        }
    }
}

// MARK: - Protocol

protocol HealthKitAuthorizationManager {
    func isAuthorized() -> Bool
    func authorize(completion: @escaping (Bool, Error?) -> ())
}

// MARK: - Implementation

private class HealthKitAuthorizationManagerImpl: HealthKitAuthorizationManager {
    private enum HealthkitSetupError: Error {
        case notAvailableOnDevice
        case dataTypeNotAvailable
    }
    
    func isAuthorized() -> Bool {
        guard
            let dateOfBirth = HKObjectType.characteristicType(forIdentifier: .dateOfBirth),
            let dietaryEnergy = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed),
            let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate),
            let sleepAnalysis = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
            let steps = HKObjectType.quantityType(forIdentifier: .stepCount),
            let weight = HKObjectType.quantityType(forIdentifier: .bodyMass),
            let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            let walkingRunningDistance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)
        else {
            return false
        }
        
        let healthStore = HKHealthStore()
        let types = [dateOfBirth,
                     dietaryEnergy,
                     heartRate,
                     sleepAnalysis,
                     steps,
                     weight,
                     activeEnergy,
                     walkingRunningDistance]

        for type in types {
            if healthStore.authorizationStatus(for: type) != .sharingAuthorized {
                return false
            }
        }
        
        return true
    }
    
    func authorize(completion: @escaping (Bool, Error?) -> ()) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, HealthkitSetupError.notAvailableOnDevice)
            return
        }
        
        guard
            let dateOfBirth = HKObjectType.characteristicType(forIdentifier: .dateOfBirth),
            let dietaryEnergy = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed),
            let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate),
            let sleepAnalysis = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
            let steps = HKObjectType.quantityType(forIdentifier: .stepCount),
            let weight = HKObjectType.quantityType(forIdentifier: .bodyMass),
            let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            let walkingRunningDistance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)
        else {
            completion(false, HealthkitSetupError.dataTypeNotAvailable)
            return
        }
        
        let healthKitTypesToWrite: Set<HKSampleType> = [activeEnergy,
                                                        weight,
                                                        HKObjectType.workoutType()]
        
        let healthKitTypesToRead: Set<HKObjectType> = [dateOfBirth,
                                                       dietaryEnergy,
                                                       heartRate,
                                                       sleepAnalysis,
                                                       steps,
                                                       weight,
                                                       activeEnergy,
                                                       walkingRunningDistance,
                                                       HKObjectType.workoutType()]
        
        HKHealthStore().requestAuthorization(toShare: healthKitTypesToWrite,
                                             read: healthKitTypesToRead) { (success, error) in
                                                completion(success, error)
        }
    }
}

// MARK: - Factory

class HealthKitAuthorizationManagerFactory {
    static func `default`() -> HealthKitAuthorizationManager {
        return HealthKitAuthorizationManagerImpl()
    }
}
