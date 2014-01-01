import vibe.appmain;
import vibe.core.core;
import vibe.core.log;
import vibe.data.json;
import vibe.http.rest;
import vibe.http.router;
import vibe.http.server;
import mysql;
import std.c.stdlib;
import std.conv;
import std.string;

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
//void main()
{	auto settings = new HTTPServerSettings;
	auto routes = new URLRouter;
	registerRestInterface(routes, new Example1());
	string port = to!string(getenv("PORT"));
	settings.port = to!ushort(port);
	settings.bindAddresses = ["::1", "127.0.0.1"];
	listenHTTP(settings, routes);
	logInfo("Please open http://localhost:8080/example1_api/some_info in your browser.");
}
void main()
{
	// returns false if a help screen has been requested and displayed (--help)
	if (!finalizeCommandLineOptions())
		return;
	lowerPrivileges();
	runEventLoop();
}
