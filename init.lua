local tconcat, theme, add_js, goto, url = table.concat, theme, add_js, goto, url
local modules, header, read, type = ophal.modules, header, io.read, type
local empty, env, time, error = seawolf.variable.empty, env, os.time, error
local json, _SESSION, exit_ophal = require 'dkjson', _SESSION, exit_ophal
local exit, arg, str_replace = os.exit, arg, seawolf.text.str_replace
local exit_ophal, print, format_date = exit_ophal, print, format_date
local io_write, os_exit, version = io_write, os_exit, ophal.version
local session_write_close, string, math = session_write_close, string, math
local rawset, concat = rawset, table.concat

local debug = debug

module 'ophal.modules.shorten'

local user_is_logged_in, db_query

function init()
  user_is_logged_in = modules.user.user_is_logged_in
  db_query = env.db_query
  redirect()
end

function redirect()
  local data, rs, err, date_format

  if empty(arg(1)) and not empty(arg(0)) then
    rs, err = db_query('SELECT long FROM shorten_urls WHERE short = ?', arg(0))

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

function menu()
  items = {}

  items.shorten = {
    page_callback = 'shorten_service',
  }

  items['shorten/wizard'] = {
    page_callback = 'page',
  }

  return items
end

function shorten_service()
  local params, pos, err, data, output, short_path

  if not user_is_logged_in() then
    header('status', 404)
  else
    header('content-type', 'application/json; charset=utf-8')

    output = {success = false}
    params, pos, err = json.decode(read '*a', 1, nil)
    if err then
      error(err)
    elseif
      'table' == type(params) and not empty(params.url)
    then
      rs, err = db_query('SELECT * FROM shorten_urls WHERE long = ?', params.url)
      if err then
        error(err)
      else
        data = rs:fetch(true)
        if not empty(data) then
          short_path = data.short
        else
          short_path = new()
          rs, err = db_query(
            'INSERT INTO shorten_urls(user_id, long, short, active, created) VALUES(?, ?, ?, ?, ?)',
            _SESSION.user.id, str_replace({'\n', '\r'}, '', params.url), short_path, 1, time()
          )
          if err then
            error(err)
          end
        end
        output.short = url(short_path, {absolute = true})
        output.success = true
      end
    end

    output = json.encode(output)
  end

  theme.html = function () return output or '' end
end

--[[
  Convert given integer to alphanumeric (numbers + lower case + upper case)

  Copied and adapted from http://lua-users.org/lists/lua-l/2004-09/msg00054.html
]]
function int2alphanum(IN)
  local map = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
  local buffer, OUT, i, d = {}, {}, 0
  local b = map:len()
  while IN > 0 do
    i = i + 1
    IN, d = math.floor(IN/b), math.mod(IN, b) + 1
    rawset(buffer, i, string.sub(map, d, d))
  end
  while i > 0 do
    rawset(OUT, #OUT + 1, buffer[i])
    i = i - 1
  end
  return tconcat(OUT, '')
end


function new()
  local rs, err, last_id, id
  rs, err  = db_query 'SELECT id from shorten_urls ORDER BY id DESC LIMIT 0,1'
  if err then
    error(err)
  else
    last_id = rs:fetch(true)
    if empty(last_id) then
      id = 1
    else
      id = last_id.id + 1
    end

    return int2alphanum(id)
  end
end

function page()
  if not user_is_logged_in() then
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
