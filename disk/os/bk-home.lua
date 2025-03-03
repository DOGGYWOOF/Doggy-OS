--Alternative shell from CraftOS shell

termutils = {}

termutils.clear = function()
  term.clear()
  term.setCursorPos(1,1)
end

termutils.clearColor = function()
  term.setTextColor(colors.white)
  term.setBackgroundColor(colors.black)
end

function input()
  term.setTextColor(colors.blue)
  local dir = shell.dir().."/"..">"
  write(dir)
  termutils.clearColor()
  command = io.read()
end

termutils.clear()
print("Doggy OS Terminal (13.0)")
while true do
  input()
  shell.run(command)
end
