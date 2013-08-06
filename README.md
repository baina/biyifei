biyifei
=======

The general flight data cloud acceleration system design


== Welcome to biyifei

As you know, Flight data is generally powered by travelsky Co. in China.

The OTA Co. such as itour, ctrip, elong, they mush connect into the main power system 
which had been developed by publish official's partner.

So, the main power system is NOT power. The main problem in the whole internet business 
of traveling is getting the flight data from travel-sky very slowly 
but with more payments.

  
Biyifei has been designed by the mayjor of bestfly named huangqi. it is used to accelerate
the gerenal flight system.


== Getting Started

1, 00:00 clock, to start the initialization data, time-consuming 2 minutes; the command: Lua 00.lua
2, start the expireTime program generation task, org/dst/date/; the command: nohup Lua 10.lua & (need to record PID number)
3, check whether the task item; the command: tail -10f nohup.out
4, start getting agent, to maintain an effective agent for a collection of elong IP queue; the command: nohup Lua proxyqueues.lua & (need to record PID number)
5, start the merge of price affairs; the command: nohup Lua combinate.lua & (need to record PID number)
6, start the scheduling program; the command: Lua maincall.lua
Advice: two to find the agent process with 8 main scheduling process and a merger price affairs.

== Web Servers

By default, biyifei will try to use Nginx if it's installed when started with script/server, otherwise apache is the second choice.

in Nginx, configure the elongidx.lua for elong.com, and other ota's name combinate idx.lua

== nginx configure example for elongidx.lua

# General Nginx options
    location ~ '^/idx-elong/([A-Za-z0-9]{3})/([A-Za-z0-9]{3})/([A-Za-z0-9]{5,6})/([0-9]{8})/$'
    {
      default_type 'text/plain;charset=utf-8';
      set $org $1;
      set $dst $2;
      set $fltno $3;
      set $date $4;
    content_by_lua_file /data/rails2.3.5/biyifei/http/elongidx.lua;
    }

== Debugging lua

Sometimes your application goes wrong.  Fortunately there are a lot of tools that
will help you debug it and get it back on the nginx and linux lua envirement.

First area to check is the application log files.  Have "debug_htt" configuration running
on the nginx.conf and youlogfilename.log in the error dir.

You can also log your own messages directly into the log file from your code using
the lua logger class from inside your controllers. Example:



The result will be a message in your log file along the lines of:

  Mon Oct 08 14:22:29 +1000 2007 Destroyed Weblog ID #1

More information on how to use the logger is at http://www.ruby-doc.org/core/

Also, Ruby documentation can be found at http://www.ruby-lang.org/ including:

* The Learning Ruby (Pickaxe) Book: http://www.ruby-doc.org/docs/ProgrammingRuby/
* Learn to Program: http://pine.fm/LearnToProgram/  (a beginners guide)

These two online (and free) books will bring you up to speed on the Ruby language
and also on programming in general.


== Debugger

Debugger support is available through the debugger command when you start your Mongrel or
Webrick server with --debugger. This means that you can break out of execution at any point
in the code, investigate and change the model, AND then resume execution! 
You need to install ruby-debug to run the server in debugging mode. With gems, use 'gem install ruby-debug'
Example:

  if body then
			local wname = "/data/logs/rholog.txt"
			local wfile = io.open(wname, "w+");
			wfile:write(os.date());
			wfile:write("\r\n---------------------\r\n");
			wfile:write(pcontent);
			wfile:write("\r\n---------------------\r\n");
			wfile:write(ngx.var.remote_addr);
			wfile:write("\r\n---------------------\r\n");
			wfile:write(puri);
			wfile:write("\r\n---------------------\r\n");
			for k, v in pairs(args) do
				wfile:write(k .. ":" .. v .. "\n");
			end
			wfile:write("\r\n---------------------\r\n");
			wfile:write(body .. "\n");
			io.close(wfile);
	end

So the controller will open yourlogfilename.log, run the first line, then present you
with a IRB prompt in the server window. Here you can do things like:

  ==>ngx.var.*

