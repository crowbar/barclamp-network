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

class CreateAllocatedIpAddresses < ActiveRecord::Migration
  def change
    create_table :allocated_ip_addresses do |t|
      t.string :ip
      t.references :interface
      t.references :network

      t.timestamps
    end

    add_index(:allocated_ip_addresses, [:ip, :network_id], :unique => true, :name => "by_ip_network")
  end
end
