# frozen_string_literal: true

require 'fog'
require 'neoinfra/cloudwatch'

# NeoInfra Account information
module NeoInfra
  # Provide informations about the accounts available
  class Cloudwatch
    def get_bucket_size(key, secret, region, bucket)
      conf = {
        aws_access_key_id: key,
        aws_secret_access_key: secret,
        region: region
      }
      cwstats = Fog::AWS::CloudWatch.new(conf)
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
    end
  end
end
