#!/usr/bin/ruby
require 'telegram/bot'

token = '<bot token goes here>'
filepath = '/tmp/audio'
join_msg = "To use the Voice2Audio Telegram bot, simply forward a voice message to it, and get the message as a media message back."
help_msg = join_msg + " Go to http://www.github.com/BenjiWiebe/Voice2Audio for reporting issues."

Telegram::Bot::Client.run(token) do |bot|
  puts "Bot started."
  bot.listen do |message|
	case message.text
		when "/start"
			bot.api.send_message(chat_id: message.chat.id, text: join_msg)
		when "/help"
			bot.api.send_message(chat_id: message.chat.id, text: help_msg)
	end
	if message.voice
		print 'Received a voice message...'
		f = bot.api.get_file({:file_id => message.voice.file_id})
		path = f["result"]["file_path"]
		path = "https://api.telegram.org/file/bot#{token}/#{path}"
		`curl -s #{path} -o #{filepath}.oga`
		print "downloaded..."
		`ffmpeg -loglevel quiet -y -i #{filepath}.oga #{filepath}.mp3`
		print "converted..."
		bot.api.send_audio(
				chat_id: message.chat.id,
				reply_to_message_id: message.message_id,
				audio: Faraday::UploadIO.new("#{filepath}.mp3", 'audio/mp3')
		)
		puts "sent!"
		File.unlink("#{filepath}.oga") if File.exists?("#{filepath}.oga")
		File.unlink("#{filepath}.mp3") if File.exists?("#{filepath}.mp3")
	end
  end
end
