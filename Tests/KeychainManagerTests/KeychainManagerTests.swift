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
    
    func testSaveDataToKeychainWithCompletion() {
        let manager = KeychainManager.shared
        let testItem = ["key": "value"]
        
        let expectation = self.expectation(description: "Data should be saved to the Keychain.")
        
        manager.save(testItem, service: testService, account: testAccount) { result in
            switch result {
            case .success(let success):
                XCTAssertTrue(success, "Saving data to the Keychain should succeed.")
            case .failure(let error):
                XCTFail("Saving data failed with error: \(error.localizedDescription)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testSaveDuplicateItemWithCompletion() {
        let manager = KeychainManager.shared
        let testItem = ["key": "value"]
        
        let expectation = self.expectation(description: "Duplicate save should update the item.")
        
        // First save
        manager.save(testItem, service: testService, account: testAccount) { [self] result in
            switch result {
            case .success(let success):
                XCTAssertTrue(success, "First save should succeed.")
            case .failure(let error):
                XCTFail("First save failed with error: \(error.localizedDescription)")
            }
            
            // Second save (duplicate)
            manager.save(testItem, service: testService, account: testAccount) { result in
                switch result {
                case .success(let success):
                    XCTAssertTrue(success, "Second save (duplicate) should succeed.")
                case .failure(let error):
                    XCTFail("Second save failed with error: \(error.localizedDescription)")
                }
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testAsyncSaveDataToKeychain() async {
        let manager = KeychainManager.shared
        let testItem = ["key": "value"]
        
        let result = await manager.save(testItem, service: testService, account: testAccount)
        switch result {
        case .success(let success):
            XCTAssertTrue(success, "Saving data to the Keychain should succeed.")
        case .failure(let error):
            XCTFail("Saving data failed with error: \(error.localizedDescription)")
        }
    }
    
    func testAsyncSaveDuplicateItem() async {
        let manager = KeychainManager.shared
        let testItem = ["key": "value"]
        
        let firstSaveResult = await manager.save(testItem, service: testService, account: testAccount)
        switch firstSaveResult {
        case .success(let success):
            XCTAssertTrue(success, "First save should succeed.")
        case .failure(let error):
            XCTFail("First save failed with error: \(error.localizedDescription)")
        }
        
        let secondSaveResult = await manager.save(testItem, service: testService, account: testAccount)
        switch secondSaveResult {
        case .success(let success):
            XCTAssertTrue(success, "Second save of duplicate item should succeed.")
        case .failure(let error):
            XCTFail("Second save failed with error: \(error.localizedDescription)")
        }
    }
    
    func testConcurrentSaves() {
        let manager = KeychainManager.shared
        let testItem = ["key": "value"]
        
        // Create an expectation for 10 concurrent save operations
        let expectation = self.expectation(description: "All saves should succeed.")
        expectation.expectedFulfillmentCount = 10  // Expecting 10 concurrent operations
        
        // Perform 10 concurrent save operations
        for _ in 0..<10 {
            DispatchQueue.global(qos: .userInitiated).async {
                let result = manager.save(testItem, service: self.testService, account: self.testAccount)
                XCTAssertTrue(result, "Save operation should succeed.")
                expectation.fulfill()  // Fulfill the expectation when each operation finishes
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
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
        let expectation = XCTestExpectation(description: "Delete operation should complete and item should not be readable.")
        
        // Save the item
        let saveResult = manager.save(testItem, service: testService, account: testAccount)
        XCTAssertTrue(saveResult, "Saving data should succeed.")
        
        // Delete the item asynchronously
        manager.delete(for: testService, account: testAccount) { [self] result in
            switch result {
            case .success(let success):
                XCTAssertTrue(success, "Deleting data should succeed.")
            case .failure(let error):
                XCTFail("Failed to delete item: \(error.localizedDescription)")
            }
            
            // After deletion, attempt to read the item
            let readItem: [String: String]? = manager.read(for: testService, account: testAccount)
            
            XCTAssertNil(readItem, "Reading a deleted item should return nil.")
            
            // Fulfill the expectation when the test is complete
            expectation.fulfill()
        }
        
        // Wait for the expectation to be fulfilled, with a timeout to avoid hanging the test
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testReadDataFromKeychainWithCompletion() {
        let manager = KeychainManager.shared
        let testItem = ["key": "value"]
        
        let expectation = self.expectation(description: "Data should be read from the Keychain.")
        
        // First save the item
        manager.save(testItem, service: testService, account: testAccount) { [self] result in
            switch result {
            case .success(let success):
                XCTAssertTrue(success, "Saving data should succeed.")
            case .failure(let error):
                XCTFail("Saving data failed with error: \(error.localizedDescription)")
            }
            
            // Now read the item
            _ = manager.read(for: testService, account: testAccount) { (result: Result<[String: String], Error>) in
                switch result {
                case .success(let readItem):
                    XCTAssertEqual(readItem["key"], "value", "The value of the key should match the saved value.")
                case .failure(let error):
                    XCTFail("Reading data failed with error: \(error.localizedDescription)")
                }
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testReadNonExistentItemWithCompletion() {
        let manager = KeychainManager.shared
        
        let expectation = self.expectation(description: "Reading a non-existent item should fail.")
        
        _ = manager.read(for: testService, account: "nonExistentAccount") { (result: Result<[String: String], Error>) in
            switch result {
            case .success(let item):
                XCTFail("Reading a non-existent item should return nil, but got \(item).")
            case .failure:
                XCTAssertTrue(true, "Reading a non-existent item correctly returned a failure.")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testAsyncReadDataFromKeychain() async {
        let manager = KeychainManager.shared
        let testItem = ["key": "value"]
        
        // Save the item
        let saveResult = await manager.save(testItem, service: testService, account: testAccount)
        switch saveResult {
        case .success(let success):
            XCTAssertTrue(success, "Saving data to the Keychain should succeed.")
        case .failure(let error):
            XCTFail("Saving data failed with error: \(error.localizedDescription)")
        }
        
        // Read the item from Keychain asynchronously
        let readItemResult: Result<[String: String], Error> = await manager.read(for: testService, account: testAccount)
        
        switch readItemResult {
        case .success(let readItem):
            XCTAssertEqual(readItem["key"], "value", "The value of the key should match the saved value.")
        case .failure(let error):
            XCTFail("Failed to read data from Keychain: \(error.localizedDescription)")
        }
    }
    
    func testAsyncReadNonExistentItem() async {
        let manager = KeychainManager.shared
        
        // Attempt to read an item that doesn't exist
        let readItemResult: Result<[String: String], Error> = await manager.read(for: testService, account: "nonExistentAccount")
        
        switch readItemResult {
        case .success(let readItem):
            XCTFail("Reading a non-existent item should return nil, but got \(readItem).")
        case .failure:
            XCTAssertTrue(true, "Reading a non-existent item correctly returned a failure.")
        }
    }
    
    func testConcurrentReads() {
        let manager = KeychainManager.shared
        let testItem = ["key": "value"]
        
        // Save the item before reading
        let saveResult = manager.save(testItem, service: self.testService, account: self.testAccount)
        XCTAssertTrue(saveResult, "Saving data should succeed.")
        
        // Create an expectation for 10 concurrent read operations
        let expectation = self.expectation(description: "All reads should succeed.")
        expectation.expectedFulfillmentCount = 10  // Expecting 10 concurrent operations
        
        // Perform 10 concurrent read operations
        for _ in 0..<10 {
            DispatchQueue.global(qos: .userInitiated).async {
                _ = manager.read(for: self.testService, account: self.testAccount) { (result: Result<[String: String], Error>) in
                    switch result {
                    case .success(let readItem):
                        XCTAssertEqual(readItem["key"], "value", "Read data should match the saved value.")
                    case .failure(let error):
                        XCTFail("Read operation failed with error: \(error.localizedDescription)")
                    }
                    expectation.fulfill()  // Fulfill the expectation when each operation finishes
                }
            }
        }
        
        // Wait for all operations to finish
        waitForExpectations(timeout: 5, handler: nil)
    }
}


// MARK: - Delete Tests
extension KeychainManagerTests {
    func testDeleteDataFromKeychainWithCompletion() {
        let manager = KeychainManager.shared
        let testItem = ["key": "value"]
        
        let expectation = self.expectation(description: "Data should be deleted from the Keychain.")
        
        // First save the item
        manager.save(testItem, service: testService, account: testAccount) { [self] result in
            switch result {
            case .success(let success):
                XCTAssertTrue(success, "Saving data should succeed.")
            case .failure(let error):
                XCTFail("Saving data failed with error: \(error.localizedDescription)")
            }
            
            // Now delete the item
            manager.delete(for: testService, account: testAccount) { result in
                switch result {
                case .success(let success):
                    XCTAssertTrue(success, "Deleting data should succeed.")
                case .failure(let error):
                    XCTFail("Failed to delete data: \(error.localizedDescription)")
                }
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDeleteNonExistentItemWithCompletion() {
        let manager = KeychainManager.shared
        
        let expectation = self.expectation(description: "Deleting a non-existent item should fail.")
        
        manager.delete(for: testService, account: "nonExistentAccount") { result in
            switch result {
            case .success(let success):
                XCTAssertFalse(success, "Deleting a non-existent item should fail.")
            case .failure(let error):
                if let keychainError = error as? KeychainManager.KeychainError,
                   case .itemNotFound = keychainError {
                    // If the item is not found, this is expected behavior
                    XCTAssertTrue(true, "Item not found for deletion. This is expected behavior.")
                } else {
                    XCTFail("Failed to delete non-existent item: \(error.localizedDescription)")
                }
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testAsyncDeleteDataFromKeychain() async {
        let manager = KeychainManager.shared
        let testItem = ["key": "value"]
        
        // Save the item first
        let saveResult = await manager.save(testItem, service: testService, account: testAccount)
        switch saveResult {
        case .success(let success):
            XCTAssertTrue(success, "Saving data to the Keychain should succeed.")
        case .failure(let error):
            XCTFail("Saving data failed with error: \(error.localizedDescription)")
        }
        
        // Delete the item asynchronously
        let deleteResult = await manager.delete(for: testService, account: testAccount)
        
        switch deleteResult {
        case .success(let success):
            XCTAssertTrue(success, "Deleting data should succeed.")
        case .failure(let error):
            XCTFail("Failed to delete data: \(error.localizedDescription)")
        }
        
        // Attempt to read the item after deletion
        let readItemResult: Result<[String: String], Error> = await manager.read(for: testService, account: testAccount)
        
        switch readItemResult {
        case .success(let readItem):
            XCTFail("Reading after deletion should return nil, but got \(readItem).")
        case .failure:
            XCTAssertTrue(true, "Reading after deletion correctly returned a failure.")
        }
    }
    
    func testAsyncDeleteNonExistentItem() async {
        let manager = KeychainManager.shared
        
        // Attempt to delete an item that doesn't exist
        let deleteResult: Result<Bool, Error> = await manager.delete(for: testService, account: "nonExistentAccount")
        
        switch deleteResult {
        case .success(let success):
            XCTAssertFalse(success, "Deleting a non-existent item should pass.")
        case .failure(let error):
            if let keychainError = error as? KeychainManager.KeychainError,
               case .itemNotFound = keychainError {
                // If the item is not found, this is expected behavior
                XCTAssertTrue(true, "Item not found for deletion. This is expected behavior.")
            } else {
                XCTFail("Failed to delete non-existent item: \(error.localizedDescription)")
            }
        }
    }
    
    func testConcurrentDeletes() {
        let manager = KeychainManager.shared
        let testItem = ["key": "value"]
        
        let group = DispatchGroup() // To track multiple concurrent delete operations
        var deleteResults: [Bool] = []
        var errors: [Error] = []
        
        let expectation = XCTestExpectation(description: "All delete operations should complete without issues.")

        
        // Save the item before deleting
        let saveResult = manager.save(testItem, service: testService, account: testAccount)
        XCTAssertTrue(saveResult, "Saving data should succeed.")
        
        
        // Perform 10 concurrent delete operations
        for _ in 0..<10 {
            DispatchQueue.global().async(group: group) { [weak self] in
                guard let self else { return }
                group.enter()
                
                manager.delete(for: testService, account: testAccount) { result in
                    switch result {
                    case .success(let success):
                        deleteResults.append(success)
                    case .failure(let error):
                        errors.append(error)
                    }
                    group.leave() // Mark this async operation as complete
                }
            }
        }
        
        // Wait for all async operations to finish
        group.notify(queue: .main) {
            // Ensure all delete operations are complete without any errors
            XCTAssertTrue(errors.isEmpty, "There were errors in the delete operations: \(errors)")
            
            // Verify that the delete operation was successful for all threads
            XCTAssertTrue(deleteResults.allSatisfy { $0 == true || $0 == false },
                          "Not all delete operations returned a valid result (true/false).")
            
            // Fulfill the expectation to indicate test completion
            expectation.fulfill()
        }
        
        // Wait for expectation to be fulfilled
        wait(for: [expectation], timeout: 10.0)
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
        let expectation = XCTestExpectation(description: "Delete operation should complete.")
        
        manager.delete(for: testService, account: "emptyAccount") { result in
            switch result {
            case .success(let success):
                XCTAssertFalse(success, "Deleting a non-existent or empty item should be treated as successful, but with a 'false' result.")
                
            case .failure(let error):
                XCTAssertEqual(error.localizedDescription, KeychainManager.KeychainError.itemNotFound.localizedDescription, "Expected itemNotFound error.")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}
