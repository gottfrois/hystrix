require 'circuitbox'

module Hystrix
  class Circuit

    # `sleep_window`      - seconds the circuit stays open once it has passed the error threshold
    # `volume_threshold`  - number of requests before error rate calculation occurs
    # `error_threshold`   - percentage of failed requests needed to trip circuit
    # `timeout_seconds`   - seconds until it will timeout the request
    # `exceptions`        - exceptions other than Timeout::Error that count as failures
    # `time_window`       - interval of time used to calculate error_rate (in seconds)
    def initialize(name:)
      @name    = name
      @circuit = ::Circuitbox.circuit(name, {
        sleep_window:     5,
        volume_threshold: 3,
        error_threshold:  50,
        timeout_seconds:  2,
        exceptions:       [Exception],
        time_window:      5,
      })
    end

    def bridge(&block)
      circuit.run!(&block)
    end

    def open?
      circuit.open?
    end

    def self.reset
      ::Circuitbox.reset
    end

    private

    attr_reader :name, :circuit

  end
end
