# frozen_string_literal: true

module APIResponse
  # Crea e invia una risposta di successo.
  # @param response [Roda::RodaResponse] La risposta HTTP.
  # @param data [Hash, Array] i dati da includere nella risposta.
  # @param message [String] un messaggio descrittivo.
  def self.success(response, data, message = 'Success')
    payload = {
      status: 'success',
      message: message,
      data: data
    }
    response.status = 200
    response.write Serializers::APIResponseSerializer.new(payload).render
  end

  # Crea e invia una risposta di errore.
  # @param response [Roda::RodaResponse] La risposta HTTP.
  # @param message [String] un messaggio di errore.
  # @param status_code [Integer] il codice di stato HTTP per l'errore.
  def self.error(response, message, status_code = 400)
    payload = {
      status: 'error',
      message: message,
      code: status_code
    }
    response.status = status_code
    response.write Serializers::APIResponseSerializer.new(payload).render
  end
end
