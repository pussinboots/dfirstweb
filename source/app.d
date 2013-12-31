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
        string getSomeInfo();

	Stock[] getStocks();
}

class Example1 : Example1API
{
	 override:
                string getSomeInfo()
                {
                        return "Some Info!";
                }

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
	logInfo("Please open http://localhost:8080/example1_api/some_info in your browser.");
}