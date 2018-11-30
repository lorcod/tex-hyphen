#!/usr/bin/env ruby
# encoding: utf-8

# this file auto-generates loaders for hyphenation patterns - to be improved # No shit, Sherlock -- AR 2018-11-27

require_relative 'lib/tex/hyphen/language.rb'
include TeX::Hyphen
include Language::TeXLive

#text_if_native_utf = "\input pattern-loader.tex\n\\ifNativeUtfEightPatterns"

def output(file, string, indent = 2)
  if string.is_a? Enumerable
    string.each { |line| output(file, line, indent) }
  else
    string.split("\n").each do |line|
      file.print '  ' * indent
      file.puts(line)
    end
  end
end

print 'Generating loaders for '
Language.all.each do |language|

# puts language.bcp47

################
# Header texts #
################

# a message about auto-generation
# TODO: write a more comprehensive one
text_header =
"% filename: loadhyph-#{language.bcp47}.tex
% language: #{language.babelname}
%
% Loader for hyphenation patterns, generated by
%     source/generic/hyph-utf8/generate-pattern-loaders.rb
% See also http://tug.org/tex-hyphen
%
% Copyright 2008-#{Time.now.year} TeX Users Group.
% You may freely use, modify and/or distribute this file.
% (But consider adapting the scripts if you need modifications.)
%
% Once it turns out that more than a simple definition is needed,
% these lines may be moved to a separate file.
%"

###########
# lccodes #
###########

lccodes_common = []
if language.has_apostrophes? then
  lccodes_common.push("\\lccode`\\'=`\\'")
end
if language.has_hyphens? then
  lccodes_common.push("\\lccode`\\-=`\\-")
end

  next if language.use_old_loader
    print language.bcp47, ' '

    filename = File.join(PATH::LOADER, language.loadhyph)
    File.open(filename, "w") do |file|
      # puts language.bcp47
      file.puts text_header
      file.puts('\begingroup')

      if lccodes_common.length > 0 then
        file.puts lccodes_common.join("\n")
      end

# for ASCII encoding, we don't load any special support files, but simply load everything
if language.encoding == 'ascii' && !language.italic?
  file.puts "% ASCII patterns - no additional support is needed"
  file.puts "\\message{ASCII #{language.message}}"
  file.puts "\\input hyph-#{language.bcp47}.tex"
else
  file.puts '% Test for pTeX
\\ifx\\kanjiskip\\undefined
% Test for native UTF-8 (which gets only a single argument)
% That\'s Tau (as in Taco or ΤΕΧ, Tau-Epsilon-Chi), a 2-byte UTF-8 character
\\def\\testengine#1#2!{\\def\\secondarg{#2}}\\testengine Τ!\\relax
\\ifx\\secondarg\\empty'
  output(file, language.format_inputs(language.utf8_chunk))
  file.puts("\\else\n")
  output(file, language.format_inputs(language.nonutf8_chunk('8-bit')))
  file.puts("\\fi\\else\n")
  output(file, language.format_inputs(language.nonutf8_chunk('pTeX')))
  file.puts("\\fi\n")
end

########################################
# GROUP nr. 1 - ONLY USABLE WITH UTF-8 #
########################################
      # some special cases first
      #
      # some languages (sanskrit) are useless in 8-bit engines; we only want to load them for UTF engines
      # TODO - maybe consider doing something similar for ibycus

#######################
# GROUP nr. 2 - ASCII #
#######################

####################################
# GROUP nr. 3 - different patterns #
####################################
      # when lanugage uses old patterns for 8-bit engines, load two different patterns rather than using the converter
        # greek, coptic
#########################
# GROUP nr. 4 - regular #
#########################
#######
# end #
#######
      file.puts('\endgroup')
    end
end

puts
