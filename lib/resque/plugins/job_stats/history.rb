# frozen_string_literal: true

module Resque
  module Plugins
    module JobStats
      module History
        include Resque::Helpers

        def job_histories(start = 0, limit = histories_recordable)
          Resque.redis.lrange(jobs_history_key, start, start + limit - 1).map { |h| decode(h) }
        end

        # Returns the key used for tracking job histories
        def jobs_history_key
          "stats:jobs:#{name}:history"
        end

        def around_perform_job_stats_history(*args)
          # we collect our own duration and start time rather
          # than correlate with the duration stat to make sure
          # we're associating them with the right job arguments
          start = Time.now

          # new - fork
          number_of_jobs_in_queue = self.number_of_jobs_in_queue
          been_in_the_queue_for = self.been_in_the_queue_for(args.last.to_time)

          begin
            yield
            duration = Time.now - start
            push_history 'success' => true, 'args' => args, 'run_at' => start, 'duration' => duration,
                         'number_of_jobs_in_queue' => number_of_jobs_in_queue, 'been_in_the_queue_for' => been_in_the_queue_for
          rescue Exception => e
            duration = Time.now - start
            exception = { 'name' => e.to_s, 'backtrace' => e.backtrace }
            push_history 'success' => false, 'exception' => exception, 'args' => args, 'run_at' => start, 'duration' => duration,
                         'number_of_jobs_in_queue' => number_of_jobs_in_queue, 'been_in_the_queue_for' => been_in_the_queue_for
            raise e
          end
        end

        def histories_recordable
          @histories_recordable || 100
        end

        def histories_recorded
          Resque.redis.llen(jobs_history_key)
        end

        def reset_job_histories
          Resque.redis.del(jobs_history_key)
        end

        private

        def push_history(history)
          Resque.redis.lpush(jobs_history_key, encode(history))
          Resque.redis.ltrim(jobs_history_key, 0, histories_recordable)
        end
      end
    end
  end
end
