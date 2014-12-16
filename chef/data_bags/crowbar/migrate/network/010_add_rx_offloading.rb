def upgrade ta, td, a, d
  unless a.has_key? "enable_rx_offloading"
    a["enable_rx_offloading"] = a["enable_tx_offloading"] || ta["enable_rx_offloading"]
  end
  unless a.has_key? "enable_tx_offloading"
    a["enable_tx_offloading"] = ta["enable_tx_offloading"]
  end
  return a, d
end


def downgrade ta, td, a, d
  unless ta.has_key? "enable_tx_offloading"
    a.delete "enable_tx_offloading"
  end
  unless ta.has_key? "enable_rx_offloading"
    a.delete "enable_rx_offloading"
  end
  return a, d
end

