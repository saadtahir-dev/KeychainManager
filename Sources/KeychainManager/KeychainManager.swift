//
//  KeychainManager.swift
//  A singleton manager for handling Keychain operations such as saving, reading, updating, and deleting items.
//  Provides thread-safe methods for interacting with the iOS Keychain for secure data storage.
//
//  Created by Saad Tahir on 04/02/2025.
//

import Foundation

final class KeychainManager {
    /// Logger
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "KeychainManager")
    
    /// Serial Dispatch Queue for synchronizing Keychain operations
    private let keychainQueue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).keychainQueue", attributes: .concurrent)
    
    /// An enumeration representing errors that can occur while interacting with the Keychain.
    public enum KeychainError: Error, LocalizedError {
        case OSStatusError(OSStatus)
        case emptyService
        case emptyAccount
        case emptyAccessGroup
        case itemNotFound
        
        public var errorDescription: String? {
            switch self {
            case .OSStatusError(let osStatus):
                return "Keychain error with OSStatus code: \(osStatus)"
                
            case .emptyService:
                return "The service parameter is empty. Please provide a valid service identifier."
                
            case .emptyAccount:
                return "The account parameter is empty. Please provide a valid account identifier."
                
            case .emptyAccessGroup:
                return "The access group parameter is empty. Please provide a valid access group identifier."
                
            case .itemNotFound:
                return "The item requested was not found in the Keychain."
            }
        }
    }
    
    /// The shared instance of the `KeychainManager`, used to access and perform Keychain operations.
    public class var shared: KeychainManager {
        struct Singleton {
            static let instance = KeychainManager()
        }
        return Singleton.instance
    }
    
    /// Exposed variable for access permission
    /// This will allow external code to get or set the access permission
    public var accessPermission: CFString = kSecAttrAccessibleAlways
}

