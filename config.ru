require_relative 'init'

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    DB.disconnect if forked
  end
end

run App
