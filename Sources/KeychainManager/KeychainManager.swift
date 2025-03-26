// The Swift Programming Language
// https://docs.swift.org/swift-book
//
//  KeychainManager.swift
//
//  Created by Saad Tahir on 04/02/2025.
//

import Foundation
import os.log

/// A singleton manager for handling Keychain operations such as saving, reading, updating, and deleting items.
/// Provides thread-safe methods for interacting with the iOS Keychain for secure data storage.
final class KeychainManager {
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "KeychainManager")

    
    /// An enumeration representing errors that can occur while interacting with the Keychain.
    public enum KeychainError: Error {
        /// Represents an unknown error, identified by an `OSStatus` error code.
        case unknown(OSStatus)
        
        case emptyService
        case emptyAccount
        case emptyAccessGroup
    }

    
    /// The shared instance of the `KeychainManager`, used to access and perform Keychain operations.
    public class var shared: KeychainManager {
        struct Singleton {
            static let instance = KeychainManager()
        }
        return Singleton.instance
    }

    
    /// Private method to save data to the Keychain.
    /// This method is used internally to store data associated with a service and account.
    /// If an item with the same service and account already exists,
    /// it will be updated with the new data.
    ///
    /// - Parameters:
    ///   - data: The data to be saved to the Keychain.
    ///   - service: The service identifier for the data.
    ///   - account: The account associated with the data.
    ///   - accessGroup: An optional access group identifier for shared Keychain access across apps.
    /// - Throws: `KeychainError.unknown` if the operation fails due to an OSStatus error.
    private func save(_ data: Data, service: String, account: String, accessGroup: String? = nil) throws {
        var query = [kSecClass as String: kSecClassGenericPassword,
                     kSecAttrService as String: service as AnyObject,
                     kSecAttrAccount as String: account as AnyObject,
                     kSecValueData as String: data as AnyObject] as [String: Any]
        
        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            logger.debug("Item already exists in Keychain.")
            do {
                try update(for: data, service: service, account: account)
            } catch {
                logger.error("Error updating item in keychain: \(error.localizedDescription)")
                throw KeychainError.unknown(status)
            }
        } else {
            guard status == errSecSuccess else {
                logger.error("Error saving item to keychain: \(status)")
                throw KeychainError.unknown(status)
            }
        }
    }
    
    
    /// Private method to update existing data in the Keychain.
    /// This method is used to modify data in the Keychain if it already exists.
    ///
    /// - Parameters:
    ///   - data: The new data to be updated in the Keychain.
    ///   - service: The service identifier for the data.
    ///   - account: The account associated with the data.
    ///   - accessGroup: An optional access group identifier for shared Keychain access across apps.
    /// - Throws: `KeychainError.unknown` if the operation fails due to an OSStatus error.
    private func update(for data: Data, service: String, account: String, accessGroup: String? = nil) throws {
        logger.debug("Updating data in keychain: service: \(service), account: \(account)")
        
        var query = [kSecClass as String: kSecClassGenericPassword,
                     kSecAttrService as String: service as AnyObject,
                     kSecAttrAccount as String: account as AnyObject] as [String: Any]
        
        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        
        let attributeToUpdate = [kSecValueData: data] as CFDictionary
        
        let status = SecItemUpdate(query as CFDictionary, attributeToUpdate)
        
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
        
        logger.debug("Successfully updated data in keychain.")
    }
    
    
    /// Private method to read data from the Keychain.
    /// This method retrieves the data associated with a given service and account.
    ///
    /// - Parameters:
    ///   - service: The service identifier for the data.
    ///   - account: The account associated with the data.
    ///   - accessGroup: An optional access group identifier for shared Keychain access across apps.
    /// - Returns: The data stored in the Keychain, or `nil` if the data is not found.
    /// - Note: The returned data is in `Data` format, and you should decode it accordingly.
    private func read(for service: String, account: String, accessGroup: String? = nil) -> Data? {
        var query = [kSecClass as String: kSecClassGenericPassword,
                     kSecAttrService as String: service as AnyObject,
                     kSecAttrAccount as String: account as AnyObject,
                     kSecReturnData as String: kCFBooleanTrue ?? true,
                     kSecMatchLimit as String: kSecMatchLimitOne] as [String: Any]
        
        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        
        var result: AnyObject?
        
        SecItemCopyMatching(query as CFDictionary, &result)
        
        var loggerMessage = ""
        if result != nil {
            loggerMessage = "Successfully found data in keychain."
        } else {
            loggerMessage = "Error reading item from keychain"
        }
        logger.debug("\(loggerMessage)")
        
        return (result as? Data)
    }

    
    /// Private method to checks whether the `service`, `account`, and `accessGroup` (if provided) are non-empty strings.
    /// If any of these parameters are empty, it returns a corresponding `KeychainError`. If all parameters are valid, it returns `nil`.
    ///
    /// - Parameters:
    ///   - service: The identifier for the Keychain service. This value must not be empty.
    ///   - account: The identifier for the account associated with the Keychain item. This value must not be empty.
    ///   - accessGroup: An optional identifier for the access group for shared Keychain access across apps. If provided, this value must not be empty.
    /// - Returns:
    ///   - `KeychainError?`: Returns a `KeychainError` if any of the parameters are empty:
    ///     - `.emptyService` if `service` is empty.
    ///     - `.emptyAccount` if `account` is empty.
    ///     - `.emptyAccessGroup` if `accessGroup` is empty.
    ///   - Returns `nil` if all parameters are valid (non-empty).
    /// - Note: This method is used to validate the inputs before performing Keychain operations such as saving, reading, or deleting items.
    private func validateKeychainParameters(service: String, account: String, accessGroup: String?) -> KeychainError? {
        if service.isEmpty {
            return KeychainError.emptyService
        }
        
        if account.isEmpty {
            return KeychainError.emptyAccount
        }
        
        if let group = accessGroup, group.isEmpty {
            return KeychainError.emptyAccessGroup
        }
        
        return nil
    }
}

