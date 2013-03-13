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

# This is a pretty nasty hack to create the default network barclamp deployment
#
# This is being done this way for now so that the default deployment will be
# created in both the dev test environment and in production mode
#
# TODO: Remove this

class CreateDeployment < ActiveRecord::Migration
  def self.up
    barclamp = BarclampNetwork::Barclamp.find_key(BarclampNetwork::Barclamp::BARCLAMP_NAME)
    barclamp.create_deployment("Default")
  end

  def self.down
    # TODO
  end
end

