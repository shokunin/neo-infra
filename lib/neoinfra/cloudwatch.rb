# frozen_string_literal: true

require 'fog-aws'
require 'neoinfra/cloudwatch'

# NeoInfra Account information
module NeoInfra
  # Provide informations about the accounts available
  class Cloudwatch
    def get_instance_cpu(key, secret, region, instance_id)
      begin
        stats = {:cpu_avg => -1, :cpu_max => -1}
        cwstats = Fog::AWS::CloudWatch.new(
                          {
                              :region                => region,
                              :aws_access_key_id     => key,
                              :aws_secret_access_key => secret,
                            }
        )
        cpu_stats=cwstats.get_metric_statistics(
          { 'Dimensions' => [ {'Name' => 'InstanceId', 'Value' => instance_id} ],
            'Namespace'  => 'AWS/EC2',
            'MetricName' => 'CPUUtilization',
            'Statistics' => ['Average'],
            'EndTime'    => DateTime.now,
            'StartTime'  => DateTime.now-7,
            'Period'     => 3600
        }).data[:body]['GetMetricStatisticsResult']['Datapoints'].collect{|r| r['Average']}
        if cpu_stats.size > 0
          stats[:cpu_max] = cpu_stats.max
          stats[:cpu_avg] = cpu_stats.inject(0.0) { |sum, el| sum + el } / cpu_stats.size
        else
          stats[:cpu_max] = 0
          stats[:cpu_avg] = 0
        end
        return stats
      rescue Exception => e
        puts "ERR: #{e.message}: #{account[:name]},#{region} #{base_conf.inspect}"
        return stats
      end
    end

    def get_bucket_size(key, secret, region, bucket)
      conf = {
        aws_access_key_id: key,
        aws_secret_access_key: secret,
        region: region
      }
      cwstats = Fog::AWS::CloudWatch.new(conf)
      begin
        cwstats.get_metric_statistics('Statistics' => ['Maximum'],
                                      'StartTime'  => DateTime.now - 7,
                                      'EndTime'    => DateTime.now,
                                      'Period'     => 3600,
                                      'MetricName' => 'BucketSizeBytes',
                                      'Namespace'  => 'AWS/S3',
                                      'Dimensions' => [
                                        { 'Name' => 'BucketName', 'Value' => bucket },
                                        { 'Name' => 'StorageType', 'Value' => 'StandardStorage' }
                                      ]).data[:body]['GetMetricStatisticsResult']['Datapoints'].last['Maximum']
      rescue StandardError
        puts "Unable to get stats for #{bucket} returning -1"
        return -1
      end
    end
  end
end
