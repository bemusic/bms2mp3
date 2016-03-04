require 'tmpdir'
require 'digest'
require 'json'
require 'open3'
require 'fileutils'

# Takes a BMS package and returns an array of BMS files.
# If it’s a ZIP/RAR archive, extract them.
def bms_files(package, temp:)
  dir = begin
    if Dir.exist?(package)
      package
    else
      system '7z', 'e', "-o#{temp}", ARGV[0]
      temp
    end
  end
  basenames = Dir.chdir(dir) { Dir['*.{bm[sel],pms,bmson}'] }
  sounds = Dir.chdir(dir) { Dir['*.{wav,mp3,ogg}'] }
  outdir = File.join(temp, 'bms2song-preproc')
  FileUtils.mkdir_p(outdir)
  sounds.each do |basename|
    input = File.join(dir, basename)
    output = File.join(outdir, File.basename(basename, File.extname(basename)) + '.wav')
    command = [ 'sox', input, '-r', '44.1k', '-c', '2', output ]
    $stderr.puts "Converting audio: #{basename}"
    system(*command)
  end
  basenames.each do |basename|
    input = File.join(dir, basename)
    output = File.join(outdir, basename)
    FileUtils.cp(input, output)
    $stderr.puts "#{input} -> #{output}"
  end
  basenames.map { |x| File.join(outdir, x) }
end

def get_song_info(file)
  stdout, _ = Open3.capture2('bms-renderer', '--info', file, '-')
  JSON.parse(stdout)
end

def get_mp3_name(attrs)
  "[#{attrs['genre']}] #{attrs['artist']} — #{attrs['title']}".gsub(/[\/\\:\*\?"<>\|]/, '')
end

mp3dir = ENV['MP3DIR'] || 'mp3'

FileUtils.mkdir_p(mp3dir)

                         # XXX: remove
Dir.mktmpdir 'bms2song', '/Volumes/RAMDisk/' do |dir|
  bms_files(ARGV[0], temp: dir).sort_by { |x| x.scan(/h/i).length }.reverse.take(1).each do |file|
    tmpfile = File.join(dir, File.basename(file))
    md5 = Digest::MD5.file(file).hexdigest
    utf16, status = Open3.capture2('iconv', '-f', 'Shift_JIS', '-t', 'UTF-16', file)
    if status.exitstatus.zero?
      File.write(file, utf16)
    end
    out = "#{tmpfile}_bms2song.wav"
    trimmed = "#{tmpfile}_bms2song.trimmed.wav"
    song_info = get_song_info(file)
    mp3_name = get_mp3_name(song_info)
    mp3 = "#{mp3dir}/#{mp3_name}.mp3"
    $stderr.puts ">> Output file: #{mp3}"
    if File.exist?(mp3)
      $stderr.puts "!! #{mp3} already exists -- skipping"
      next
    end
    $stderr.puts ">> Rendering to: #{out}"

    system 'bms-renderer', file, out
    system 'wavegain', '-y', out
    system(
      'sox', out,
      '-b', '16', trimmed,
      'silence', '1', '0', '0.1%',
      'reverse',
      'silence', '1', '0', '0.1%',
      'reverse'
    )
    system('lame', '-b320',
      '--tt', song_info['title'] || '',
      '--ta', song_info['artist'] || '',
      '--tg', song_info['genre'] || '',
      '--tl', ENV['ALBUM'] || '',
      '--tc', "md5=#{md5}; #{File.basename(file)}",
      trimmed, mp3
    )
  end
end
