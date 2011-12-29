require './omegle'

class Question
   attr_reader :text, :choices

   def initialize(text, choices = nil)
      @text = text
      @choices = choices
   end
end

class AskOmegle
   def ask(question)#, strangerstoask) #il tutto va ripetuto per il numero di volte che vogliamo
      p "asking" #debug
      Omegle.start(:host => 'cardassia.omegle.com') do |omegle|
         omegle.typing #typing e stopped typing per me vanno inseriti nel send della libreria omegle 
         p question.text #debug
         omegle.send question.text
         omegle.stopped_typing
        
         letter = "a"
         question.choices.each do |c|
            omegle.typing
            p letter + ") " + c #debug
            omegle.send letter + ") " + c
            omegle.stopped_typing
            letter.next!
         end

         omegle.listen do |event|
            #puts event.inspect #debug
            remote_messages = event.collect {|e| e if e.first == "gotMessage"}.compact.collect {|e| e.last}
           
            puts remote_messages.inspect #debug
           
           
            #qui va trappata la risposta, bisogna capire se ha risposto una delle lettere possibili, in caso positivo ringraziare e chiudere la conversazione, 
            #in caso negativo chiedere di rispondere solo con una delle alternative possibili
            #bisogna anche introdurre un timeout 
           
            #input da tastiera da console: usato per il debug
           
            message = gets.chomp
            #puts message

            if message
               omegle.typing
               omegle.send message
               omegle.stopped_typing
            end

            remote_messages = ''
            message = false

         end
      end

      #end_conversation

   end
end


q = Question.new("I'm a bot, i was born today. I was programmed by a lazy guy that has an ugly job and wants me to do polls in his place, so the question is: which is the worst of 2011", ["justin bieber", "rebecca black", "the twilight movies"])

p "question initialized"
p "text"
p q.text
letter = "a"
q.choices.each do |c|
   p letter + ") " + c
   letter.next!
end

AskOmegle.new.ask(q)







