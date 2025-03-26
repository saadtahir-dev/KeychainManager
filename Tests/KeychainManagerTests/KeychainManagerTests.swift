import XCTest
@testable import KeychainManager

class KeychainManagerTests: XCTestCase {

    var testService: String {
        "com.example.testService"
    }
    
    var testAccount: String {
        "testAccount"
    }

}

// MARK: - Save Tests
extension KeychainManagerTests {
    func testSaveDataToKeychain() {
        let manager = KeychainManager.shared
        let testItem = ["key": "value"]
        
        let result = manager.save(testItem, service: testService, account: testAccount)
        
        XCTAssertTrue(result, "Saving data to the Keychain should succeed.")
    }
    
    func testSaveDuplicateItem() {
        let manager = KeychainManager.shared
        let testItem = ["key": "value"]
        
        // Save the first item
        let firstSaveResult = manager.save(testItem, service: testService, account: testAccount)
        XCTAssertTrue(firstSaveResult, "First save should succeed.")
        
        // Save the same item again (should update the existing one)
        let secondSaveResult = manager.save(testItem, service: testService, account: testAccount)
        XCTAssertTrue(secondSaveResult, "Second save of duplicate item should succeed.")
    }
}

// MARK: - Read Tests
extension KeychainManagerTests {
    func testReadDataFromKeychain() {
        let manager = KeychainManager.shared
        let testItem = ["key": "value"]
        
        // Save the item
        let saveResult = manager.save(testItem, service: testService, account: testAccount)
        XCTAssertTrue(saveResult, "Saving data should succeed.")
        
        // Read the item from Keychain
        let readItem: [String: String]? = manager.read(for: testService, account: testAccount)
        
        XCTAssertNotNil(readItem, "Reading data from Keychain should return data.")
        XCTAssertEqual(readItem?["key"], "value", "The value of the key should match the saved value.")
    }
    
    func testReadNonExistentItem() {
        let manager = KeychainManager.shared
        
        // Attempt to read an item that doesn't exist
        let readItem: [String: String]? = manager.read(for: testService, account: "nonExistentAccount")
        
        XCTAssertNil(readItem, "Reading a non-existent item should return nil.")
    }
    
    func testReadExpiredItem() {
        let manager = KeychainManager.shared
        let testItem = ["key": "value"]
        
        // Save the item
        let saveResult = manager.save(testItem, service: testService, account: testAccount)
        XCTAssertTrue(saveResult, "Saving data should succeed.")
        
        // Delete the item
        let deleteResult = manager.delete(for: testService, account: testAccount)
        XCTAssertTrue(deleteResult, "Deleting data should succeed.")
        
        // Attempt to read after deletion
        let readItem: [String: String]? = manager.read(for: testService, account: testAccount)
        
        XCTAssertNil(readItem, "Reading a deleted item should return nil.")
    }
}


// MARK: - Delete Tests
extension KeychainManagerTests {
    func testDeleteDataFromKeychain() {
        let manager = KeychainManager.shared
        let testItem = ["key": "value"]
        
        // Save the item first
        let saveResult = manager.save(testItem, service: testService, account: testAccount)
        XCTAssertTrue(saveResult, "Saving data should succeed.")
        
        // Delete the item
        let deleteResult = manager.delete(for: testService, account: testAccount)
        XCTAssertTrue(deleteResult, "Deleting data should succeed.")
        
        // Attempt to read the item after deletion
        let readItem: [String: String]? = manager.read(for: testService, account: testAccount)
        
        XCTAssertNil(readItem, "Reading after deletion should return nil.")
    }
    
    func testDeleteNonExistentItem() {
        let manager = KeychainManager.shared
        
        // Attempt to delete an item that doesn't exist
        let deleteResult = manager.delete(for: testService, account: "nonExistentAccount")
        
        XCTAssertFalse(deleteResult, "Deleting a non-existent item should fail.")
    }
}


// MARK: - Error Handling Tests
extension KeychainManagerTests {
    func testSaveDataWithError() {
        let manager = KeychainManager.shared
        let invalidService = "" // Empty service should result in an error
        
        let testItem = ["key": "value"]
        let saveResult = manager.save(testItem, service: invalidService, account: testAccount)
        
        XCTAssertFalse(saveResult, "Saving data with an invalid service should fail.")
    }
    
    func testReadDataWithError() {
        let manager = KeychainManager.shared
        
        // Trying to read data without a service or account should result in an error
        let readItem: [String: String]? = manager.read(for: "", account: "")
        
        XCTAssertNil(readItem, "Reading data with invalid parameters should return nil.")
    }
    
}


// MARK: - Edge Cases
extension KeychainManagerTests {
    func testSaveEmptyString() {
        let manager = KeychainManager.shared
        let emptyString = ""
        
        // Save an empty string as data
        let result = manager.save(emptyString, service: testService, account: testAccount)
        
        XCTAssertTrue(result, "Saving an empty string should succeed.")
        
        // Read the saved empty string
        let readItem: String? = manager.read(for: testService, account: testAccount)
        
        XCTAssertEqual(readItem, emptyString, "The saved empty string should match the read value.")
    }
    
    func testDeleteEmptyItem() {
        let manager = KeychainManager.shared
        
        // Try to delete an item that doesn't exist
        let deleteResult = manager.delete(for: testService, account: "emptyAccount")
        
        XCTAssertFalse(deleteResult, "Deleting an empty or non-existent item should fail.")
    }
}
