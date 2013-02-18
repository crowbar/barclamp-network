# Copyright 2013, Dell
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class BarclampNetwork::SelectBySpeed < Selector
  def select(if_remap)
    speeds= %w{10m 100m 1g 10g}
    
    desired_match = /^([-+?]?)(\d{1,3}[mg])$/.match(self.value)
    desired_speed = desired_match[2]
    desired_speed_index = speeds.index(desired_speed)
    speed_modifier = desired_match[1]

    new_if_remap = {}

    # Find the max interface index
    max_if_index = 1
    if_remap.keys.each do |conduit_name|
      m = CONDUIT_REGEX.match(conduit_name)
      index = m[3].to_i
      max_if_index = index if index > max_if_index
    end

    # Find the best speed for each index
    (1..max_if_index).each do |if_index|
      found = nil
      filter = lambda { |speed_index|
        unless found
          key = "#{speeds[speed_index]}#{if_index}"
          if if_remap.has_key?(key)
            new_if_remap[key] = if_remap[key]
            found = true
          end
        end
      }
      
      case speed_modifier
      when '+' then (desired_speed_index..speeds.length).each(&filter)
      when '-' then desired_speed_index.downto(0,&filter)
      when '?'
        (desired_speed_index..speeds.length).each(&filter)
        desired_speed_index.downto(0,&filter) unless found
      else
        key = "#{desired_speed}#{if_index}"
        new_if_remap[key] = if_remap[key] if if_remap.has_key?(key)
      end
    end

    new_if_remap
  end
end
