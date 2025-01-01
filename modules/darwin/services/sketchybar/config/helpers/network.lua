local M = {}

local function get_network_stats(interface)
  local f = io.popen(string.format("netstat -I %s -b | awk 'NR>1{print $7,$10}'", interface))
  if not f then return 0, 0 end
  
  local stats = f:read("*a")
  f:close()
  
  local bytes_in, bytes_out = stats:match("(%d+)%s+(%d+)")
  return tonumber(bytes_in) or 0, tonumber(bytes_out) or 0
end

local function format_speed(bytes)
  if bytes >= 1000000 then
    return string.format("%.1f MBps", bytes/1000000)
  elseif bytes >= 1000 then
    return string.format("%.1f KBps", bytes/1000)
  else
    return string.format("%d Bps", bytes)
  end
end

local last_bytes_in = 0
local last_bytes_out = 0
local last_time = os.time()

function M.update_network(interface)
  local current_time = os.time()
  local bytes_in, bytes_out = get_network_stats(interface)
  local time_diff = current_time - last_time
  
  if time_diff > 0 then
    local bytes_in_diff = bytes_in - last_bytes_in
    local bytes_out_diff = bytes_out - last_bytes_out
    
    local speed_in = bytes_in_diff / time_diff
    local speed_out = bytes_out_diff / time_diff
    
    last_bytes_in = bytes_in
    last_bytes_out = bytes_out
    last_time = current_time
    
    return format_speed(speed_in), format_speed(speed_out)
  end
  
  return "0 Bps", "0 Bps"
end

return M 