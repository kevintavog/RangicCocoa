//
//

public class PersistentCacheLookupProvider: LookupProvider
{
    static private let innerLookupProvider: LookupProvider = OpenMapLookupProvider()
    static private var creationAttempted = false
    static private var databaseInstance: FMDatabaseQueue? = nil

    public func lookup(latitude: Double, longitude: Double) -> OrderedDictionary<String,String>
    {
        let key = "\(latitude), \(longitude)"
        if let result = PersistentCacheLookupProvider.getDataForKey(key) {
            return result
        }
        else {
            let result = PersistentCacheLookupProvider.innerLookupProvider.lookup(latitude, longitude: longitude)
            PersistentCacheLookupProvider.storeDataForKey(key, components: result)
            return result
        }
    }


    // MARK: Database get/store
    static private func getDataForKey(key: String) -> OrderedDictionary<String,String>?
    {
        var result: OrderedDictionary<String,String>? = nil

        if let db = getDatabaseQueue() {
            db.inDatabase() {
                db in
                let arguments = ["key":key]
                if let resultSet = db.executeQuery(
                            "SELECT fullPlacename FROM LocationCache WHERE geoLocation = :key",
                            withParameterDictionary: arguments) {
                    while resultSet.next() {
                        if let fullPlacename = resultSet.stringForColumn("fullPlacename") {
                            result = OpenMapLookupProvider.responseDataToDictionary(fullPlacename.dataUsingEncoding(NSUTF8StringEncoding)!)
                        }
                    }
                }
                else {
                    Logger.log("Error querying for '\(key)': \(db.lastErrorMessage())")
                }
            }
        }

        return result
    }

    static private func storeDataForKey(key: String, components: OrderedDictionary<String,String>)
    {
        if let db = getDatabaseQueue() {
            db.inDatabase() {
                db in
                let json = OpenMapLookupProvider.dictionaryToResponse(components)
                Logger.log("Storing placename for '\(key)'")
                let arguments = ["key":key, "json":json]
                if (!db.executeUpdate(
                            "INSERT INTO LocationCache (geoLocation, fullPlacename) VALUES(:key, :json)",
                            withParameterDictionary: arguments)) {
                    Logger.log("Error storing '\(key)': \(db.lastErrorMessage())' (\(json))")
                }
            }
        }
    }


    // MARK: Database Open/Create
    static private func getDatabaseQueue() -> FMDatabaseQueue?
    {
        if databaseInstance == nil && creationAttempted == false {
            databaseInstance = openDatabase()
            creationAttempted = true
        }

        return databaseInstance
    }

    static private func openDatabase() -> FMDatabaseQueue?
    {
        let appSupportFolder = NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask).first!
        let parentFolder = NSString.pathWithComponents([appSupportFolder.path!, "Rangic", "Location"])
        let dbPath = NSString.pathWithComponents([parentFolder, "location.cache"])
        Logger.log("Opening cache from \(dbPath)")

        if !NSFileManager.defaultManager().fileExistsAtPath(parentFolder) {
            Logger.log("Creating location cache folder: \(parentFolder)")
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(parentFolder, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                Logger.log("Failed creating location cache folder: \(error)")
                return nil
            }
        }

        if let dbQueue = FMDatabaseQueue(path: dbPath) {
            if ensureTablesExist(dbQueue) {
                return dbQueue
            }
        } else {
            Logger.log("Failed creating cache at \(dbPath)")
        }
        return nil
    }

    static private func ensureTablesExist(dbQueue: FMDatabaseQueue?) -> Bool
    {
        var successful = false
        dbQueue?.inDatabase {
            db in
            if !db.tableExists("LocationCache") {
                Logger.log("Creating cache schema")
                if !db.executeUpdate(
                        "CREATE TABLE IF NOT EXISTS LocationCache (geoLocation TEXT PRIMARY KEY, fullPlacename TEXT)",
                        withArgumentsInArray:nil) {
                    Logger.log("Failed creating cache tables: \(db.lastErrorMessage()!)")
                }
            } else {
                successful = true
            }
        }

        return successful
    }

}
