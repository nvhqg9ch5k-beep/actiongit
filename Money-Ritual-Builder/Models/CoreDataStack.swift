import CoreData
import Foundation

class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    
    private var _persistentContainer: NSPersistentContainer?
    private let modelVersion = "2.0" // Increment when model changes
    
    var persistentContainer: NSPersistentContainer {
        if let container = _persistentContainer {
            return container
        }
        
        let container = NSPersistentContainer(name: "MoneyRitualModel")
        
        // Check if we need to delete old store
        let lastModelVersion = UserDefaults.standard.string(forKey: "CoreDataModelVersion")
        
        if lastModelVersion != modelVersion {
            // Model changed, delete old store
            if let storeURL = container.persistentStoreDescriptions.first?.url {
                deleteStore(at: storeURL)
            }
            UserDefaults.standard.set(modelVersion, forKey: "CoreDataModelVersion")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                // Check if it's a migration error
                if let nsError = error as NSError? {
                    if nsError.domain == NSCocoaErrorDomain,
                       (nsError.code == 134140 || nsError.code == 134190) {
                        // Delete all store files
                        if let url = description.url {
                            self.deleteStore(at: url)
                            
                            // Reload the store
                            container.loadPersistentStores { _, retryError in
                                if retryError != nil {
                                    // Failed to reload - user will need to restart app
                                }
                            }
                        }
                    } else {
                        // For other errors, try to delete and recreate
                        if let url = description.url {
                            self.deleteStore(at: url)
                            
                            container.loadPersistentStores { _, retryError in
                                if retryError != nil {
                                    // Failed to reload - user will need to restart app
                                }
                            }
                        }
                    }
                }
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        _persistentContainer = container
        return container
    }
    
    private func deleteStore(at url: URL) {
        let storeDirectory = url.deletingLastPathComponent()
        let storeName = url.lastPathComponent
        
        // Delete main store
        try? FileManager.default.removeItem(at: url)
        
        // Delete SQLite journal files
        let shmURL = storeDirectory.appendingPathComponent(storeName + "-shm")
        let walURL = storeDirectory.appendingPathComponent(storeName + "-wal")
        
        try? FileManager.default.removeItem(at: shmURL)
        try? FileManager.default.removeItem(at: walURL)
    }
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func save() throws {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            try context.save()
        }
    }
    
    func saveSilently() {
        do {
            try save()
        } catch {
            // Silent failure - errors are logged by Core Data
        }
    }
    
    private init() {}
}
