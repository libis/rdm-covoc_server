# frozen_string_literal: true

require 'digest'

class App

  sha256 = Digest::SHA256.new

  # Entrypoint for claimer
  hash_branch 'claimer' do |r|
    r.post do
      res = { status: "OK" }

      # read the r.body stream
      content = r.body.read
      # Write the content in a file for Lirias import
      begin
        File.open("/data/json/#{sha256.hexdigest content}.json", 'w') { |file| file.write(content) }
      rescue => exception
        res = { status: "failed", error: exception }
      end

      # Finally, return the response
      res

    end
  end
end
