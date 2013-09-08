BarclampNetwork::Engine.routes.draw do
  #"/api/v2/networks"
  scope :defaults => {:format=> 'json'} do
    constraints( :id => /([a-zA-Z0-9\-\.\_]*)/, :version => /v[1-9]/ ) do
      scope ':version' do
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
