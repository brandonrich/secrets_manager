# config/initializers/fetch_secrets.rb

require 'aws-sdk-secretsmanager'

def fetch_secrets(app_name:, environment_name:)
  p "Fetching secrets"

  begin

    if( app_name.length == 0 || environment_name.length == 0 )
      raise "To fetch secrets, please define APP_NAME and ENVIRONMENT_NAME in the ENV."
    end

    p "Fetching secrets b1"
    secrets_manager_client_options = {}
    if ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY']
      if ( ENV['AWS_SECRET_ACCESS_KEY'] )
        Aws.config[:session_token] = ENV['AWS_SECURITY_TOKEN']
      end
      p "Got AWS environment variables: " + ENV['AWS_ACCESS_KEY_ID']
      secrets_manager_client_options[:access_key_id] = ENV['AWS_ACCESS_KEY_ID']
      secrets_manager_client_options[:secret_access_key] = ENV['AWS_SECRET_ACCESS_KEY']
    end
    p "secrets_manager_client_options: " + secrets_manager_client_options.to_s
    secrets_manager_client = Aws::SecretsManager::Client.new(secrets_manager_client_options)


    secrets_prefix = "#{app_name}/#{environment_name}/"

    p "Fetching secrets b2.  prefix is #{secrets_prefix}"
    # Fetch all secrets with the given prefix
    secrets = secrets_manager_client.list_secrets(
      max_results: 99,
      filters: [{
        key: 'name',
        values: [secrets_prefix]
      }]
    ).secret_list.map do |secret|
      {
        name: secret.name[secrets_prefix.length..-1],
        value: secrets_manager_client.get_secret_value(secret_id: secret.arn).secret_string
      }
    end

    p "Fetching secrets b3: secrets: #{secrets}"

    # Set the secrets as environment variables
    secrets.each do |secret|
      ENV[secret[:name]] = secret[:value]
      p "Writing secret with name " + secret[:name] + " and value " + secret[:value]
    end

  rescue Aws::Errors::ServiceError => e
    # Handle exceptions gracefully
    p "Error fetching secrets from AWS Secrets Manager: #{e}"
  end

end

# Fetch secrets for the current app and environment
fetch_secrets(
  app_name: ENV['APP_NAME'],
  environment_name: ENV['ENVIRONMENT_NAME']
)


