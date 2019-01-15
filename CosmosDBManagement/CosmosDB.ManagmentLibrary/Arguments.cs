namespace CosmosDB.ManagementLibrary
{
    public class Arguments
    {
        public string EndPointUrl { get; set; }
        public string AuthorizationKey { get; set; }
        public string DatabaseName { get; set; }
        public string CollectionName { get; set; }
        public bool Wait { get; set; } = true;

        public void ReadArgs(string[] args)
        {
            for (int i = 0; i <= args.Length - 1; i++)
            {
                var searchValue = args[i];

                switch (searchValue)
                {
                    case "-Y":
                        Wait = false;
                        break;
                    case "-EndPointUrl":
                        EndPointUrl = args[i + 1];
                        i++;
                        break;
                    case "-AuthorizationKey":
                        AuthorizationKey = args[i + 1];
                        i++;
                        break;
                    case "-DatabaseName":
                        DatabaseName = args[i + 1];
                        i++;
                        break;
                    case "-CollectionName":
                        CollectionName = args[i + 1];
                        i++;
                        break;
                }
            }
        }

    }
}
