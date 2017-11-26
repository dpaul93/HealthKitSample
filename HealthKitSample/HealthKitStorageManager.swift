//
//  HealthKitStorageManager.swift
//  HealthKitSample
//
//  Created by Pavel Deinega on 11/24/17.
//  Copyright © 2017 Pavel Deinega. All rights reserved.
//

import HealthKit

// MARK: - Protocol

protocol HealthKitStorageManager {
    func getDateOfBirth() throws -> String?
    func getSleepAnalysis(completion: @escaping (String?) -> ())
    func getHeartRate(completion: @escaping (String?) -> ())
    func getDietaryEnergy(completion: @escaping (String?) -> ())
    func getSteps(completion: @escaping (String?) -> ())
    func getWeight(completion: @escaping (String?) -> ())
    func getActiveEnergy(completion: @escaping (String?) -> ())
    func getWalkingRunningDistance(completion: @escaping (String?) -> ())
}

// MARK: - Implementation

private class HealthKitStorageManagerImpl: HealthKitStorageManager {
    private let healthStorage: HKHealthStore
    
    init(healthStorage: HKHealthStore) {
        self.healthStorage = healthStorage
    }
    
    // MARK: HealthKitStorageManager
    
    func getDateOfBirth() throws -> String? {
        do {
            let birthdayComponents = try healthStorage.dateOfBirthComponents()
            if let year = birthdayComponents.year,
                let month = birthdayComponents.month,
                let day = birthdayComponents.day {
                return "\(day).\(month).\(year)"
            }
        }
        return nil
    }
    
    func getSleepAnalysis(completion: @escaping (String?) -> ()) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis) else {
            completion(nil)
            return
        }
        
        getSampleType(sampleType: sleepType) { (query, results, error) in
            guard
                let results = results,
                let data = results.first as? HKCategorySample
            else {
                completion(nil)
                return
            }
            
            let value = (data.value == HKCategoryValueSleepAnalysis.inBed.rawValue) ? "InBed" : "Asleep"
            completion("Healthkit sleep: \(data.startDate) \(data.endDate) - value: \(value)")
        }
    }
    
    func getHeartRate(completion: @escaping (String?) -> ()) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(nil)
            return
        }
        
        getSampleType(sampleType: heartRateType) { (query, results, error) in
            guard
                let results = results,
                let data = results.first as? HKQuantitySample
            else {
                completion(nil)
                return
            }
            
            completion("Heart Rate: \(data.quantity.doubleValue(for: HKUnit(from: "count/min")))")
        }
    }
    
    func getDietaryEnergy(completion: @escaping (String?) -> ()) {
        guard let dietaryEnergyType = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed) else {
            completion(nil)
            return
        }
        
        getSampleType(sampleType: dietaryEnergyType) { (query, results, error) in
            guard
                let results = results,
                let data = results.first as? HKQuantitySample
            else {
                completion(nil)
                return
            }
            
            completion("Dietary Energy: \(data.quantity.doubleValue(for: HKUnit.joule()))")
        }
    }
    
    func getSteps(completion: @escaping (String?) -> ()) {
        guard let stepsCount = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) else {
            completion(nil)
            return
        }
        
        let today = Date()
        let calendar = Calendar(identifier: .gregorian)
        let startOfDay = calendar.startOfDay(for: today)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: today, options: .strictStartDate)
        var interval = DateComponents()
        interval.day = 1
        
        getStatisticsType(
            quantityType: stepsCount,
            quantitySamplePredicate: predicate
        ) { (query, results, error) in
            guard
                let sum = results?.sumQuantity()
            else {
                completion(nil)
                return
            }

            let stepsCount = sum.doubleValue(for: HKUnit.count())

            completion("Steps Count: \(stepsCount)")
        }
    }
    
    func getWeight(completion: @escaping (String?) -> ()) {
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            completion(nil)
            return
        }
        
        getSampleType(sampleType: weightType) { (query, results, error) in
            guard
                let results = results,
                let data = results.first as? HKQuantitySample
            else {
                completion(nil)
                return
            }
            
            completion("Weight: \(data.quantity.doubleValue(for: HKUnit.gram()))")
        }
    }
    
    func getActiveEnergy(completion: @escaping (String?) -> ()) {
        guard let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(nil)
            return
        }
        
        getSampleType(sampleType: activeEnergyType) { (query, results, error) in
            guard
                let results = results,
                let data = results.first as? HKQuantitySample
            else {
                completion(nil)
                return
            }
            
            completion("Active Energy: \(data.quantity.doubleValue(for: HKUnit.kilocalorie()))")
        }
    }
    
    func getWalkingRunningDistance(completion: @escaping (String?) -> ()) {
        guard let runningWalkingType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            completion(nil)
            return
        }
        
        getSampleType(sampleType: runningWalkingType) { (query, results, error) in
            guard
                let results = results,
                let data = results.first as? HKQuantitySample
            else {
                completion(nil)
                return
            }
            
            completion("Distance Walking Running: \(data.quantity.doubleValue(for: HKUnit.meter()))")
        }
    }
    
    // MARK: Helpers

    @discardableResult private func getSampleType(
        sampleType: HKSampleType,
        predicate: NSPredicate? = nil,
        descriptors: [NSSortDescriptor]? = [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)],
        limit: Int = 1,
        completion: @escaping (HKSampleQuery, [HKSample]?, Error?) -> ()
    ) -> HKSampleQuery {
        let sampleQuery = HKSampleQuery(
            sampleType: sampleType,
            predicate: predicate,
            limit: limit,
            sortDescriptors: descriptors
        ) { (query, results, error) in
            DispatchQueue.main.async {
                completion(query, results, error)
            }
        }
        
        healthStorage.execute(sampleQuery)
        
        return sampleQuery
    }
        
    @discardableResult private func getStatisticsType(
        quantityType: HKQuantityType,
        quantitySamplePredicate: NSPredicate,
        options: HKStatisticsOptions = [.cumulativeSum],
        completion: @escaping (HKStatisticsQuery, HKStatistics?, Error?) -> ()
    ) -> HKStatisticsQuery {
        let statisticsQuery = HKStatisticsQuery(
            quantityType: quantityType,
            quantitySamplePredicate: quantitySamplePredicate,
            options: options
        ) { (query, results, error) in
            DispatchQueue.main.async {
                completion(query, results, error)
            }
        }
        
        healthStorage.execute(statisticsQuery)
        
        return statisticsQuery
    }
}

// MARK: - Factory

class HealthKitStorageManagerFactory {
    static func `default`(
        healthStorage: HKHealthStore = HKHealthStore()
    ) -> HealthKitStorageManager {
        return HealthKitStorageManagerImpl(healthStorage: healthStorage)
    }
}
