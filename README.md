# Version Info: For the release-history of your application

VersionInfo..
 
 * stores your git-history (and diffs) in a file that you can deploy (f.ex. with capistrano)
 * reads and formats your history-file in places where there is no .git-folder (and thus no git log) available.

## Assumptions

The code assumes your releases are tagged in git using a format like `release_DDMMYY`. Change the code if needed.

## Installation

You can install the gem by specifying it in your Gemfile:

    gem "version_info", :git => "git://github.com/lukas2/version_info.git"

## Usage (writing the file)

After installing the gem you can create your datafile like this:

    require "version_info"
    VersionInfo.new( true )

This would store the data to a file called `version.info`. To store in another file specify the filename:

    VersionInfo.new( true, "my.file" )

If you use capistrano, you can write something like this into your deploy-file:

    namespace :version do
      task :info do
        require "version_info"
        filename = "my.file"
        VersionInfo.new( true, filename )
        top.upload( filename, "#{current_path}/#{filename}", :via => :scp )
      end
    end

    after 'deploy', 'version:info'

This would upload the file after deployment.

## Usage (reading the file)

After deployment you can read and display the file like this:

    require "version_info"
    vi = VersionInfo.new( false ) # or provide a filename as 2nd parameter

To get the hash that contains all history-data use:

    vi.version

To get a simple text-representation use: 

    vi.to_s

## Viewing diffs

To get the diffs in color-html do:

    vi.diff( "some-key" ) 

