# Copyright 2012, Dell
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

class Bond < Interface
  attr_accessible :team_mode

  has_many :physical_interfaces, :dependent => :nullify

  validates :team_mode, :presence => true, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 6 }
  validate :has_two_or_more_physical_interfaces


  def has_two_or_more_physical_interfaces
    if physical_interfaces.size < 2
      errors.add(:two_or_more_physical_interfaces, "A Bond must have at least two physical interfaces")
    end
  end
end
