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
import std.variant;

class Collection(T)
{	T[] items;
	long count;
}
class Stock {int id; string name; double value; DateTime date;}
class Balance {int id; string name; double value; DateTime date;}
//alias Collection!(Balance) BalanceCollection;
class BalanceCollection : Collection!Balance {}

@rootPath("/")
interface Example1API 
{       string getInfo();
	string getStatus();
	Stock[] getStocks(string name = "", string sort = "id desc", int page = 1, int items = 25);
	BalanceCollection getBalances(string name = "", string sort = "id desc", int page = 1, int items = 25);
}

class Example1 : Example1API
{	override:
                string getInfo() 
		{	string versionNumber = to!string(getenv("rel"));
                        return "{service:'balanceservice', version:'" ~ versionNumber ~ "'}";
                }
		string getStatus() 
		{	string db = "failed";
			try  
			{	auto c = new Connection("host=localhost;user=root;pwd=root;db=stock_manager");
				scope(exit) c.close();
				auto c1 = Command(c);		
				c1.sql = "select * from stocks limit 1";
				c1.execSQLResult();
				c1.sql = "select * from balances limit 1";
				c1.execSQLResult();
				db = "okay";
			} catch (Exception e) 
			{	db = db ~ ":" ~e.msg;
			} 
			return "{service:'balanceservice', database:'"~db~"'}";
                }

                Stock[] getStocks(string name, string sort, int page, int items) 
		{	auto c = new Connection("host=localhost;user=root;pwd=root;db=stock_manager");
			scope(exit) c.close();			
			auto c1 = Command(c);
			auto where = " where ";
			if (!name.length) where = "";
			else where = where ~ "name =? ";
			auto orderBy = " order by " ~ sort;
			c1.sql = "select id, name, value, date from stocks "~where~" " ~orderBy~" limit ?,?";
			c1.prepare();
			Variant[] va;
			if (!name.length) va = variantArray(items * (page-1), items);	
			else va = variantArray(name, items * (page-1), items);
			c1.bindParameters(va);			
			ResultSet rs = c1.execPreparedResult();
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
		BalanceCollection getBalances(string name, string sort, int page, int items) 
		{	auto c = new Connection("host=localhost;user=root;pwd=root;db=stock_manager");
			scope(exit) c.close();			
			auto c1 = Command(c);
			auto where = " where ";
			if (!name.length) where = "";
			else where = where ~ "name =? ";
			auto orderBy = " order by " ~ sort;
			Variant[] va;
			c1.sql = "select count(id) from balances "~where~" limit 1";
			c1.prepare();			
			if (!name.length)
			{}
			else			
			{	va.length=1;
			 	va[0] = name;
				c1.bindParameters(va);
			}		
			long count = 0;			
			c1.execPreparedTuple(count);
			c1.sql = "select id, name, value, date from balances "~where~ " " ~orderBy~" limit ?,?";
			c1.prepare();			
			if (!name.length) va = variantArray(items * (page-1), items);	
			else va = variantArray(name, items * (page-1), items);
			c1.bindParameters(va);			
			ResultSet rs = c1.execPreparedResult();
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
			auto result = new BalanceCollection();
			result.items = balances;
			result.count = count;
			return result;
                }
}
shared static this()
{	auto settings = new HTTPServerSettings;
	auto routes = new URLRouter;
	registerRestInterface(routes, new Example1());
	string port = to!string(getenv("PORT"));
	settings.port = to!ushort(port);
	settings.bindAddresses = ["::1", "127.0.0.1"];
	listenHTTP(settings, routes);
	logInfo("Start with port "~port);
	logInfo("Please open http://localhost:"~port~"/info in your browser.");
	logInfo("or on heroku open http://firstd.herokuapp.com/info in your browser.");
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
