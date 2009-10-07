require 'rake/tasklib'
require 'erb'
require 'symbol'

class SymbolTask < Rake::TaskLib
  
  TEMPLATE = ERB.new <<-LATEX.gsub(/^  /,'')
  \\documentclass[10pt]{article}
  \\usepackage[utf8]{inputenc} % Direkte Eingabe von Umlauten und anderen Diakritika

  <%= @packages %>

  \\pagestyle{empty}

  \\begin{document}

  <%= @command %>

  \\end{document}
  LATEX
  
  TMP = 'tmp'
  OUT = 'public/images/latex'

  attr_accessor :name, :tmp, :out

  # initialize sets the name and calls a block to get
  #   the rest of the options
  def initialize(name = :symbols)
      @name = name
      yield self if block_given?
      define
  end

  # define creates the new task(s)
  def define
    # desc "prepare necessary directories"
    # task :prepare do
      directory TMP
      directory OUT
    # end
        
    all_image_tasks = Latex::Symbol::List.map do |symbol|
      define_single_tex_task symbol
      define_single_dvi_task symbol      
      define_single_image_task symbol
    end
    
    desc "create png images from all symbols"
    task @name => all_image_tasks
  end
  
  
  def define_single_image_task symbol
    file "#{File.join(OUT, symbol.filename)}.png" => [OUT, "#{File.join(TMP, symbol.filename)}.dvi"] do |t|
      # Now convert to image
      dpi = ENV['DPI'] || 600
      gamma = ENV['GAMMA'] || 1

      puts "Creating image... #{t.name}"
      sh %|dvipng -bg Transparent -T tight -v -D #{dpi} --gamma #{gamma} #{File.join(TMP, symbol.filename)}.dvi -o #{t.name} >/dev/null| do |ok, res|
        if ! ok
          puts "Major Failure creating image! (status = #{res.exitstatus})"
        end
      end
      
    end
    "#{File.join(OUT, symbol.filename)}.png" # need the names
  end

  def define_single_dvi_task symbol
    file "#{File.join(TMP, symbol.filename)}.dvi" => [TMP, "#{File.join(TMP, symbol.filename)}.tex"] do
      puts "Generating dvi for #{symbol}..."
      sh %|latex -interaction=batchmode -output-directory=#{TMP} #{File.join(TMP, symbol.filename)}.tex >/dev/null| do |ok, res|
        if ! ok
          puts "Major Failure creating dvi! (status = #{res.exitstatus})"
        end
      end
    end
  end

  def define_single_tex_task symbol
    file "#{File.join(TMP, symbol.filename)}.tex" => TMP do |t|
      open(t.name, 'w+') do |texfile|
        # setup variables
        @packages = ''
        @packages << "\\usepackage{#{symbol[:package]}}\n" if symbol[:package]
        @packages << "\\usepackage[#{symbol[:fontenc]}]{fontenc}\n" if symbol[:fontenc]
        @command = symbol.mathmode ? "$#{symbol.command}$" : symbol.command
        # write symbol to tempfile
        puts "Generating latex for #{symbol}..."
        texfile.puts TEMPLATE.result(binding)
      end
    end
  end
  
end


# -----

  # INDEX = ERB.new <<-HTML.gsub(/^  /,'')
  # <html>
  # <body>
  #   <h1>Symbole</h1>
  #   <table>
  #     <% for s in @symbols %>
  #     <tr>
  #       <td><%= s.command %></td><td><img src='<%= s.id %>.png'></td>
  #     </tr>
  #     <% end %>
  #   </table>
  # </body>
  # </html>
  # HTML