local sys  = require "luci.sys"
local http = require "luci.http"

module("luci.controller.ninja", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/ninja") then
		return
	end

	local page
	page = entry({ "admin", "services", "ninja" }, alias("admin", "services", "ninja", "client"), _("Ninja"), 10)
	page.dependent = true
	page.acl_depends = { "luci-app-ninja" }

	entry({ "admin", "services", "ninja", "client" }, cbi("ninja/client"), _("Settings"), 10).leaf = true
	entry({ "admin", "services", "ninja", "log" }, form("ninja/log"), _("Log"), 30).leaf = true
	
	entry({"admin", "services", "ninja", "status"}, call("act_status")).leaf = true
	entry({ "admin", "services", "ninja", "logtail" }, call("action_logtail")).leaf = true
end

function act_status()
	local e = {}
	e.running = sys.call("pgrep -f ninja >/dev/null") == 0
	e.application = luci.sys.exec("ninja --version")
	http.prepare_content("application/json")
	http.write_json(e)
end

function action_logtail()
	local fs = require "nixio.fs"
	local log_path = "/var/log/ninja.log"
	local e = {}
	e.running = luci.sys.call("pidof ninja >/dev/null") == 0
	if fs.access(log_path) then
		e.log = luci.sys.exec("tail -n 200 %s | sed 's/\\x1b\\[[0-9;]*m//g'" % log_path)
	else
		e.log = ""
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end