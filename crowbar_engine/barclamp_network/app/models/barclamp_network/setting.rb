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

class BarclampNetwork::Setting < ActiveRecord::Base

  def self.[](n)
    res = where(:name => n).first
    res &&= res.value
  end
  
  def self.[]=(n,v)
    val = self[n] || new({:name => n}, :without_protection => true)
    val.value = v
    val.save!
  end
  
end
