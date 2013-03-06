BarclampNetwork::Engine.routes.draw do

  namespace :scaffolds do
    resources :allocated_ip_addresses do as_routes end
    resources :bmc_interfaces do as_routes end
    resources :bonds do as_routes end
    resources :bridges do as_routes end
    resources :bus_maps do as_routes end
    resources :buses do as_routes end
    resources :config_actions do as_routes end
    resources :conduit_filters do as_routes end
    resources :conduit_rules do as_routes end
    resources :conduits do as_routes end
    resources :create_bonds do as_routes end
    resources :create_bridges do as_routes end
    resources :create_vlans do as_routes end
    resources :interface_maps do as_routes end
    resources :interface_selectors do as_routes end
    resources :interfaces do as_routes end
    resources :ip_addresses do as_routes end
    resources :ip_ranges do as_routes end
    resources :network_mode_filters do as_routes end
    resources :networks do as_routes end
    resources :node_attribute_filters do as_routes end
    resources :physical_interfaces do as_routes end
    resources :routers do as_routes end
    resources :select_by_indices do as_routes end
    resources :select_by_speeds do as_routes end
    resources :vlan_interfaces do as_routes end
    resources :vlans do as_routes end
  end

  # CB1 - should move to network barclamp!
  scope 'network' do
    version = "2.0"
    resources :networks, :conduits
    get '/', :controller => 'networks', :action=>'switch', :as => :network
    get 'switch(/:id)', :controller => 'networks', :action=>'switch', :constraints => { :id => /.*/ }, :as => :switch
    get 'vlan(/:id)', :controller => 'networks', :action=>'vlan', :constraints => { :id => /.*/ }, :as => :vlan
  end

  # API routes (must be json and must prefix 2.0)()
  scope :defaults => {:format=> 'json'} do
  # 2.0 API Pattern
  # depricated 2.0 API Pattern
    scope '2.0' do
      constraints(:id => /([a-zA-Z0-9\-\.\_]*)/, :version => /[0-9].[0-9]/ ) do
        scope 'crowbar' do    # MOVE TO GENERIC!
          scope '2.0' do      # MOVE TO GENERIC!
            get    "network/networks", :controller => 'networks', :action=>'networks'     # MOVE TO GENERIC!
            get    "network/networks/:id", :controller => 'networks', :action=>'network_show'     # MOVE TO GENERIC!
            post   "network/networks", :controller => 'networks', :action=>'network_create'     # MOVE TO GENERIC!
            put    "network/networks/:id", :controller => 'networks', :action=>'network_update'     # MOVE TO GENERIC!
            delete "network/networks/:id", :controller => 'networks', :action=>'network_delete'     # MOVE TO GENERIC!
            post   "network/networks/:id/allocate_ip", :controller => 'networks', :action=>'network_allocate_ip'
            delete "network/networks/:id/deallocate_ip/:network_id/:node_id", :controller => 'networks', :action=>'network_deallocate_ip'
            post   "network/networks/:id/enable_interface", :controller => 'networks', :action=>'network_enable_interface'
          end
        end
      end
    end
  end

end
