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
import std.datetime;
import std.stdio;

class Collection(T)
{	T[] entries;
	long length;
	int page;
	int items;
	long total;
	DateTime date;
}
class Stock {int id; string name; double value; DateTime date;}
class Balance {int id; string name; double value; DateTime date;}
//alias Collection!(Balance) BalanceCollection;
class BalanceCollection : Collection!Balance {}
class StockCollection : Collection!Stock {}

@rootPath("/")
interface Example1API 
{       import vibe.http.rest : after;
	@after!addAccessControlOrigin()
	string getInfo();
	@after!addAccessControlOrigin()
	string getStatus();
	@after!addAccessControlOrigin()
	StockCollection getStocks(string name = "", string sort = "id desc", int page = 1, int items = 25);
	@after!addAccessControlOrigin()
	BalanceCollection getBalances(DateTime date = DateTime.init, string name = "", string sort = "id desc", int page = 1, int items = 25);
}

string addAccessControlOrigin(string result, HTTPServerRequest, HTTPServerResponse res)
{	res.headers["Access-Control-Allow-Origin"] = "*";
	return result;
}

class Example1 : Example1API
{	override:
                string getInfo() 
		{	string versionNumber = to!string(getenv("rel"));
                        return "{service:'balanceservice', version:'" ~ versionNumber ~ "'}";
                }
		string getStatus() 
		{	string db = "failed";
			bool health = true;
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
				health = false;
			} 
			return "{service:'balanceservice', database:'"~db~"', health:"~to!string(health)~"}";
                }

                StockCollection getStocks(string name, string sort, int page, int items) 
		{	auto c = new Connection("host=localhost;user=root;pwd=root;db=stock_manager");
			scope(exit) c.close();			
			auto c1 = Command(c);

			auto where2 = " where ";
			if (!name.length) where2 = "";
			else where2 = where2 ~ "name = '"~name~"'";
			c1.sql = "select count(id) from stocks "~where2~" limit 1";
			long count = 0;	
			c1.execSQLTuple(count);

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
			auto result = new StockCollection();
			result.entries = stocks;
			result.length = stocks.length;
			result.total = count;
			result.page = page;
			result.items = items;
			result.date = to!DateTime(Clock.currTime());
			return result;
                }
		BalanceCollection getBalances(DateTime date, string name, string sort, int page, int items) 
		{	auto c = new Connection("host=localhost;user=root;pwd=root;db=stock_manager");
			scope(exit) c.close();	
			writeln("date " ~to!string(date));		
			auto c1 = Command(c);
			auto where2 = " where ";
			if (!name.length) where2 = "";
			else where2 = where2 ~ "name = '"~name~"'";
			if(date != DateTime.init)
			{	if (!where2.length) where2 = " where date = '"~date.toISOExtString()~"' "; 
				else where2 = where2 ~ " AND date = '"~date.toISOExtString()~"' ";
			}

			c1.sql = "select count(id) from balances "~where2~" limit 1";
			writeln("SQL " ~to!string(c1.sql));	
			long count = 0;	
			c1.execSQLTuple(count);

			Variant[] va;
			auto where = " where ";
			if (!name.length) where = "";
			else where = where ~ "name = ? ";
			if(date != DateTime.init)
				if (!where.length) where = " where date = ? "; 
				else where = where ~ " AND date = ? ";
			else where2 = where2 ~ "name = '"~name~"'";

			auto orderBy = " order by " ~ sort;
			c1.sql = "select id, name, value, date from balances "~where~ " " ~orderBy~" limit ?,?";
					
			c1.prepare();	
			if (!name.length && date == DateTime.init) va = variantArray(items * (page-1), items);	
			else if (name.length && date != DateTime.init) va = variantArray(name, date, items * (page-1), items);
			else if (!name.length && date != DateTime.init) va = variantArray(date, items * (page-1), items);
			else if (!name.length && date == DateTime.init) va = variantArray(name, items * (page-1), items);
			c1.bindParameters(va);			
			logInfo("Retrieve items ");
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
			result.entries = balances;
			result.length = balances.length;
			result.total = count;
			result.page = page;
			result.items = items;
			result.date = to!DateTime(Clock.currTime());
			return result;
                }
}
unittest
{	auto c = new Connection("host=localhost;user=root;pwd=root;db=mysql");
	scope(exit) c.close();
	auto command = Command(c);
	ulong affectedRows;
	command.sql ="DROP TABLE IF EXISTS balances;";
	command.execSQL(affectedRows);
	command.sql ="DROP TABLE IF EXISTS stocks;";
	command.execSQL(affectedRows);
	command.sql ="DROP DATABASE IF EXISTS stock_manager_test;";
	command.execSQL(affectedRows);	
	
	command.sql = "create database stock_manager_test;";
	command.execSQL(affectedRows);
	command.sql = "use stock_manager_test;";
	command.execSQL(affectedRows);
	command.sql = "CREATE TABLE `balances` (
		  `id` int(11) NOT NULL AUTO_INCREMENT,
		  `name` varchar(254) NOT NULL,
		  `value` double NOT NULL,
		  `date` timestamp NULL DEFAULT NULL,
		  PRIMARY KEY (`id`)
		) ENGINE=InnoDB AUTO_INCREMENT=157 DEFAULT CHARSET=latin1";
	command.execSQL(affectedRows);
	command.sql = "CREATE TABLE `stocks` (
		  `id` int(11) NOT NULL AUTO_INCREMENT,
		  `name` varchar(254) NOT NULL,
		  `value` double NOT NULL,
		  `date` timestamp NULL DEFAULT NULL,
		  PRIMARY KEY (`id`)
		) ENGINE=InnoDB AUTO_INCREMENT=157 DEFAULT CHARSET=latin1";
	command.execSQL(affectedRows);	
	Example1API e1 = new Example1();
	assert(e1.getBalances().total == 150, "check if 150 balances exists");	
}

shared static this()
{	auto settings = new HTTPServerSettings;
	auto routes = new URLRouter;
	registerRestInterface(routes, new Example1());
	string port = to!string(getenv("PORT"));
	settings.port = to!ushort(port);
	//cause heroku boot of webapp to fail	
	//settings.bindAddresses = ["::1", "127.0.0.1"];
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
