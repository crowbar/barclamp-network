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

class NodeAttributeFilter < ConduitFilter
  def match(node)
    attr_name = self.attr.split(".")
    attrib = node.get_attrib(attr_name[0])

    op_str = ".#{attr_name[1]}" if attr_name.length > 1

    eval "self.value #{self.comparitor} attrib.value()#{op_str}"
  end
end
