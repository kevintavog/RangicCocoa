//
//

open class PersistentCacheLookupProvider: LookupProvider
{
    static fileprivate let innerLookupProvider: LookupProvider = OpenMapLookupProvider()
    static fileprivate var creationAttempted = false
    static fileprivate var databaseInstance: FMDatabaseQueue? = nil

    open func lookup(_ latitude: Double, longitude: Double) -> OrderedDictionary<String,String>
    {
        let key = "\(latitude), \(longitude)"
        if let result = PersistentCacheLookupProvider.getDataForKey(key) {
            if result.count > 0 {
                return result
            }
        }

        let result = PersistentCacheLookupProvider.innerLookupProvider.lookup(latitude, longitude: longitude)
        if result.count > 0 {
            PersistentCacheLookupProvider.storeDataForKey(key, components: result)
        }
        return result
    }


    // MARK: Database get/store
    static fileprivate func getDataForKey(_ key: String) -> OrderedDictionary<String,String>?
    {
        var result: OrderedDictionary<String,String>? = nil

        if let db = getDatabaseQueue() {
            db.inDatabase() {
                db in
                let arguments = ["key":key]
                if let resultSet = db?.executeQuery(
                            "SELECT fullPlacename FROM LocationCache WHERE geoLocation = :key",
                            withParameterDictionary: arguments) {
                    while resultSet.next() {
                        if let fullPlacename = resultSet.string(forColumn: "fullPlacename") {
                            result = OpenMapLookupProvider.responseDataToDictionary(fullPlacename.data(using: String.Encoding.utf8)!)
                        }
                    }
                }
                else {
                    Logger.error("Error querying for '\(key)': \(String(describing: db?.lastErrorMessage()))")
                }
            }
        }

        return result
    }

    static fileprivate func storeDataForKey(_ key: String, components: OrderedDictionary<String,String>)
    {
        if let db = getDatabaseQueue() {
            db.inDatabase() {
                db in
                let json = OpenMapLookupProvider.dictionaryToResponse(components)
                Logger.debug("Storing placename for '\(key)'")
                let arguments = ["key":key, "json":json]
                if (!(db?.executeUpdate(
                    "INSERT OR REPLACE INTO LocationCache (geoLocation, fullPlacename) VALUES(:key, :json)",
                    withParameterDictionary: arguments))!) {
                    Logger.error("Error storing '\(key)': \(String(describing: db?.lastErrorMessage()))' (\(json))")
                }
            }
        }
    }


    // MARK: Database Open/Create
    static fileprivate func getDatabaseQueue() -> FMDatabaseQueue?
    {
        if databaseInstance == nil && creationAttempted == false {
            databaseInstance = openDatabase()
            creationAttempted = true
        }

        return databaseInstance
    }

    static fileprivate func openDatabase() -> FMDatabaseQueue?
    {
        let appSupportFolder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let parentFolder = NSString.path(withComponents: [appSupportFolder.path, "Rangic", "Location"])
        let dbPath = NSString.path(withComponents: [parentFolder, "location.cache"])
        Logger.info("Opening cache from \(dbPath)")

        if !FileManager.default.fileExists(atPath: parentFolder) {
            Logger.info("Creating location cache folder: \(parentFolder)")
            do {
                try FileManager.default.createDirectory(atPath: parentFolder, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                Logger.error("Failed creating location cache folder: \(error)")
                return nil
            }
        }

        if let dbQueue = FMDatabaseQueue(path: dbPath) {
            if ensureTablesExist(dbQueue) {
                return dbQueue
            }
        } else {
            Logger.error("Failed creating cache at \(dbPath)")
        }
        return nil
    }

    static fileprivate func ensureTablesExist(_ dbQueue: FMDatabaseQueue?) -> Bool
    {
        var successful = false
        dbQueue?.inDatabase {
            db in
            if !(db?.tableExists("LocationCache"))! {
                Logger.info("Creating cache schema")
                if !(db?.executeUpdate(
                        "CREATE TABLE IF NOT EXISTS LocationCache (geoLocation TEXT PRIMARY KEY, fullPlacename TEXT)",
                        withArgumentsIn:nil))! {
                    Logger.error("Failed creating cache tables: \(String(describing: db?.lastErrorMessage()!))")
                }
            } else {
                successful = true
            }
        }

        return successful
    }

}
