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

class ConduitFilter < ActiveRecord::Base
  belongs_to :conduit_rule, :inverse_of => :conduit_filters

  attr_accessible :attr, :comparitor, :end_value, :start_value, :value


  def match(node)
    raise "Subclasses must implement match method!"
  end
end
