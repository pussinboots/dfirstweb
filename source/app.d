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
import std.getopt;

class Stock {int id; string name; double value; DateTime date;}
class Balance {int id; string name; double value; DateTime date;}

@rootPathFromName
interface Example1API 
{       string getInfo();
	string getStatus();
	Stock[] getStocks();
	Balance[] getBalances();
}

class Example1 : Example1API
{	override:
                string getInfo() 
		{	string versionNumber = to!string(getenv("rel"));
                        return "{service:'balanceservice', version:'" ~ versionNumber ~ "'}";
                }
		string getStatus() 
		{	auto c = new Connection("host=localhost;user=root;pwd=root;db=stock_manager");
			scope(exit) c.close();			
			auto c1 = Command(c);
			string db = "failed";
			try  {
				c1.sql = "select * from stocks limit 1";
				c1.execSQLResult();
				c1.sql = "select * from balances limit 1";
				c1.execSQLResult();
				db = "okay";
			} catch (Exception e) {
				db = db ~ ":" ~e.msg;
			} 
			return "{service:'balanceservice', }";
                }

                Stock[] getStocks() 
		{	auto c = new Connection("host=localhost;user=root;pwd=root;db=stock_manager");
			scope(exit) c.close();			
			auto c1 = Command(c);
			c1.sql = "select id, name, value, date from stocks";
			ResultSet rs = c1.execSQLResult();
			Json.emptyObject;
			Stock[] stocks;
		 	foreach (Row row; rs) 
			{	Stock stock = new Stock();
				stock.id = row[0].get!int;
				stock.name = row[1].toString();
				stock.value = row[2].get!double;
				stock.date = row[3].get!(DateTime);
				stocks ~= stock;
		   	}
			return stocks;
                }
		Balance[] getBalances() 
		{	auto c = new Connection("host=localhost;user=root;pwd=root;db=stock_manager");
			scope(exit) c.close();			
			auto c1 = Command(c);
			c1.sql = "select id, name, value, date from balances";
			ResultSet rs = c1.execSQLResult();
			Json.emptyObject;
			Balance[] balances;
		 	foreach (Row row; rs) 
			{	Balance balance = new Balance();
				balance.id = row[0].get!int;
				balance.name = row[1].toString();
				balance.value = row[2].get!double;
				balance.date = row[3].get!(DateTime);
				balances ~= balance;
		   	}
			return balances;
                }
}
shared static this()
{	auto settings = new HTTPServerSettings;
	auto routes = new URLRouter;
	registerRestInterface(routes, new Example1());
	string port = to!string(getenv("PORT"));
	settings.port = to!ushort(port);
	listenHTTP(settings, routes);
	logInfo("Start with port "~port);
	logInfo("Please open http://localhost:8080/example1_api/some_info in your browser.");
	logInfo("or on heroku open http://firstd.herokuapp.com/example1_api/some_info in your browser.");
}
void main(string[] args)
{	// returns false if a help screen has been requested and displayed (--help)
	if (!finalizeCommandLineOptions())
		return;
	ushort port = 8080;
  	getopt(args, "port", &port);
	lowerPrivileges();
	runEventLoop();
}