extension KeychainManager {
    /// Saves a Codable item to the Keychain.
    ///
    /// - Parameters:
    ///   - item: The `Codable` item to be saved to the Keychain.
    ///   - service: The service identifier for the data.
    ///   - account: The account associated with the data.
    ///   - accessGroup: An optional access group identifier for shared Keychain access across apps.
    ///   - completion: A closure that is called once the operation is completed. It returns a `Result<Bool, Error>` indicating whether the operation was successful or not.
    /// - Returns: A `Bool` indicating if the operation was started successfully. If it returns `false`, the operation failed before it could begin.
    @discardableResult
    func save<T: Codable>(_ item: T, service: String, account: String, accessGroup: String? = nil, completion: ((Result<Bool, Error>) -> ())? = nil) -> Bool {
        logger.debug("Starting to save data in keychain: service: \(service), account: \(account)")
        
        if let validationError = validateKeychainParameters(service: service, account: account, accessGroup: accessGroup) {
            logger.error("Failed to save item to Keychain: \(validationError)")
            completion?(.failure(validationError))
            return false
        }
        
        var data = Data()
        do {
            data = try JSONEncoder().encode(item)
            try save(data, service: service, account: account)
            logger.debug("Item saved successfully: service: \(service), account: \(account)")
            
            completion?(.success(true))
            return true
            
        } catch KeychainError.unknown(let error_) {
            logger.error("Failed to save item to Keychain: \(error_)")
            completion?(.failure(KeychainError.unknown(error_)))
            return false
            
        } catch {
            logger.error("Failed to encode item for keychain: \(error.localizedDescription)")
            completion?(.failure(error))
            return false
        }
    }
    
    
    /// Reads a `Codable` item from the Keychain based on the provided service and account.
    /// If the item is found, it will be decoded into the specified `Codable` type.
    ///
    /// - Parameters:
    ///   - service: The service identifier for the data.
    ///   - account: The account associated with the data.
    ///   - accessGroup: An optional access group identifier for shared Keychain access across apps.
    ///   - completion: A closure that is called once the operation is completed. It returns a `Result<T, Error>` with the decoded item or an error if it fails.
    /// - Returns: A `Codable` indicating whether the operation was successful. If it returns `nil`, no data was found or the decoding failed.
    func read<T: Codable>(for service: String, account: String, accessGroup: String? = nil, completion: ((Result<T, Error>) -> ())? = nil) -> T? {
        logger.debug("Reading item from keychain: service: \(service), account: \(account)")

        if let validationError = validateKeychainParameters(service: service, account: account, accessGroup: accessGroup) {
            logger.error("Failed to retreive item from Keychain: \(validationError)")
            completion?(.failure(validationError))
            return nil
        }
        
        guard let data = read(for: service, account: account) else {
            logger.error("Item not found in keychain: service: \(service), account: \(account)")
            completion?(.failure(KeychainError.unknown(errSecItemNotFound)))
            return nil
        }
        
        do {
            let item = try JSONDecoder().decode(T.self, from: data)
            logger.debug("Successfully decoded item from keychain.")
            
            completion?(.success(item))
            return item
            
        } catch {
            logger.error("Failed to decode item from keychain: \(error.localizedDescription)")
            completion?(.failure(error))
            return nil
        }
    }
    
    
    /// Deletes an item from the Keychain based on the provided service and account.
    /// The item is removed from the Keychain storage if it exists.
    ///
    /// - Parameters:
    ///   - service: The service identifier for the data.
    ///   - account: The account associated with the data.
    ///   - accessGroup: An optional access group identifier for shared Keychain access across apps.
    ///   - completion: A closure that is called once the operation is completed. It returns a `Result<Bool, Error>` indicating the success or failure of the operation.
    /// - Returns: A `Bool` indicating whether the deletion operation was successful. If it returns `false`, the operation failed or no item was found.
    @discardableResult
    func delete(for service: String, account: String, accessGroup: String? = nil, completion: ((Result<Bool, Error>) -> ())? = nil) -> Bool {
        logger.debug("Deleting item from keychain: service: \(service), account: \(account)")
        
        if let validationError = validateKeychainParameters(service: service, account: account, accessGroup: accessGroup) {
            logger.error("Failed to delete item from Keychain: \(validationError)")
            completion?(.failure(validationError))
            return false
        }
        
        var query = [kSecClass as String: kSecClassGenericPassword,
                     kSecAttrService as String: service as AnyObject,
                     kSecAttrAccount as String: account as AnyObject] as [String: Any]
        
        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess {
            logger.debug("Item successfully deleted from keychain.")
            completion?(.success(true))
            return true
            
        } else {
            logger.error("Failed to delete item from keychain: \(status)")
            completion?(.failure(KeychainError.unknown(status)))
            return false
        }
    }
}
