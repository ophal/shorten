local sw_var = require 'seawolf.variable'
local sw_txt = require 'seawolf.text'
local tconcat, theme, add_js, goto, url = table.concat, theme, add_js, goto, url
local modules, header, type = ophal.modules, header, type
local empty, env, time, error = sw_var.empty, env, os.time, error
local json, _SESSION, exit_ophal = require 'dkjson', _SESSION, exit_ophal
local exit, route_arg, str_replace = os.exit, route_arg, sw_txt.str_replace
local exit_ophal, print, format_date = exit_ophal, print, format_date
local io_write, os_exit, version = io_write, os_exit, ophal.version
local session_write_close, string, math = session_write_close, string, math
local rawset, concat, int2strmap = rawset, table.concat, sw_txt.int2strmap
local str2intmap, request_get_body = sw_txt.str2intmap, request_get_body

module 'ophal.modules.shorten'

local user_mod, db_query

--[[ Implements hook init().
]]
function init()
  user_mod = modules.user
  db_query = env.db_query
  redirect()
end

function redirect()
  local data, rs, err, date_format

  if empty(route_arg(1)) and not empty(route_arg(0)) then
    rs, err = db_query('SELECT long FROM shorten_urls WHERE id = ?', str2intmap(route_arg(0)))

    if not err then
      data = rs:fetch(true)
      if not empty(data) then
        date_format = '!%a, %d %b %Y %X GMT'
        io_write(([[status: 301
cache-control: private,max-age=300
date: %s
expires: %s
location: %s
content-length: 0
x-powered-by: %s
connection: close

]]):format(
          format_date(time(), date_format),
          format_date(time() + 60*5, date_format),
          data.long,
          version
        ))
        session_write_close()
        os_exit()
      end
    end
  end
end

--[[ Implements hook route().
]]
function route()
  local items = {}

  items.shorten = {
    page_callback = 'shorten_service',
    access_callback = {module = 'user', 'access', 'create short urls'},
    format = 'json',
  }

  items['shorten/wizard'] = {
    page_callback = 'page',
  }

  return items
end

function shorten_service()
  local parsed, pos, err, data, output, short_path, input, account

  input = request_get_body()
  output = {success = false}

  parsed, pos, err = json.decode(input, 1, nil)
  if err then
    error(err)
  elseif
    'table' == type(parsed) and not empty(parsed.url)
  then
    rs, err = db_query('SELECT * FROM shorten_urls WHERE long = ?', parsed.url)
    if err then
      error(err)
    else
      data = rs:fetch(true)
      if not empty(data) then
        short_path = int2strmap(data.id)
      else
        short_path = new()
        rs, err = db_query(
          'INSERT INTO shorten_urls(user_id, long, active, created) VALUES(?, ?, ?, ?)',
          user_mod.current().id, str_replace({'\n', '\r'}, '', parsed.url), 1, time()
        )
        if err then
          error(err)
        end
      end
      output.short = url(short_path, {absolute = true})
      output.success = true
    end
  end

  return output
end

function new()
  local rs, err, last_id, id
  rs, err  = db_query 'SELECT seq FROM SQLITE_SEQUENCE WHERE name = "shorten_urls"'
  if err then
    error(err)
  else
    last_id = rs:fetch(true)
    if empty(last_id) then
      id = 1
    else
      id = last_id.seq + 1
    end

    return int2strmap(id)
  end
end

function page()
  if not user_mod.is_logged_in() then
    goto 'user/login'
  end

  add_js 'misc/jquery.js'
  add_js 'misc/json2.js'
  add_js 'modules/shorten/shorten.js'

  return tconcat{
    '<form method="POST">',
    '<div>',
    theme.textfield{attributes = {id = 'long_url', title = 'paste your URL here'}},
    '<br />',
    theme.submit{value = 'shorten', attributes = {id = 'shorten_smt'}},
    '</div>',
    '<div>',
    theme.textfield{id = 'short_url', attributes = {id = 'short_url'}},
    '<br />',
    theme.button{value = 'copy', attributes = {id = 'copy_btn'}},
    '</div>',
    '</form>',
  }
end
