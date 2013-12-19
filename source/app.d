import vibe.d;
import vibe.appmain;
import vibe.core.core;
import vibe.core.log;
import vibe.data.json;
import vibe.http.rest;
import vibe.http.router;
import vibe.http.server;
import mysql;

@rootPathFromName
interface Example1API
{
        /* Default convention is based on camelCase
         */
         
        /* Used HTTP method is "GET" because function name start with "get".
         * Remaining part is converted to lower case with words separated by _
         *
         * Resulting matching request: "GET /some_info"
         */
        string getSomeInfo();

        /* Parameters are supported in a similar fashion.
         * Despite this is only an interface, make sure parameter names are not omitted, those are used for serialization.
         * If it is a GET reuqest, parameters are embedded into query URL.
         * Stored in POST data for POST, of course.
         */
        int postSum(int a, int b);

        /* @property getters are always GET. @property setters are always PUT.
         * All supported convention prefixes are documentated : http://vibed.org/api/vibe.http.rest/registerRestInterface
         * Rather obvious and thus omitted in this example interface.
         */
        @property Stock[] getStocks();
}

class Example1 : Example1API
{
                string getSomeInfo()
                {
                        return "Some Info!";
                }

                int postSum(int a, int b)
                {
                        return a + b;
                }

                @property
                Stock[] getStocks()
                {
                        auto c = new Connection("host=localhost;user=root;pwd=root;db=stock_manager");
			scope(exit) c.close();			
			auto c1 = Command(c);
			c1.sql = "select * from stocks";
			ResultSet rs = c1.execSQLResult();
			Json.emptyObject;
			Stock[] stocks;
		 	foreach (Row row; rs) {
				Stock stock = new Stock();
				stock.name = row[1].toString();
				stock.value = row[2].get!double;
				stocks ~= stock;
		   	}
			return stocks;
                }
}

class Stock {string name; double value;}
shared static this()
{
	auto settings = new HTTPServerSettings;
	auto routes = new URLRouter;
	registerRestInterface(routes, new Example1());
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1"];
	listenHTTP(settings, routes);
	logInfo("Please open http://127.0.0.1:8080/ in your browser.");
}
