-- Copyright 2015 BMC Software, Inc.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local framework = require('framework')
local Plugin = framework.Plugin
local DataSource = framework.DataSource
local CommandOutputDataSource = framework.CommandOutputDataSource
local params = framework.params
local clone = framework.table.clone
local gsplit = framework.string.gsplit
local split = framework.string.split
local notEmpty = framework.string.notEmpty
local pack = framework.util.pack
local ipack = framework.util.ipack
local os = require('os')

local JMXDataSource = CommandOutputDataSource:extend()
function JMXDataSource:initialize(options)
  options.path = 'java'
  options.use_popen = true
  local args  = ('-jar jmxquery.jar -U "service:jmx:rmi:///jndi/rmi://%s:%d/jmxrmi"'):format(options.host, options.port)
  local mbeans = table.concat(options.mbeans, ';') 
  options.args = { args .. ' -O "java.lang:type=Memory" -A "NonHeapMemoryUsage" -K committed -X "' .. mbeans .. '"' }

  CommandOutputDataSource.initialize(self, options)
end

local options = clone(params)
options.mbeans = {
   'java.lang:type=Memory|NonHeapMemoryUsage|used',
   'java.lang:type=Memory|NonHeapMemoryUsage|init',
   'java.lang:type=Memory|NonHeapMemoryUsage|max'
}

local metric_mapping = {
}

local dataSource = JMXDataSource:new(options)
local plugin = Plugin:new(params, dataSource)

function plugin:onParseValues(data)
  local result = {}
  local lines = split(data.output, '\n');
  for _, l in pairs(lines) do
    if notEmpty(l) then
      local metric, value = l:match('JMX OK%s*-%s*([%p%w]+)=(%d+) ')
      ipack(result, metric, value)
    end
  end
  return result
end

plugin:run()

