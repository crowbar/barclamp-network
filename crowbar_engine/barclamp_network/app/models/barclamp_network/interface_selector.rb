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

class BarclampNetwork::InterfaceSelector < ActiveRecord::Base
  belongs_to :conduit_rule, :inverse_of => :interface_selectors
  has_many :selectors, :inverse_of => :interface_selector, :dependent => :destroy

  validates :selectors, :presence => true


  def select_interface(if_remap, node)
    # Apply each selector to the bucket of interfaces,
    # resulting in a trimmed down bucket each time
    self.selectors.each do |selector|
      if_remap = selector.select(if_remap)
    end

    if if_remap.empty?
      return nil
    elsif if_remap.size > 1
      Rails.logger.warn("#{if_remap.size} interfaces selected for node #{node.name} by interface selector #{self.id}")
    end

    if_remap.values[0]
  end
end
