using System;
using Microsoft.Azure.Documents;
using CosmosDB.ManagementLibrary;

namespace CosmosDBManagement
{
    class Program
    {
        static void Main(string[] args)
        {
            var arguments = new Arguments();
            arguments.ReadArgs(args);
            try
            {
                var manage = new ManagementLibrary(arguments);
                manage.DeleteDatabase();
            }
            catch (DocumentClientException de)
            {
                Exception baseException = de.GetBaseException();
                Console.WriteLine("{0} error occurred: {1}, Message: {2}", de.StatusCode, de.Message, baseException.Message);
            }
            catch (Exception e)
            {
                Exception baseException = e.GetBaseException();
                Console.WriteLine("Error: {0}, Message: {1}", e.Message, baseException.Message);
            }
            finally
            {
                if (arguments.Wait)
                {
                    Console.WriteLine("End of Deletion, press any key to exit.");
                    Console.ReadKey();
                }
                Console.WriteLine("Deletion done!");
            }
        }
    }
}