extension KeychainManager {
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
    ///   - accessPermission: Specifies the access control for the Keychain item.
    /// - Throws: `KeychainError.unknown` if the operation fails due to an OSStatus error.
    private func _save(_ data: Data, service: String, account: String, accessGroup: String? = nil, accessPermission: CFString) throws {
        try keychainQueue.sync {
            var query = [kSecClass as String: kSecClassGenericPassword,
                         kSecAttrService as String: service as AnyObject,
                         kSecAttrAccount as String: account as AnyObject,
                         kSecValueData as String: data as AnyObject,
                         kSecAttrAccessible as String: accessPermission] as [String: Any]
            
            if let group = accessGroup {
                query[kSecAttrAccessGroup as String] = group
            }
            
            let status = SecItemAdd(query as CFDictionary, nil)
            
            if status == errSecDuplicateItem {
                logger.debug("Item already exists in Keychain.")
                do {
                    try _update(for: data, service: service, account: account, accessPermission: accessPermission)
                } catch {
                    logger.error("Error updating item in keychain: \(error.localizedDescription)")
                    throw KeychainError.OSStatusError(status)
                }
            } else {
                guard status == errSecSuccess else {
                    logger.error("Error saving item to keychain: \(status)")
                    throw KeychainError.OSStatusError(status)
                }
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
    ///   - accessPermission: Specifies the access control for the Keychain item.
    /// - Throws: `KeychainError.unknown` if the operation fails due to an OSStatus error.
    private func _update(for data: Data, service: String, account: String, accessGroup: String? = nil, accessPermission: CFString) throws {
        try keychainQueue.sync {
            logger.debug("Updating data in keychain: service: \(service), account: \(account)")
            
            var query = [kSecClass as String: kSecClassGenericPassword,
                         kSecAttrService as String: service as AnyObject,
                         kSecAttrAccount as String: account as AnyObject,
                         kSecAttrAccessible as String: accessPermission] as [String: Any]
            
            if let group = accessGroup {
                query[kSecAttrAccessGroup as String] = group
            }
            
            let attributeToUpdate = [kSecValueData: data] as CFDictionary
            
            let status = SecItemUpdate(query as CFDictionary, attributeToUpdate)
            
            guard status == errSecSuccess else {
                throw KeychainError.OSStatusError(status)
            }
            
            logger.debug("Successfully updated data in keychain.")
        }
    }
    
    
    /// Private method to read data from the Keychain.
    /// This method retrieves the data associated with a given service and account.
    ///
    /// - Parameters:
    ///   - service: The service identifier for the data.
    ///   - account: The account associated with the data.
    ///   - accessGroup: An optional access group identifier for shared Keychain access across apps.
    ///   - accessPermission: Specifies the access control for the Keychain item.
    /// - Returns: The data stored in the Keychain, or `nil` if the data is not found.
    /// - Note: The returned data is in `Data` format, and you should decode it accordingly.
    private func _read(for service: String, account: String, accessGroup: String? = nil, accessPermission: CFString) -> Data? {
        keychainQueue.sync {
            var query = [kSecClass as String: kSecClassGenericPassword,
                         kSecAttrService as String: service as AnyObject,
                         kSecAttrAccount as String: account as AnyObject,
                         kSecReturnData as String: kCFBooleanTrue ?? true,
                         kSecMatchLimit as String: kSecMatchLimitOne,
                         kSecAttrAccessible as String: accessPermission] as [String: Any]
            
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
    }
    
    
    /// Deletes an item from the Keychain for a given service and account.
    ///
    /// - Parameters:
    ///   - service: The service identifier for the Keychain item (e.g., your app’s bundle identifier or a custom service name).
    ///   - account: The account name associated with the Keychain item.
    ///   - accessGroup: An optional access group to which the Keychain item belongs. If not provided, the default access group is used.
    ///   - accessPermission: The access permission for the Keychain item, represented by a `CFString`. Example permissions include `kSecAttrAccessibleWhenUnlocked`.
    /// - Throws:
    ///   - `KeychainError.itemNotFound` if the item could not be found in the Keychain.
    ///   - `KeychainError.OSStatusError` for any other errors returned by the Keychain API.
    private func _delete(for service: String, account: String, accessGroup: String? = nil, accessPermission: CFString) throws {
        try keychainQueue.sync {
            var query = [kSecClass as String: kSecClassGenericPassword,
                         kSecAttrService as String: service as AnyObject,
                         kSecAttrAccount as String: account as AnyObject,
                         kSecAttrAccessible as String: accessPermission] as [String: Any]
            
            if let group = accessGroup {
                query[kSecAttrAccessGroup as String] = group
            }
            
            let status = SecItemDelete(query as CFDictionary)
            switch status {
            case errSecSuccess:
                logger.debug("Item successfully deleted from Keychain.")
                
            case errSecItemNotFound:
                logger.debug("Item not found in Keychain. No item to delete.")
                throw KeychainError.itemNotFound
                
            default:
                logger.debug("Failed to delete item from Keychain. OSStatus: \(status)")
                throw KeychainError.OSStatusError(status)
            }
        }
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
    private func _validateKeychainParameters(service: String, account: String, accessGroup: String?) -> KeychainError? {
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
    ///   - accessPermission: Specifies the access control for the Keychain item (default is `nil`).
    ///   - completion: A closure that is called once the operation is completed. It returns a `Result<Bool, Error>` indicating whether the operation was successful or not.
    /// - Returns: A `Bool` indicating if the operation was started successfully. If it returns `false`, the operation failed before it could begin.
    @discardableResult
    public func save<T: Codable>(_ item: T,
                                 service: String,
                                 account: String,
                                 accessGroup: String? = nil,
                                 accessPermission: CFString? = nil,
                                 completion: ((Result<Bool, Error>) -> ())? = nil) -> Bool {
        logger.debug("Starting to save data in keychain: service: \(service), account: \(account)")
        
        if let validationError = _validateKeychainParameters(service: service, account: account, accessGroup: accessGroup) {
            logger.error("Failed to save item to Keychain: \(validationError)")
            completion?(.failure(validationError))
            return false
        }
        
        var data = Data()
        do {
            data = try JSONEncoder().encode(item)
            try _save(data, service: service, account: account, accessPermission: accessPermission ?? self.accessPermission)
            logger.debug("Item saved successfully: service: \(service), account: \(account)")
            
            completion?(.success(true))
            return true
            
        } catch KeychainError.OSStatusError(let error_) {
            logger.error("Failed to save item to Keychain: \(error_)")
            completion?(.failure(KeychainError.OSStatusError(error_)))
            return false
            
        } catch {
            logger.error("Failed to encode item for keychain: \(error.localizedDescription)")
            completion?(.failure(error))
            return false
        }
    }
    
    
    /// Asynchronously saves a Codable item securely in the Keychain with the specified parameters.
    ///
    /// - Parameters:
    ///   - item: The `Codable` item to be saved. This item will be encoded to `Data` before being saved.
    ///   - service: The service identifier for the Keychain item. This helps categorize and access the item.
    ///   - account: The account identifier associated with the Keychain item.
    ///   - accessGroup: (Optional) An access group identifier for shared Keychain access across apps. Default is `nil`.
    ///   - accessPermission: (Optional) Specifies the access control for the Keychain item (default is `nil`).
    /// - Returns: A `Result<Bool, Error>` indicating whether the save operation was successful (`true`) or failed (`false`).
    public func save<T: Codable>(_ item: T,
                                 service: String,
                                 account: String,
                                 accessGroup: String? = nil,
                                 accessPermission: CFString? = nil) async -> Result<Bool, Error> {
        logger.debug("Starting to save data in keychain: service: \(service), account: \(account)")
        
        // Validate parameters
        if let validationError = _validateKeychainParameters(service: service, account: account, accessGroup: accessGroup) {
            logger.error("Failed to save item to Keychain: \(validationError)")
            return .failure(validationError)
        }
        
        var data = Data()
        do {
            data = try JSONEncoder().encode(item)
            try _save(data, service: service, account: account, accessPermission: accessPermission ?? self.accessPermission)
            logger.debug("Item saved successfully: service: \(service), account: \(account)")
            
            return .success(true)
            
        } catch KeychainError.OSStatusError(let error_) {
            logger.error("Failed to save item to Keychain: \(error_)")
            return .failure(KeychainError.OSStatusError(error_))
            
        } catch {
            logger.error("Failed to encode item for keychain: \(error.localizedDescription)")
            return .failure(error)
        }
    }
}

extension KeychainManager {
    /// Reads a `Codable` item from the Keychain based on the provided service and account.
    /// If the item is found, it will be decoded into the specified `Codable` type.
    ///
    /// - Parameters:
    ///   - service: The service identifier for the data.
    ///   - account: The account associated with the data.
    ///   - accessGroup: An optional access group identifier for shared Keychain access across apps.
    ///   - accessPermission: Specifies the access control for the Keychain item (default is `nil`).
    ///   - completion: A closure that is called once the operation is completed. It returns a `Result<T, Error>` with the decoded item or an error if it fails.
    /// - Returns: A `Codable` indicating whether the operation was successful. If it returns `nil`, no data was found or the decoding failed.
    public func read<T: Codable>(for service: String,
                                 account: String,
                                 accessGroup: String? = nil,
                                 accessPermission: CFString? = nil,
                                 completion: ((Result<T, Error>) -> ())? = nil) -> T? {
        logger.debug("Reading item from keychain: service: \(service), account: \(account)")
        
        if let validationError = _validateKeychainParameters(service: service, account: account, accessGroup: accessGroup) {
            logger.error("Failed to retreive item from Keychain: \(validationError)")
            completion?(.failure(validationError))
            return nil
        }
        
        guard let data = _read(for: service, account: account, accessPermission: accessPermission ?? self.accessPermission)
        else {
            logger.error("Item not found in keychain: service: \(service), account: \(account)")
            completion?(.failure(KeychainError.itemNotFound))
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
    
    
    /// Asynchronously reads a `Codable` item from the Keychain based on the provided service and account.
    ///
    /// - Parameters:
    ///   - service: The service identifier for the data.
    ///   - account: The account associated with the data.
    ///   - accessGroup: An optional access group identifier for shared Keychain access across apps.
    ///   - accessPermission: Specifies the access control for the Keychain item (default is `nil`).
    /// - Returns: A `Result<T, Error>` where:
    ///     - `.success(item)` if the item was found and decoded successfully.
    ///     - `.failure(error)` if an error occurred during reading or decoding.
    public func read<T: Codable>(for service: String,
                                 account: String,
                                 accessGroup: String? = nil,
                                 accessPermission: CFString? = nil) async -> Result<T, Error> {
        logger.debug("Reading item from keychain: service: \(service), account: \(account)")
        
        if let validationError = _validateKeychainParameters(service: service, account: account, accessGroup: accessGroup) {
            logger.error("Failed to retrieve item from Keychain: \(validationError)")
            return .failure(validationError)
        }
        
        guard let data = _read(for: service, account: account, accessPermission: accessPermission ?? self.accessPermission)
        else {
            logger.error("Item not found in keychain: service: \(service), account: \(account)")
            return .failure(KeychainError.itemNotFound)
        }
        
        do {
            let item = try JSONDecoder().decode(T.self, from: data)
            logger.debug("Successfully decoded item from keychain.")
            return .success(item)
            
        } catch {
            logger.error("Failed to decode item from keychain: \(error.localizedDescription)")
            return .failure(error)
        }
    }
}

extension KeychainManager {
    /// Deletes an item from the Keychain based on the provided service and account.
    /// The item is removed from the Keychain storage if it exists.
    ///
    /// - Parameters:
    ///   - service: The service identifier for the data.
    ///   - account: The account associated with the data.
    ///   - accessGroup: An optional access group identifier for shared Keychain access across apps.
    ///   - accessPermission: Specifies the access control for the Keychain item (default is `nil`).
    ///   - completion: A closure that is called once the operation is completed. It returns a `Result<Bool, Error>` indicating the success or failure of the operation.
    /// - Returns: A `Bool` indicating whether the deletion operation was successful. If it returns `false`, the operation failed or no item was found.
    public func delete(for service: String,
                       account: String,
                       accessGroup: String? = nil,
                       accessPermission: CFString? = nil,
                       completion: ((Result<Bool, Error>) -> ())? = nil) {
        logger.debug("Deleting item from keychain: service: \(service), account: \(account)")
        
        if let validationError = _validateKeychainParameters(service: service, account: account, accessGroup: accessGroup) {
            logger.error("Failed to delete item from Keychain: \(validationError)")
            completion?(.failure(validationError))
            return
        }
        
        do {
            try _delete(for: service, account: account, accessGroup: accessGroup, accessPermission: accessPermission ?? self.accessPermission)
            logger.debug("Item deleted successfully: service: \(service), account: \(account)")
            completion?(.success(true))
            
        } catch KeychainError.itemNotFound {
            logger.debug("Item not found in Keychain. Treated as successful deletion.")
            completion?(.success(false))
            
        } catch KeychainError.OSStatusError(let error) {
            logger.error("Failed to delete item from Keychain: \(error)")
            completion?(.failure(KeychainError.OSStatusError(error)))
            
        } catch {
            logger.error("Unexpected error occurred while deleting item from Keychain: \(error)")
            completion?(.failure(error))
        }
    }
    
    
    /// Asynchronously deletes an item from the Keychain based on the provided service and account.
    /// The item is removed from the Keychain storage if it exists.
    ///
    /// - Parameters:
    ///   - service: The service identifier for the data.
    ///   - account: The account associated with the data.
    ///   - accessGroup: An optional access group identifier for shared Keychain access across apps.
    ///   - accessPermission: Specifies the access control for the Keychain item (default is `nil`).
    /// - Returns: A `Result<Bool, Error>` indicating the success or failure of the operation.
    ///     - `.success(true)` if the deletion was successful.
    ///     - `.failure(error)` if an error occurred.
    @discardableResult
    public func delete(for service: String,
                       account: String,
                       accessGroup: String? = nil,
                       accessPermission: CFString? = nil) async -> Result<Bool, Error> {
        logger.debug("Deleting item from keychain: service: \(service), account: \(account)")
        
        if let validationError = _validateKeychainParameters(service: service, account: account, accessGroup: accessGroup) {
            logger.error("Failed to delete item from Keychain: \(validationError)")
            return .failure(validationError)
        }
        
        do {
            try _delete(for: service, account: account, accessGroup: accessGroup, accessPermission: accessPermission ?? self.accessPermission)
            logger.debug("Item deleted successfully: service: \(service), account: \(account)")
            return .success(true)
            
        } catch KeychainError.itemNotFound {
            logger.debug("Item not found in Keychain. Treated as successful deletion.")
            return .success(false)
            
        } catch KeychainError.OSStatusError(let error) {
            logger.error("Failed to delete item from Keychain: \(error)")
            return .failure(KeychainError.OSStatusError(error))
            
        } catch {
            logger.error("Unexpected error occurred while deleting item from Keychain: \(error)")
            return .failure(error)
        }
    }
}
