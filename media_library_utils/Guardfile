# More info at https://github.com/guard/guard#readme
#
guard :shell do
	watch('rename_music.rb') do |m|
		system("ruby #{m[0]} -p /mnt/nas_music -f '[Gg]*' -d INFO")
	end
end
