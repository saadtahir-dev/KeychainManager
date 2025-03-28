# KeychainManager

**KeychainManager** is a Swift-based utility that simplifies interacting with the iOS Keychain to securely store, retrieve, update, and delete sensitive data. It supports both synchronous and asynchronous operations and is compatible with `Codable` types for easy serialization.

---

## Installation

To install **KeychainManager**, simply add it as a Swift Package Dependency.

### Swift Package Manager (SPM)

1. Open your Xcode project.
2. Go to **File** > **Swift Packages** > **Add Package Dependency**.
3. Enter the repository URL: `https://github.com/saadtahir-dev/KeychainManager.git`.
4. Follow the prompts to integrate the package into your project.

---

## Features
- **Singleton Design Pattern**: Provides a shared instance of `KeychainManager` for global access.
- **Thread-Safety**: Ensures that all Keychain operations are performed in a thread-safe manner using `DispatchQueue`.
- **Supports Codable**: Allows easy saving and reading of `Codable` items to and from the Keychain.
- **Asynchronous and Synchronous Support**: The manager supports both asynchronous and synchronous versions of methods for saving, reading, updating, and deleting data.
- **Access Permission Control**: Exposes a public `accessPermission` property that can be customized for different access permissions.
- **Error Handling**: Provides comprehensive error handling, including specific errors like `KeychainError.itemNotFound`.
  
---

## API Documentation

### Properties

- `logger`: A logger used for logging keychain operations for debugging and error reporting.
- `keychainQueue`: A concurrent serial dispatch queue used for synchronizing Keychain operations.
- `accessPermission`: Specifies the access control for Keychain items, defaulting to `kSecAttrAccessibleAlways`.

### Error Handling

`KeychainManager` defines the following custom `KeychainError` enum for error handling:

- `OSStatusError`: Represents an error returned by Keychain APIs (e.g., `SecItemAdd`, `SecItemUpdate`).
- `emptyService`: Returned when the service parameter is empty.
- `emptyAccount`: Returned when the account parameter is empty.
- `emptyAccessGroup`: Returned when the access group parameter is empty.
- `itemNotFound`: Returned when an item is not found in the Keychain.

### Methods

#### Save

##### Synchronous Save Method

```swift
@discardableResult
func save<T: Codable>(_ item: T,
                      service: String,
                      account: String,
                      accessGroup: String? = nil,
                      accessPermission: CFString? = nil,
                      completion: ((Result<Bool, Error>) -> ())? = nil) -> Bool
```

- **Parameters**:
  - `item`: The `Codable` item to be saved.
  - `service`: The service identifier for the item (e.g., app bundle identifier).
  - `account`: The account associated with the item.
  - `accessGroup`: An optional access group for shared access across apps.
  - `accessPermission`: Specifies the access control for the item (default: `nil`).
  - `completion`: A closure called with the result of the operation.

- **Returns**: A `Bool` indicating whether the save operation started successfully.

##### Asynchronous Save Method

```swift
func save<T: Codable>(_ item: T,
                      service: String,
                      account: String,
                      accessGroup: String? = nil,
                      accessPermission: CFString? = nil) async -> Result<Bool, Error>
```

- **Parameters**:
  - `item`: The `Codable` item to be saved.
  - `service`: The service identifier for the item.
  - `account`: The account associated with the item.
  - `accessGroup`: (Optional) An access group identifier.
  - `accessPermission`: (Optional) Specifies the access control for the item.

- **Returns**: A `Result<Bool, Error>` indicating the success or failure of the operation.

#### Read

##### Synchronous Read Method

```swift
func read<T: Codable>(for service: String,
                      account: String,
                      accessGroup: String? = nil,
                      accessPermission: CFString? = nil,
                      completion: ((Result<T, Error>) -> ())? = nil) -> T?
```

- **Parameters**:
  - `service`: The service identifier for the item.
  - `account`: The account associated with the item.
  - `accessGroup`: An optional access group for shared access across apps.
  - `accessPermission`: Specifies the access control for the Keychain item (default: `nil`).
  - `completion`: A closure that is called once the operation is completed, returning the decoded `Codable` item.

- **Returns**: The decoded `Codable` item from the Keychain, or `nil` if the item is not found.

##### Asynchronous Read Method

```swift
func read<T: Codable>(for service: String,
                      account: String,
                      accessGroup: String? = nil,
                      accessPermission: CFString? = nil) async -> Result<T, Error>
```

- **Parameters**:
  - `service`: The service identifier for the item.
  - `account`: The account associated with the item.
  - `accessGroup`: (Optional) An access group identifier.
  - `accessPermission`: (Optional) Specifies the access control for the item.

- **Returns**: A `Result<T, Error>` with the decoded item or an error if the operation fails.

#### Delete

##### Synchronous Delete Method

```swift
func delete(for service: String,
            account: String,
            accessGroup: String? = nil,
            accessPermission: CFString? = nil,
            completion: ((Result<Bool, Error>) -> ())? = nil)
```

- **Parameters**:
  - `service`: The service identifier for the item.
  - `account`: The account associated with the item.
  - `accessGroup`: (Optional) An access group identifier.
  - `accessPermission`: Specifies the access control for the Keychain item.

