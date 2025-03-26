# KeychainManager

**KeychainManager** is a Swift-based utility that simplifies interacting with the iOS Keychain to securely store, retrieve, update, and delete sensitive data. It supports both synchronous and asynchronous operations and is compatible with `Codable` types for easy serialization.

## Features
- **Save** sensitive data securely in the Keychain.
- **Read** data from the Keychain.
- **Update** existing data in the Keychain.
- **Delete** items from the Keychain.
- Support for **Codable** types, making it easy to store and retrieve custom objects.
- Provides both **completion handler** (asynchronous) and **Boolean return value** (synchronous) options.

## Installation

To install **KeychainManager**, simply add it as a Swift Package Dependency.

### Swift Package Manager (SPM)

1. Open your Xcode project.
2. Go to **File** > **Swift Packages** > **Add Package Dependency**.
3. Enter the repository URL: `https://github.com/saadtahir-dev/KeychainManager.git`.
4. Follow the prompts to integrate the package into your project.

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

// Using Bool return value
let isDeleted = KeychainManager.shared.delete(for: "com.example.myApp", account: "user123")
if isDeleted {
    print("Data deleted successfully.")
} else {
    print("Error deleting data.")
}
```

---

## API Documentation

### `KeychainManager`

The `KeychainManager` class provides thread-safe operations for interacting with the iOS Keychain.

#### `shared`:
A singleton instance of `KeychainManager`.

```swift
public class var shared: KeychainManager
```

#### `save<T: Codable>(_ item: T, service: String, account: String, accessGroup: String? = nil) -> Bool`
Saves a `Codable` item to the Keychain.

- **Parameters**:
    - `item`: The `Codable` item to be saved.
    - `service`: The service identifier for the Keychain item.
    - `account`: The account associated with the Keychain item.
    - `accessGroup`: (Optional) An access group identifier for shared Keychain access across apps.
    
- **Returns**: `Bool` indicating success (`true`) or failure (`false`).

#### `read<T: Codable>(for service: String, account: String, accessGroup: String? = nil) -> T?`
Reads a `Codable` item from the Keychain.

- **Parameters**:
    - `service`: The service identifier for the Keychain item.
    - `account`: The account associated with the Keychain item.
    - `accessGroup`: (Optional) An access group identifier for shared Keychain access across apps.
    
- **Returns**: The `Codable` item, or `nil` if not found.

#### `delete(for service: String, account: String, accessGroup: String? = nil) -> Bool`
Deletes an item from the Keychain.

- **Parameters**:
    - `service`: The service identifier for the Keychain item.
    - `account`: The account associated with the Keychain item.
    - `accessGroup`: (Optional) An access group identifier for shared Keychain access across apps.
    
- **Returns**: `Bool` indicating success (`true`) or failure (`false`).

---

## Error Handling

The `KeychainManager` class uses the following errors:

- **`KeychainError.emptyService`**: The service parameter is empty.
- **`KeychainError.emptyAccount`**: The account parameter is empty.
- **`KeychainError.emptyAccessGroup`**: The access group parameter is empty (if provided).
- **`KeychainError.unknown(String)`**: An unknown error occurred while interacting with the Keychain.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

This README covers how to use **KeychainManager** for saving, reading, updating, and deleting items in the Keychain, both with a completion handler and a `Bool` return value. It also explains how to handle errors and provides installation instructions for Swift Package Manager (SPM).
