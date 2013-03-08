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

class BarclampNetwork::NodeAttributeFilter < BarclampNetwork::ConduitFilter
  def match(node)
    self.attr =~ /([^.]+)(\..+)?/
    match = Regexp.last_match
    attr_name = match[1]
    attrib = node.get_attrib(attr_name)

    eval_str = "self.value #{self.comparitor} attrib.value()#{match[2]}"

    begin
      result = eval eval_str
    rescue => ex
      Rails.logger.error("Caught an exception while evaluating \"#{eval_str}\"")
      Rails.logger.error("#{ex.message}")
      Rails.logger.error("#{ex.backtrack.join('\n')}")
    end

    result
  end
end
