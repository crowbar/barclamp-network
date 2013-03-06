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

  scope 'network' do
    version = "2.0"
    resources :networks, :conduits
    get '/', :controller => 'networks', :action=>'switch', :as => :network
    get 'switch(/:id)', :controller => 'networks', :action=>'switch', :constraints => { :id => /.*/ }, :as => :switch
    get 'vlan(/:id)', :controller => 'networks', :action=>'vlan', :constraints => { :id => /.*/ }, :as => :vlan
  end

  scope :defaults => {:format=> 'json'} do
    constraints( :version => /v[1-9]/ ) do
      scope ':version' do
        scope :module => "barclamp_network" do
          resources :networks do
            member do  
              put 'allocate_ip'
              put 'deallocate_ip'
              put 'enable_interface'
            end
          end
        end
      end
    end
  end
end
