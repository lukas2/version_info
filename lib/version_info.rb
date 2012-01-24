require "zlib"
require "strscan"
require "cgi"
# Builds and reads a file that contains information about the git-history.
# diff-result can be displayed as HTML in the browser.
class VersionInfo

  def initialize( write, filename = "version.info" )
    @branch      = nil
    @releases    = []
    @history     = []
    @diffs       = []

    if write
      get_from_git!
      return write!( filename )
    end

    read!( filename )
  end

  # returns a hash with the stored version-information
  def version
    res = {}
    res[:branch]    = @branch
    res[:history]   = @history
    res[:releases]  = @releases
    res[:diffs]     = @diffs.keys
    res
  end

  # returns a hash with the stored version-information in a
  # simpler format and as a string
  def to_s
    res = ""
    res += "branch: [ #{@branch} ]\n"

    @history.each do |h|
      res += "#{h[:tags].join(", ")}\n" unless h[:tags].empty?
      res += "  #{Time.parse(h[:date]).strftime("%d.%m.%y")} #{h[:msg]}\n"
    end

    res += "diffs: #{@diffs.keys.join(', ')}"
  end

  def diff( diff )
    diff_to_html( @diffs[diff] )
  end

  def read!( filename = "version.info" )
    package = Marshal.load( uncompress( File.open( filename, "r" ).read ) )

    @branch   = package[:branch]
    @releases = package[:releases]
    @history  = package[:history]
    @diffs    = package[:diffs]

    nil
  end

  def write!( filename = "version.info" )

    package = {}
    
    package[:history]   = @history
    package[:branch]    = @branch
    package[:releases]  = @releases
    package[:diffs]     = {}

    # diffs
    @releases.unshift({ :hash => "HEAD", :tag => "HEAD" })
    pairs = []

    @releases.each_with_index do |r,i|
      break if @releases[i+1].nil?
      pairs << [r, @releases[i+1]]
    end

    pairs.each do |a,b|
      package[:diffs]["#{a[:tag]}-#{b[:tag]}"] = mkdiff( a[:hash], b[:hash] )
    end

    package = Marshal.dump( package )

    File.open( filename, 'w' ) do |f|
      f.write( compress( package ) )
    end

    File.open( filename + "_readme", "w" ) do |f|
      f.write( "** version.info and this file are generated during deployment. **\n" )
      f.write( "** version.info contains zipped git-history information.       **\n" )
    end
  end

  private 

  def get_from_git!( num_logentries = 100 )

    log_lines    = `git log --pretty=format:'%h\t%cd\t%s\t%d' | head -n #{num_logentries.to_s}`.split("\n")
    @branch      = `git branch | grep "*"`.split.last

    log_lines.each do |line|
      line = line.split("\t")

      tags = line[3]
      hash = line[0]

      if tags.nil?
        tags = []
      else
        tags = tags.gsub!("(","").gsub!(")","").gsub!(" ","").split(",")
        tags.each do |t|
          if t.index("release_")
            @releases << { :tag => t, :hash => hash }
          end
        end
        tags = tags.delete_if{ |t| !t.index("release_") }
      end

      @history << { 
        :hash => hash,
        :date => line[1],
        :msg  => line[2],
        :tags => tags
      }
    end
  end

  def mkdiff( from, to )
    res = `git diff --color #{from} #{to}`
  end

  def diff_to_html( diff )
    out = ""
    out += "<html><head><style>body{ background-color: #000; color: #FFF; }</style></head><body><pre><code>"

    # git diff returns results with ansi-colorcodes
    diff.split("\n").each do |s|
      s = CGI::escapeHTML( s )
      s.gsub!(/\e\[1;33m/,"<span style='font-weight: bold; color: #FF0;'>")
      s.gsub!(/\e\[1;31m/,"<span style='font-weight: bold; color: #F00;'>") 
      s.gsub!(/\e\[7;31m/,"") 
      s.gsub!(/\e\[1;32m/,"<span style='font-weight: bold; color: #0F0;'>") 
      s.gsub!(/\e\[1;35m/,"<span style='font-weight: bold; color: #F0F;'>") # bold magenta
      s.gsub!(/\e\[1;36m/,"<span style='font-weight: bold; color: #FFF;'>") # bold cyan
      s.gsub!(/\[m/,"</span>") 

      # with some git-versions the color-codes look different:
      s.gsub!(/\e\[33m/,"<span style='font-weight: bold; color: #FF0;'>")
      s.gsub!(/\e\[31m/,"<span style='font-weight: bold; color: #F00;'>") 
      s.gsub!(/\e\[31m/,"") 
      s.gsub!(/\e\[32m/,"<span style='font-weight: bold; color: #0F0;'>") 
      s.gsub!(/\e\[35m/,"<span style='font-weight: bold; color: #F0F;'>") # bold magenta
      s.gsub!(/\e\[36m/,"<span style='font-weight: bold; color: #FFF;'>") # bold cyan
      s.gsub!(/\e\[1m/,"<span style='font-weight: bold;'>") # bold cyan
      out += ( s + "\n")
    end

    out
  end

  def compress( string )
    Zlib::Deflate.deflate( string )
  end

  def uncompress( string )
    Zlib::Inflate.inflate( string )
  end

end
