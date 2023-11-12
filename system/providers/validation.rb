# frozen_string_literal: true

Application.register_provider(:validation) do
  
  prepare do
    require 'dry-validation'
  end
  
  start do
    register(:validation, Dry::Validation)
  end
end
