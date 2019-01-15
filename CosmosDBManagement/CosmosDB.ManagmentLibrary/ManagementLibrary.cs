using Microsoft.Azure.Documents;
using Microsoft.Azure.Documents.Client;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace CosmosDB.ManagementLibrary
{
    public class ManagementLibrary
    {
        public string EndPointUrl { get { return Arguments.EndPointUrl; } }
        public string AuthorizationKey { get { return Arguments.AuthorizationKey; } }
        public string DatabaseName { get { return Arguments.DatabaseName; } }
        public string CollectionName { get { return Arguments.CollectionName; } }
        public List<string> Databases { get; set; }
        public List<DocumentCollection> Collections { get; set; }
        public ConnectionPolicy ConnectionPolicy { get; set; } = new ConnectionPolicy { UserAgentSuffix = " samples-net/2" };
        private DocumentClient client;

        public Arguments Arguments { get; set; }

        public ManagementLibrary(Arguments arguments)
        {
            Arguments = arguments;
        }

        #region Database

        public void CreateDatabase()
        {
            using (client = new DocumentClient(new Uri(EndPointUrl), AuthorizationKey, ConnectionPolicy))
            {
                RunDatabaseCreate().Wait();
            }

        }

        public void DeleteDatabase()
        {
            using (client = new DocumentClient(new Uri(EndPointUrl), AuthorizationKey, ConnectionPolicy))
            {
                RunDatabaseDelete().Wait();
            }

        }

        public List<string> GetDatabases()
        {

            using (client = new DocumentClient(new Uri(EndPointUrl), AuthorizationKey, ConnectionPolicy))
            {
                RunDatabaseList().Wait();
            }
            return Databases;
        }

        private async Task RunDatabaseCreate()
        {
            Database database = client.CreateDatabaseQuery().Where(db => db.Id == DatabaseName).AsEnumerable().FirstOrDefault();
            if (database == null)
            {
                database = await client.CreateDatabaseAsync(new Database { Id = DatabaseName });
            }
        }

        private async Task RunDatabaseRead()
        {
            Database database = await client.ReadDatabaseAsync(UriFactory.CreateDatabaseUri(Arguments.DatabaseName));
        }

        private async Task RunDatabaseList()
        {
            var databases = await client.ReadDatabaseFeedAsync();
            var databaseList = new List<string>();

            foreach (var db in databases)
            {
                databaseList.Add(db.ToString());

            }
            Databases = databaseList;
        }

        private async Task RunDatabaseDelete()
        {
            Database database = await client.DeleteDatabaseAsync(UriFactory.CreateDatabaseUri(Arguments.DatabaseName));
        }


        private Database GetDatabase()

        {
            IEnumerable<Database> query = from db in client.CreateDatabaseQuery()
                                          where db.Id == DatabaseName
                                          select db;
            Database database = query.FirstOrDefault();
            return database;
        }

        #endregion

        #region Collections
        public void CreateCollection()
        {
            using (client = new DocumentClient(new Uri(EndPointUrl), AuthorizationKey, ConnectionPolicy))
            {
                var database = GetDatabase();
                RunCollectionCreate().Wait();
            }
        }

        public void DeleteCollection()
        {
            using (client = new DocumentClient(new Uri(EndPointUrl), AuthorizationKey, ConnectionPolicy))
            {
                RunCollectionDelete().Wait();
            }
        }

        private async Task RunCollectionCreate()
        {
            Database database = GetDatabase();
            DocumentCollection collection = await client.CreateDocumentCollectionAsync(database.SelfLink, new DocumentCollection { Id = CollectionName });
        }

        private async Task RunCollectionDelete()
        {
            Database database = GetDatabase();
            await RunCollectionList();
            var collection = Collections.FirstOrDefault(coll => coll.Id == CollectionName);
            await client.DeleteDocumentCollectionAsync(collection.SelfLink);
        }

        private async Task RunCollectionList()
        {
            var colls = await client.ReadDocumentCollectionFeedAsync(UriFactory.CreateDatabaseUri(DatabaseName));
            var collectionList = new List<DocumentCollection>();

            foreach (var coll in colls)
            {
                collectionList.Add(coll);
            }
            Collections = collectionList;
        }






    #endregion
}
}
