--This project is under the CC-BY-4.0 license
--https://github.com/morgatronday1234

chat = peripheral.wrap("left")

ingame_mute = {}
discord_mute = {"1218610451655430266"}
channel = "1341756594383229031"
token = "" -- TESTING VAR, DON'T USE. use tokens.txt

--no token for you!
file = fs.open("tokens.txt", "r")
token = textutils.unserialise(file.readAll())["discord_bot"]
file.close()

prev_message = nil
call_count = 0

function limited_call()
 if call_count >= 45
 then
  os.sleep(1.3)
  call_count = 0
  return true
 elseif call_count <= 45
 then
  call_count = call_count +1
  return false
 end
end

--Not realy "threads" more like a promise in python
function chat_thread()
 local _, user, message = os.pullEvent("chat")

 check_ingame = true
 for _, name in pairs(ingame_mute)
 do
  if (name == user)
  then
   check_ingame = false
  end
 end

 if check_ingame == true and limited_call() == false
 then
  http.post("https://discord.com/api/v9/channels/"..channel.."/messages", textutils.serialiseJSON({["content"] = user..":\n"..message}), {["Content-Type"] = "application/json", ["authorization"] = tostring(token)})
 end
end
function discord_thread()
  os.sleep(0.3)
 local message_data = http.get("https://discord.com/api/v9/channels/"..channel.."/messages?limit=3", {["Content-Type"] = "application/json", ["authorization"] = tostring(token)})

 if (message_data == nil)
 then
    print("["..os.time("utc").."]".." Info(log:48): "..textutils.serialize(message_data))
  return
 end
 if string.find(message_data.getResponseCode(), "429")
 then
  error("RLP Active") 
 end


 message_data = textutils.unserialiseJSON(message_data.readAll())

 check_discord = true
 for _, user_id in pairs(discord_mute)
 do
  if (user_id == message_data[1].author.id)
  then
   check_discord = false
  end
 end
 --print(message_data[1].author.username..": "..tostring(check_discord))
 if not (message_data[1].id == prev_message) and (check_discord == true)
 then
  chat.sendMessage(message_data[1].content, "§aDiscord:§d"..message_data[1].author.username, "<>")
  prev_message = message_data[1].id
else
  return
 end
end
while(true)
do
 parallel.waitForAny(chat_thread, discord_thread)
end
