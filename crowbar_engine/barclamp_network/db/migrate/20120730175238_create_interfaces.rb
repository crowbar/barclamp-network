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

class CreateInterfaces < ActiveRecord::Migration
  def change
    create_table :interfaces do |t|
      t.string :type
      t.string :name
      t.integer :team_mode
      t.references :vlan_interface
      t.references :bond
      t.references :vlan
      t.references :node

      t.timestamps
    end
  end
end
