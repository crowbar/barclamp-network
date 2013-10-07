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

BarclampNetwork::Engine.routes.draw do

  # UI routes
  resources :interfaces
  resources :networks
    get :ranges
    get :routers
    get :allocations
  namespace :scaffolds do
    resources :networks do as_routes end
    resources :routers do as_routes end
    resources :ranges do as_routes end
    resources :allocations do as_routes end
  end
  # special views
  get 'map' => "networks#map", :as=> :network_map

  #//network/api/v2/...
  scope :defaults => {:format=> 'json'} do
    constraints( :id => /([a-zA-Z0-9\-\.\_]*)/, :version => /v[1-9]/ ) do
      scope 'api' do
        scope ':version' do
          resources :interfaces
          resources :networks do
            resources :ranges
            resources :routers
            member do
              match 'ip'
              post 'allocate_ip'
              get 'allocations'
            end
          end
        end
      end
    end
  end
end