- **Returns**: A closure called once the operation is completed, indicating success or failure.

##### Asynchronous Delete Method

```swift
func delete(for service: String,
            account: String,
            accessGroup: String? = nil,
            accessPermission: CFString? = nil) async -> Result<Bool, Error>
```

- **Parameters**:
  - `service`: The service identifier for the item.
  - `account`: The account associated with the item.
  - `accessGroup`: (Optional) An access group identifier.
  - `accessPermission`: Specifies the access control for the Keychain item.

- **Returns**: A `Result<Bool, Error>` indicating success or failure of the deletion operation.

 #### Validation

```swift
private func _validateKeychainParameters(service: String, account: String, accessGroup: String?) -> KeychainError?
```

- **Parameters**:
  - `service`: The service identifier for the Keychain item.
  - `account`: The account identifier for the Keychain item.
  - `accessGroup`: (Optional) The access group identifier.
  
- **Returns**: Returns a `KeychainError` if any of the parameters are empty, otherwise returns `nil`.
  
---

## Usage

### 1. **Saving Data**

To save a `Codable` item to the Keychain:

```swift
import KeychainManager

struct UserCredentials: Codable {
    var username: String
    var password: String
}

let credentials = UserCredentials(username: "user123", password: "securepassword")

// Using completion handler
KeychainManager.shared.save(credentials, service: "com.example.myApp", account: "user123") { result in
    switch result {
    case .success(_):
        print("Data saved successfully.")
    case .failure(let error):
        print("Error saving data: \(error.localizedDescription)")
    }
}

// Using Bool return value
let isSaved = KeychainManager.shared.save(credentials, service: "com.example.myApp", account: "user123")
if isSaved {
    print("Data saved successfully.")
} else {
    print("Error saving data.")
}

// Using Async/Await
let item = UserCredentials(username: "user123", password: "password123")
Task {
    let result = await KeychainManager.shared.save(item, service: "com.example.app", account: "user123")
    switch result {
    case .success(let success):
        print("Item saved successfully: \(success)")
    case .failure(let error):
        print("Failed to save item: \(error.localizedDescription)")
    }
}
```

### 2. **Reading Data**

To read a `Codable` item from the Keychain:

```swift
// Using completion handler
KeychainManager.shared.read(for: "com.example.myApp", account: "user123") { (result: Result<UserCredentials, Error>) in
    switch result {
    case .success(let credentials):
        print("Successfully retrieved credentials: \(credentials.username), \(credentials.password)")
    case .failure(let error):
        print("Error reading data: \(error.localizedDescription)")
    }
}

// Using Bool return value
if let credentials: UserCredentials = KeychainManager.shared.read(for: "com.example.myApp", account: "user123") {
    print("Successfully retrieved credentials: \(credentials.username), \(credentials.password)")
} else {
    print("Error reading data.")
}

// Using Async/Await
Task {
    let result: Result<UserCredentials, Error> = await KeychainManager.shared.read(for: "com.example.app", account: "user123")
    switch result {
    case .success(let userCredentials):
        print("Retrieved user credentials: \(userCredentials)")
    case .failure(let error):
        print("Failed to read item: \(error.localizedDescription)")
    }
}
```

### 3. **Updating Data**

To update existing data in the Keychain:

```swift
var updatedCredentials = UserCredentials(username: "user123", password: "newpassword")

// Using completion handler
KeychainManager.shared.save(updatedCredentials, service: "com.example.myApp", account: "user123") { result in
    switch result {
    case .success(_):
        print("Credentials updated successfully.")
    case .failure(let error):
        print("Error updating data: \(error.localizedDescription)")
    }
}

// Using Bool return value
let isUpdated = KeychainManager.shared.save(updatedCredentials, service: "com.example.myApp", account: "user123")
if isUpdated {
    print("Credentials updated successfully.")
} else {
    print("Error updating data.")
}

// Using Async/Await
let item = UserCredentials(username: "user123", password: "password123")
Task {
    let result = await KeychainManager.shared.save(item, service: "com.example.app", account: "user123")
    switch result {
    case .success(let success):
        print("Item saved successfully: \(success)")
    case .failure(let error):
        print("Failed to save item: \(error.localizedDescription)")
    }
}
```

### 4. **Deleting Data**

To delete an item from the Keychain:

```swift
// Using completion handler
KeychainManager.shared.delete(for: "com.example.myApp", account: "user123") { result in
    switch result {
    case .success(_):
        print("Data deleted successfully.")
    case .failure(let error):
        print("Error deleting data: \(error.localizedDescription)")
    }
}

// Using Async/Await
Task {
    let result: Result<Bool, Error> = await KeychainManager.shared.delete(for: "com.example.app", account: "user123")
    switch result {
    case .success(let success):
        print("Item deleted successfully: \(success)")
    case .failure(let error):
        print("Failed to delete item: \(error.localizedDescription)")
    }
}
```

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

This README covers how to use **KeychainManager** for saving, reading, updating, and deleting items in the Keychain, both with a completion handler and a `Bool` return value. It also explains how to handle errors and provides installation instructions for Swift Package Manager (SPM).
