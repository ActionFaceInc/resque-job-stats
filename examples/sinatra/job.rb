# frozen_string_literal: true

require 'resque'
require 'resque-job-stats'

module Job
  @queue = :default
  extend Resque::Plugins::JobStats

  def self.perform(_params)
    sleep 1
    puts 'Processed a job!'
  end
end

module FailingJob
  @queue = :failing
  extend Resque::Plugins::JobStats

  def self.perform(_params)
    sleep 1
    raise 'not processable!'
  end
end
